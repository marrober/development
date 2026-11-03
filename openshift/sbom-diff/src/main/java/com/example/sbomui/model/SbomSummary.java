package com.example.sbomui.model;

import java.util.ArrayList;
import java.util.List;

public class SbomSummary {

    private String format;
    private String specVersion;
    private String serialNumber;
    private String name;
    private String version;
    private String supplier;
    private String timestamp;
    private String fileName;
    private int componentCount;
    private int vulnerabilityCount;
    private List<SbomComponent> components = new ArrayList<>();
    private List<SbomVulnerability> vulnerabilities = new ArrayList<>();

    public String getFormat() {
        return format;
    }

    public void setFormat(String format) {
        this.format = format;
    }

    public String getSpecVersion() {
        return specVersion;
    }

    public void setSpecVersion(String specVersion) {
        this.specVersion = specVersion;
    }

    public String getSerialNumber() {
        return serialNumber;
    }

    public void setSerialNumber(String serialNumber) {
        this.serialNumber = serialNumber;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getSupplier() {
        return supplier;
    }

    public void setSupplier(String supplier) {
        this.supplier = supplier;
    }

    public String getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public int getComponentCount() {
        return componentCount;
    }

    public void setComponentCount(int componentCount) {
        this.componentCount = componentCount;
    }

    public int getVulnerabilityCount() {
        return vulnerabilityCount;
    }

    public void setVulnerabilityCount(int vulnerabilityCount) {
        this.vulnerabilityCount = vulnerabilityCount;
    }

    public List<SbomComponent> getComponents() {
        return components;
    }

    public void setComponents(List<SbomComponent> components) {
        this.components = components != null ? components : new ArrayList<>();
    }

    public List<SbomVulnerability> getVulnerabilities() {
        return vulnerabilities;
    }

    public void setVulnerabilities(List<SbomVulnerability> vulnerabilities) {
        this.vulnerabilities = vulnerabilities != null ? vulnerabilities : new ArrayList<>();
    }
}
