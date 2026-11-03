package com.example.sbomui.service;

import com.example.sbomui.model.SbomSummary;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SbomParserServiceTest {

    private SbomParserService service;

    @BeforeEach
    void setUp() {
        service = new SbomParserService(new ObjectMapper());
    }

    @Test
    void parsesCycloneDxSample() throws Exception {
        SbomSummary summary = service.parse(loadSample("sample-cyclonedx.json"));
        assertEquals("CycloneDX", summary.getFormat());
        assertEquals("sbom-diff", summary.getName());
        assertTrue(summary.getComponentCount() >= 4);
        assertEquals(3, summary.getVulnerabilityCount());
        assertTrue(summary.getVulnerabilities().stream()
                .anyMatch(v -> "CVE-2021-44228".equals(v.getId())));
    }

    @Test
    void parsesSpdxSample() throws Exception {
        SbomSummary summary = service.parse(loadSample("sample-spdx.json"));
        assertEquals("SPDX", summary.getFormat());
        assertEquals("sbom-diff-spdx", summary.getName());
        assertFalse(summary.getComponents().isEmpty());
        assertEquals(2, summary.getVulnerabilityCount());
    }

    private MockMultipartFile loadSample(String name) throws Exception {
        Path path = Paths.get("samples", name);
        byte[] bytes = Files.readAllBytes(path);
        return new MockMultipartFile(
                "file",
                name,
                "application/json",
                new String(bytes, StandardCharsets.UTF_8).getBytes(StandardCharsets.UTF_8));
    }
}
