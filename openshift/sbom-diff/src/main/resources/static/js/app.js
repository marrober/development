(function () {
  const dropZone = document.getElementById("drop-zone");
  const fileInput = document.getElementById("file-input");
  const statusEl = document.getElementById("status");
  const resultsEl = document.getElementById("results");
  const summaryGrid = document.getElementById("summary-grid");
  const componentsBody = document.getElementById("components-body");
  const vulnerabilitiesBody = document.getElementById("vulnerabilities-body");
  const componentFilter = document.getElementById("component-filter");
  const vulnCount = document.getElementById("vuln-count");

  let currentSummary = null;

  function setStatus(message, type) {
    statusEl.textContent = message || "";
    statusEl.className = "status" + (type ? " " + type : "");
  }

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function severityClass(severity) {
    const key = String(severity || "unknown").toLowerCase();
    if (key.includes("critical")) return "critical";
    if (key.includes("high")) return "high";
    if (key.includes("medium") || key.includes("moderate")) return "medium";
    if (key.includes("low")) return "low";
    if (key.includes("info") || key.includes("none")) return "info";
    return "unknown";
  }

  async function uploadFile(file) {
    if (!file) {
      return;
    }

    setStatus("Parsing " + file.name + "…");
    resultsEl.classList.add("hidden");

    const formData = new FormData();
    formData.append("file", file);

    try {
      const response = await fetch("/api/sbom/parse", {
        method: "POST",
        body: formData
      });

      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error || "Parse failed");
      }

      currentSummary = payload;
      renderSummary(payload);
      renderComponents(payload.components || []);
      renderVulnerabilities(payload.vulnerabilities || []);
      resultsEl.classList.remove("hidden");
      setStatus(
        "Loaded " + (payload.format || "SBOM") + " with " +
        (payload.componentCount || 0) + " component(s).",
        "ok"
      );
    } catch (err) {
      currentSummary = null;
      setStatus(err.message || "Failed to parse SBOM", "error");
    }
  }

  function renderSummary(summary) {
    const cards = [
      ["Format", summary.format],
      ["Spec", summary.specVersion],
      ["Name", summary.name],
      ["Version", summary.version],
      ["Components", summary.componentCount],
      ["Vulnerabilities", summary.vulnerabilityCount],
      ["Supplier", summary.supplier],
      ["Timestamp", summary.timestamp],
      ["File", summary.fileName]
    ];

    summaryGrid.innerHTML = cards
      .filter(function (entry) {
        return entry[1] !== null && entry[1] !== undefined && entry[1] !== "";
      })
      .map(function (entry) {
        return (
          '<div class="stat">' +
          '<span class="label">' + escapeHtml(entry[0]) + "</span>" +
          '<span class="value">' + escapeHtml(entry[1]) + "</span>" +
          "</div>"
        );
      })
      .join("");
  }

  function renderComponents(components) {
    const query = (componentFilter.value || "").trim().toLowerCase();
    const filtered = components.filter(function (component) {
      if (!query) {
        return true;
      }
      const haystack = [
        component.name,
        component.version,
        component.type,
        component.license,
        component.purl
      ]
        .join(" ")
        .toLowerCase();
      return haystack.indexOf(query) !== -1;
    });

    if (!filtered.length) {
      componentsBody.innerHTML =
        '<tr class="empty-row"><td colspan="5">No components match the current filter.</td></tr>';
      return;
    }

    componentsBody.innerHTML = filtered
      .map(function (component) {
        return (
          "<tr>" +
          "<td>" + escapeHtml(component.name || "—") + "</td>" +
          "<td>" + escapeHtml(component.version || "—") + "</td>" +
          "<td>" + escapeHtml(component.type || "—") + "</td>" +
          "<td>" + escapeHtml(component.license || "—") + "</td>" +
          "<td>" + escapeHtml(component.purl || "—") + "</td>" +
          "</tr>"
        );
      })
      .join("");
  }

  function renderVulnerabilities(vulnerabilities) {
    vulnCount.textContent = vulnerabilities.length
      ? vulnerabilities.length + " reported"
      : "None in this SBOM";

    if (!vulnerabilities.length) {
      vulnerabilitiesBody.innerHTML =
        '<tr class="empty-row"><td colspan="5">No vulnerabilities were listed in this SBOM.</td></tr>';
      return;
    }

    vulnerabilitiesBody.innerHTML = vulnerabilities
      .map(function (vuln) {
        const sev = severityClass(vuln.severity);
        return (
          "<tr>" +
          "<td>" + escapeHtml(vuln.id || "—") + "</td>" +
          '<td><span class="severity ' + sev + '">' +
          escapeHtml(vuln.severity || "unknown") +
          "</span></td>" +
          "<td>" + escapeHtml(vuln.source || "—") + "</td>" +
          "<td>" + escapeHtml(vuln.affects || "—") + "</td>" +
          "<td>" + escapeHtml(vuln.description || "—") + "</td>" +
          "</tr>"
        );
      })
      .join("");
  }

  ["dragenter", "dragover"].forEach(function (eventName) {
    dropZone.addEventListener(eventName, function (event) {
      event.preventDefault();
      event.stopPropagation();
      dropZone.classList.add("dragover");
    });
  });

  ["dragleave", "drop"].forEach(function (eventName) {
    dropZone.addEventListener(eventName, function (event) {
      event.preventDefault();
      event.stopPropagation();
      dropZone.classList.remove("dragover");
    });
  });

  dropZone.addEventListener("drop", function (event) {
    const files = event.dataTransfer && event.dataTransfer.files;
    if (files && files.length) {
      uploadFile(files[0]);
    }
  });

  fileInput.addEventListener("change", function () {
    if (fileInput.files && fileInput.files.length) {
      uploadFile(fileInput.files[0]);
      fileInput.value = "";
    }
  });

  componentFilter.addEventListener("input", function () {
    if (currentSummary) {
      renderComponents(currentSummary.components || []);
    }
  });
})();
