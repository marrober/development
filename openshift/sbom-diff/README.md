# sbom-diff — SBOM Viewer

Maven / Spring Boot web UI that accepts CycloneDX or SPDX JSON SBOMs via a drop panel and displays metadata, components, licenses, and reported vulnerabilities.

The project intentionally includes **older library versions with known CVEs** so you can demonstrate SCA findings and then upgrade to safer versions. See [DEPENDENCY_UPGRADE.md](DEPENDENCY_UPGRADE.md).

## Requirements

- Java 11+
- Maven 3.8+

## Run

```bash
mvn spring-boot:run
```

Open [http://localhost:8080](http://localhost:8080).

## Try a sample SBOM

Drop one of these onto the panel:

- `samples/sample-cyclonedx.json`
- `samples/sample-spdx.json`

Or use the **Choose file** button.

## API

`POST /api/sbom/parse` — multipart form field `file` containing a JSON SBOM.

```bash
curl -s -F "file=@samples/sample-cyclonedx.json" http://localhost:8080/api/sbom/parse | jq .
```

## Inspect vulnerable dependencies

```bash
mvn dependency:tree
```

Pinned vulnerable versions are controlled by properties in `pom.xml` (`log4j2.version`, `jackson.version`, etc.).
