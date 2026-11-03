package com.example.sbomui.controller;

import com.example.sbomui.model.SbomSummary;
import com.example.sbomui.service.SbomParserService;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/sbom")
public class SbomController {

    private static final Logger LOG = LogManager.getLogger(SbomController.class);

    private final SbomParserService sbomParserService;

    public SbomController(SbomParserService sbomParserService) {
        this.sbomParserService = sbomParserService;
    }

    @PostMapping(value = "/parse", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public SbomSummary parse(@RequestParam("file") MultipartFile file) throws Exception {
        LOG.info("Parsing SBOM upload: {}", file.getOriginalFilename());
        return sbomParserService.parse(file);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleBadRequest(IllegalArgumentException ex) {
        Map<String, String> body = new HashMap<>();
        body.put("error", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleServerError(Exception ex) {
        LOG.error("Failed to parse SBOM", ex);
        Map<String, String> body = new HashMap<>();
        body.put("error", "Failed to parse SBOM: " + ex.getMessage());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }
}
