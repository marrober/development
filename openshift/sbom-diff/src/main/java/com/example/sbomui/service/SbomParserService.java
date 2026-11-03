package com.example.sbomui.service;

import com.example.sbomui.model.SbomComponent;
import com.example.sbomui.model.SbomSummary;
import com.example.sbomui.model.SbomVulnerability;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.text.StringEscapeUtils;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@Service
public class SbomParserService {

    private final ObjectMapper objectMapper;

    public SbomParserService(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public SbomSummary parse(MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("No SBOM file was provided.");
        }

        String fileName = FilenameUtils.getName(file.getOriginalFilename());
        String content = new String(file.getBytes(), StandardCharsets.UTF_8).trim();
        if (content.isEmpty()) {
            throw new IllegalArgumentException("The uploaded file is empty.");
        }

        JsonNode root;
        try {
            root = objectMapper.readTree(content);
        } catch (IOException ex) {
            throw new IllegalArgumentException("Unable to parse file as JSON SBOM: " + ex.getMessage());
        }

        SbomSummary summary;
        if (isCycloneDx(root)) {
            summary = parseCycloneDx(root);
        } else if (isSpdx(root)) {
            summary = parseSpdx(root);
        } else {
            throw new IllegalArgumentException(
                    "Unsupported SBOM format. Drop a CycloneDX or SPDX JSON document.");
        }

        summary.setFileName(fileName);
        summary.setComponentCount(summary.getComponents().size());
        summary.setVulnerabilityCount(summary.getVulnerabilities().size());
        return summary;
    }

    private boolean isCycloneDx(JsonNode root) {
        String bomFormat = text(root, "bomFormat");
        return bomFormat != null && bomFormat.toLowerCase(Locale.ROOT).contains("cyclonedx")
                || root.has("components") && (root.has("specVersion") || root.has("metadata"));
    }

    private boolean isSpdx(JsonNode root) {
        return root.has("spdxVersion") || root.has("SPDXID")
                || (root.has("packages") && root.has("documentDescribes"));
    }

    private SbomSummary parseCycloneDx(JsonNode root) {
        SbomSummary summary = new SbomSummary();
        summary.setFormat("CycloneDX");
        summary.setSpecVersion(text(root, "specVersion"));
        summary.setSerialNumber(text(root, "serialNumber"));

        JsonNode metadata = root.path("metadata");
        JsonNode metaComponent = metadata.path("component");
        summary.setName(firstNonBlank(text(metaComponent, "name"), text(metadata, "name"), "Unnamed BOM"));
        summary.setVersion(text(metaComponent, "version"));
        summary.setTimestamp(text(metadata, "timestamp"));

        JsonNode supplier = firstPresent(metaComponent.path("supplier"), metadata.path("supplier"));
        summary.setSupplier(firstNonBlank(text(supplier, "name"), text(supplier, "url")));

        List<SbomComponent> components = new ArrayList<>();
        JsonNode componentsNode = root.path("components");
        if (componentsNode.isArray()) {
            for (JsonNode node : componentsNode) {
                components.add(mapCycloneDxComponent(node));
            }
        }
        if (!metaComponent.isMissingNode() && !metaComponent.isNull()) {
            components.add(0, mapCycloneDxComponent(metaComponent));
        }
        summary.setComponents(components);

        List<SbomVulnerability> vulnerabilities = new ArrayList<>();
        JsonNode vulns = root.path("vulnerabilities");
        if (vulns.isArray()) {
            for (JsonNode vuln : vulns) {
                vulnerabilities.add(mapCycloneDxVulnerability(vuln));
            }
        }
        summary.setVulnerabilities(vulnerabilities);
        return summary;
    }

    private SbomComponent mapCycloneDxComponent(JsonNode node) {
        SbomComponent component = new SbomComponent();
        component.setName(text(node, "name"));
        component.setVersion(text(node, "version"));
        component.setType(text(node, "type"));
        component.setPurl(text(node, "purl"));
        component.setLicense(extractCycloneDxLicense(node.path("licenses")));
        component.setSupplier(text(node.path("supplier"), "name"));

        List<String> hashes = new ArrayList<>();
        JsonNode hashNodes = node.path("hashes");
        if (hashNodes.isArray()) {
            for (JsonNode hash : hashNodes) {
                String alg = text(hash, "alg");
                String content = text(hash, "content");
                if (alg != null && content != null) {
                    hashes.add(alg + ":" + content);
                }
            }
        }
        component.setHashes(hashes);
        return component;
    }

    private String extractCycloneDxLicense(JsonNode licenses) {
        if (!licenses.isArray()) {
            return null;
        }
        List<String> values = new ArrayList<>();
        for (JsonNode entry : licenses) {
            JsonNode license = entry.path("license");
            String id = firstNonBlank(text(license, "id"), text(license, "name"), text(entry, "expression"));
            if (id != null) {
                values.add(id);
            }
        }
        return values.isEmpty() ? null : String.join(", ", values);
    }

    private SbomVulnerability mapCycloneDxVulnerability(JsonNode node) {
        SbomVulnerability vulnerability = new SbomVulnerability();
        vulnerability.setId(text(node, "id"));
        vulnerability.setSource(text(node.path("source"), "name"));
        vulnerability.setDescription(truncate(text(node, "description"), 400));

        String severity = text(node, "severity");
        if (severity == null) {
            JsonNode ratings = node.path("ratings");
            if (ratings.isArray() && ratings.size() > 0) {
                severity = firstNonBlank(text(ratings.get(0), "severity"), text(ratings.get(0), "score"));
            }
        }
        vulnerability.setSeverity(severity);

        JsonNode affects = node.path("affects");
        if (affects.isArray() && affects.size() > 0) {
            vulnerability.setAffects(text(affects.get(0), "ref"));
        }
        return vulnerability;
    }

    private SbomSummary parseSpdx(JsonNode root) {
        SbomSummary summary = new SbomSummary();
        summary.setFormat("SPDX");
        summary.setSpecVersion(text(root, "spdxVersion"));
        summary.setSerialNumber(text(root, "documentNamespace"));
        summary.setName(firstNonBlank(text(root, "name"), "Unnamed SPDX document"));
        summary.setTimestamp(text(root.path("creationInfo"), "created"));

        JsonNode creators = root.path("creationInfo").path("creators");
        if (creators.isArray() && creators.size() > 0) {
            summary.setSupplier(creators.get(0).asText(null));
        }

        List<SbomComponent> components = new ArrayList<>();
        JsonNode packages = root.path("packages");
        if (packages.isArray()) {
            for (JsonNode pkg : packages) {
                components.add(mapSpdxPackage(pkg));
            }
        }
        summary.setComponents(components);

        List<SbomVulnerability> vulnerabilities = new ArrayList<>();
        // SPDX 2.3 / 3.0 may carry vulnerabilities under different extensions; support a common shape.
        JsonNode vulns = firstPresent(root.path("vulnerabilities"), root.path("vulnerability"));
        if (vulns.isArray()) {
            for (JsonNode vuln : vulns) {
                SbomVulnerability mapped = new SbomVulnerability();
                mapped.setId(firstNonBlank(text(vuln, "id"), text(vuln, "vulnerabilityId")));
                mapped.setSeverity(text(vuln, "severity"));
                mapped.setDescription(truncate(text(vuln, "description"), 400));
                mapped.setSource(text(vuln, "source"));
                mapped.setAffects(text(vuln, "product"));
                vulnerabilities.add(mapped);
            }
        }
        summary.setVulnerabilities(vulnerabilities);
        return summary;
    }

    private SbomComponent mapSpdxPackage(JsonNode pkg) {
        SbomComponent component = new SbomComponent();
        component.setName(text(pkg, "name"));
        component.setVersion(firstNonBlank(text(pkg, "versionInfo"), text(pkg, "version")));
        component.setType("library");
        component.setPurl(extractSpdxPurl(pkg));
        component.setLicense(firstNonBlank(
                text(pkg, "licenseConcluded"),
                text(pkg, "licenseDeclared")));
        component.setSupplier(text(pkg, "supplier"));

        List<String> hashes = new ArrayList<>();
        JsonNode checksums = pkg.path("checksums");
        if (checksums.isArray()) {
            for (JsonNode checksum : checksums) {
                String alg = text(checksum, "algorithm");
                String value = text(checksum, "checksumValue");
                if (alg != null && value != null) {
                    hashes.add(alg + ":" + value);
                }
            }
        }
        component.setHashes(hashes);
        return component;
    }

    private String extractSpdxPurl(JsonNode pkg) {
        JsonNode refs = pkg.path("externalRefs");
        if (!refs.isArray()) {
            return null;
        }
        for (JsonNode ref : refs) {
            String type = text(ref, "referenceType");
            if (type != null && type.equalsIgnoreCase("purl")) {
                return text(ref, "referenceLocator");
            }
        }
        return null;
    }

    /**
     * Light sanitisation helper that also keeps commons-text on a live code path for scanners.
     */
    public String safeDisplay(String value) {
        if (value == null) {
            return "";
        }
        return StringEscapeUtils.escapeHtml4(value);
    }

    private static String text(JsonNode node, String field) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        JsonNode value = node.get(field);
        if (value == null || value.isNull()) {
            return null;
        }
        String text = value.asText(null);
        return text == null || text.trim().isEmpty() ? null : text.trim();
    }

    private static JsonNode firstPresent(JsonNode first, JsonNode second) {
        if (first != null && !first.isMissingNode() && !first.isNull()) {
            return first;
        }
        return second;
    }

    private static String firstNonBlank(String... values) {
        if (values == null) {
            return null;
        }
        for (String value : values) {
            if (value != null && !value.trim().isEmpty()) {
                return value.trim();
            }
        }
        return null;
    }

    private static String truncate(String value, int max) {
        if (value == null || value.length() <= max) {
            return value;
        }
        return value.substring(0, max - 1) + "…";
    }
}
