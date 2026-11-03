# Dependency upgrade demo

This app intentionally pins older library versions that have well-known CVEs so you can show a before/after upgrade story with SCA tools (Dependency-Track, Grype, Trivy, Snyk, OWASP Dependency-Check, etc.).

Properties in `pom.xml` control the vulnerable baseline. Bump them to the safer targets below, rebuild, and re-scan.

| Library | Vulnerable pin | Example CVE(s) | Safer target |
|---|---|---|---|
| `org.apache.logging.log4j:log4j-core` | `2.14.1` | CVE-2021-44228 (Log4Shell), CVE-2021-45046 | `2.22.1` or later |
| `com.fasterxml.jackson.core:jackson-databind` | `2.12.5` | CVE-2020-36518 | `2.17.2` or later |
| `org.yaml:snakeyaml` | `1.27` | CVE-2022-1471 | `2.2` or later |
| `org.apache.commons:commons-text` | `1.8` | CVE-2022-42889 (Text4Shell) | `1.11.0` or later |
| `commons-collections:commons-collections` | `3.2.1` | CVE-2015-6420 / CVE-2015-7501 | `commons-collections4:4.4` |
| `commons-io:commons-io` | `2.6` | CVE-2021-29425 | `2.15.1` or later |
| `com.google.guava:guava` | `24.1.1-jre` | CVE-2018-10237 | `33.2.1-jre` or later |
| Spring Boot parent | `2.5.15` | multiple transitive CVEs on that line | `3.3.x` (Java 17+) |

## Quick upgrade path for the demo

1. Scan the current build (`mvn dependency:tree` or your SCA tool).
2. Edit the version properties in `pom.xml` (and optionally move to Spring Boot 3.x).
3. Rebuild and re-scan — the same components should clear or drop sharply in severity.
4. Drop `samples/sample-cyclonedx.json` into the UI to show an SBOM that still *lists* the old CVEs as educational content.

### Example property bump (keep Spring Boot 2.x)

```xml
<log4j2.version>2.22.1</log4j2.version>
<jackson.version>2.17.2</jackson.version> <!-- via Spring Boot jackson.version property -->
<snakeyaml.version>2.2</snakeyaml.version>
<commons-text.version>1.11.0</commons-text.version>
<commons-collections.version>3.2.2</commons-collections.version>
<commons-io.version>2.15.1</commons-io.version>
<guava.version>33.2.1-jre</guava.version>
```

> Note: `commons-collections` 3.2.2 still belongs to the 3.x line. For a cleaner story, replace the dependency with `org.apache.commons:commons-collections4:4.4`.
