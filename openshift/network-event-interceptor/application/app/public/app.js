const POLL_INTERVAL_MS = 4000;
const CLUSTER_URL_KEY = "nei.clusterUrl";

const state = {
  events: [],
  selectedEventId: null,
  filterText: "",
  severityFilter: "",
  clusterUrl: "",
  expandedViolationKey: null,
};

const els = {
  statWebhooks: document.getElementById("statWebhooks"),
  statDecoded: document.getElementById("statDecoded"),
  statStored: document.getElementById("statStored"),
  statUptime: document.getElementById("statUptime"),
  filterInput: document.getElementById("filterInput"),
  severityFilter: document.getElementById("severityFilter"),
  pollStatus: document.getElementById("pollStatus"),
  emptyState: document.getElementById("emptyState"),
  eventList: document.getElementById("eventList"),
  detailPanel: document.getElementById("detailPanel"),
  detailTitle: document.getElementById("detailTitle"),
  detailContent: document.getElementById("detailContent"),
  copyPayloadBtn: document.getElementById("copyPayloadBtn"),
  configBtn: document.getElementById("configBtn"),
  configModal: document.getElementById("configModal"),
  configForm: document.getElementById("configForm"),
  clusterUrlInput: document.getElementById("clusterUrlInput"),
  refreshBtn: document.getElementById("refreshBtn"),
  clearBtn: document.getElementById("clearBtn"),
  closeDetailBtn: document.getElementById("closeDetailBtn"),
};

function formatDate(value) {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString();
}

function formatUptime(seconds) {
  if (seconds < 60) return `${seconds}s`;
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  if (mins < 60) return `${mins}m ${secs}s`;
  const hours = Math.floor(mins / 60);
  const remMins = mins % 60;
  return `${hours}h ${remMins}m`;
}

function severityClass(severity) {
  if (!severity) return "muted";
  if (severity.includes("HIGH")) return "high";
  if (severity.includes("MEDIUM")) return "medium";
  if (severity.includes("LOW")) return "low";
  return "muted";
}

function severityLabel(severity) {
  if (!severity) return "Unknown";
  return severity.replace(/_SEVERITY$/, "").replace(/_/g, " ");
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function normalizeClusterUrl(url) {
  return String(url || "").trim().replace(/\/+$/, "");
}

function getStoredClusterUrl() {
  return normalizeClusterUrl(localStorage.getItem(CLUSTER_URL_KEY) || "");
}

function setStoredClusterUrl(url) {
  const normalized = normalizeClusterUrl(url);
  localStorage.setItem(CLUSTER_URL_KEY, normalized);
  state.clusterUrl = normalized;
}

function buildPolicyUrl(policyId) {
  const clusterUrl = state.clusterUrl || getStoredClusterUrl();
  if (!clusterUrl || !policyId) {
    return null;
  }
  return `${clusterUrl}/main/policy-management/policies/${policyId}`;
}

function openConfigModal() {
  els.clusterUrlInput.value = state.clusterUrl || getStoredClusterUrl();
  els.configModal.hidden = false;
  els.clusterUrlInput.focus();
}

function closeConfigModal() {
  els.configModal.hidden = true;
}

function initConfig() {
  state.clusterUrl = getStoredClusterUrl();
  if (!state.clusterUrl) {
    openConfigModal();
  }
}

function matchesFilter(event) {
  const text = state.filterText.trim().toLowerCase();
  if (!text) return true;

  const haystack = [
    event.brief?.id,
    event.brief?.policyName,
    event.brief?.clusterName,
    event.brief?.deploymentName,
    event.brief?.deploymentNamespace,
    event.summary?.processViolationMessage,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  return haystack.includes(text);
}

function matchesSeverity(event) {
  if (!state.severityFilter) return true;
  return event.summary?.severity === state.severityFilter;
}

function getFilteredEvents() {
  return state.events.filter((event) => matchesFilter(event) && matchesSeverity(event));
}

function renderStats(status) {
  els.statWebhooks.textContent = status?.webhookRequestCount ?? 0;
  els.statDecoded.textContent = status?.decodedAlertCount ?? 0;
  els.statStored.textContent = status?.storedEventCount ?? state.events.length;
  els.statUptime.textContent = formatUptime(status?.uptimeSeconds ?? 0);
}

function renderEventCard(event) {
  const severity = event.summary?.severity;
  const policyName = event.brief?.policyName || event.decodeError || "Unrecognized webhook";
  const policyId = event.brief?.policyId || event.summary?.policyId;
  const policyUrl = buildPolicyUrl(policyId);
  const selected = event.eventId === state.selectedEventId;

  const policyLink = policyUrl
    ? `<a class="policy-link" href="${escapeHtml(policyUrl)}" target="_blank" rel="noopener noreferrer">POLICY</a>`
    : `<span class="policy-link disabled" title="Configure cluster URL and ensure policy ID is present">POLICY</span>`;

  return `
    <article class="event-card${selected ? " selected" : ""}" data-event-id="${escapeHtml(event.eventId)}">
      <div class="event-card-header">
        <div class="event-policy">${escapeHtml(policyName)}</div>
        <div class="event-card-aside">
          <span class="badge ${severityClass(severity)}">${escapeHtml(severityLabel(severity))}</span>
          ${policyLink}
        </div>
      </div>
      <div class="event-meta">
        <div class="meta-item">
          <span class="meta-label">Cluster</span>
          <span class="meta-value">${escapeHtml(event.brief?.clusterName || "—")}</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">Namespace</span>
          <span class="meta-value">${escapeHtml(event.brief?.deploymentNamespace || "—")}</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">Deployment</span>
          <span class="meta-value">${escapeHtml(event.brief?.deploymentName || "—")}</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">Alert time</span>
          <span class="meta-value">${escapeHtml(formatDate(event.brief?.time))}</span>
        </div>
      </div>
      <div class="event-footer">
        Received ${escapeHtml(formatDate(event.receivedAt))}
        ${event.decoded ? "" : " · not decoded"}
      </div>
    </article>
  `;
}

function renderEventList() {
  const filtered = getFilteredEvents();
  els.emptyState.hidden = filtered.length > 0;
  els.eventList.innerHTML = filtered.map(renderEventCard).join("");

  els.eventList.querySelectorAll(".event-card").forEach((card) => {
    card.addEventListener("click", () => {
      state.selectedEventId = card.dataset.eventId;
      state.expandedViolationKey = null;
      renderEventList();
      loadEventDetail(state.selectedEventId);
    });
  });

  els.eventList.querySelectorAll(".policy-link:not(.disabled)").forEach((link) => {
    link.addEventListener("click", (event) => {
      event.stopPropagation();
    });
  });
}

function renderDetailSection(title, contentHtml) {
  return `
    <section class="detail-section">
      <h3>${escapeHtml(title)}</h3>
      ${contentHtml}
    </section>
  `;
}

let currentDetailEvent = null;

function renderDetailGrid(items) {
  return `
    <div class="detail-grid">
      ${items
        .map(([label, value]) => `
          <div class="meta-item">
            <span class="meta-label">${escapeHtml(label)}</span>
            <span class="meta-value">${escapeHtml(value ?? "—")}</span>
          </div>
        `)
        .join("")}
    </div>
  `;
}

function getEventPayloadText(event) {
  if (event.payload) {
    return JSON.stringify(event.payload, null, 2);
  }
  return event.raw || "";
}

async function copyCurrentPayload() {
  if (!currentDetailEvent) {
    return;
  }

  const payloadText = getEventPayloadText(currentDetailEvent);
  const button = els.copyPayloadBtn;
  const originalLabel = button.textContent;

  try {
    await navigator.clipboard.writeText(payloadText);
    button.textContent = "Copied!";
    setTimeout(() => {
      button.textContent = originalLabel;
    }, 1500);
  } catch {
    button.textContent = "Failed";
    setTimeout(() => {
      button.textContent = originalLabel;
    }, 1500);
  }
}

function renderExpandableBlock(summaryHtml, bodyHtml, { open = false, detailKey = "" } = {}) {
  const keyAttr = detailKey ? ` data-violation-key="${escapeHtml(detailKey)}"` : "";
  const itemClass = detailKey ? "expandable-item violation-detail-item" : "expandable-item";

  return `
    <details class="${itemClass}"${keyAttr}${open ? " open" : ""}>
      <summary class="expandable-summary">${summaryHtml}</summary>
      <div class="expandable-body">${bodyHtml}</div>
    </details>
  `;
}

function getViolationDetailKey(violation) {
  return `${violation.time || ""}|${violation.type || ""}|${violation.message || ""}`;
}

function wireViolationDetailExpanders() {
  els.detailContent.querySelectorAll(".violation-detail-item").forEach((details) => {
    details.addEventListener("toggle", () => {
      const key = details.dataset.violationKey;
      if (details.open) {
        state.expandedViolationKey = key;
        els.detailContent.querySelectorAll(".violation-detail-item").forEach((other) => {
          if (other !== details && other.open) {
            other.open = false;
          }
        });
      } else if (state.expandedViolationKey === key) {
        state.expandedViolationKey = null;
      }
    });
  });
}

function renderViolationDetailSummary(violation) {
  const typeLabel = violation.type ? `[${violation.type}] ` : "";
  const attributeSummary = violation.attributes
    .slice(0, 2)
    .map((attribute) => `${attribute.key}: ${attribute.value}`)
    .join(", ");
  const summaryText = violation.message || attributeSummary || "Violation detail";

  return `
    <span class="expandable-summary-text">${escapeHtml(typeLabel + summaryText)}</span>
    <span class="expandable-summary-meta">${escapeHtml(formatDate(violation.time))}</span>
  `;
}

function renderViolationDetailBody(violation) {
  const sections = [];

  if (violation.message) {
    sections.push(`<p class="detail-text">${escapeHtml(violation.message)}</p>`);
  }

  if (violation.attributes.length > 0) {
    sections.push(renderDetailGrid(
      violation.attributes.map((attribute) => [attribute.key, attribute.value]),
    ));
  }

  if (violation.networkFlowInfo) {
    sections.push(`
      <div class="expandable-subsection">
        <h5 class="expandable-subheading">Network flow</h5>
        <pre class="json-block expandable-json">${escapeHtml(JSON.stringify(violation.networkFlowInfo, null, 2))}</pre>
      </div>
    `);
  }

  if (violation.fileAccess) {
    sections.push(`
      <div class="expandable-subsection">
        <h5 class="expandable-subheading">File access</h5>
        <pre class="json-block expandable-json">${escapeHtml(JSON.stringify(violation.fileAccess, null, 2))}</pre>
      </div>
    `);
  }

  if (sections.length === 0) {
    sections.push(`<p class="detail-text">No additional detail available.</p>`);
  }

  return sections.join("");
}

function renderViolationDetailsSection(violationDetails) {
  const violations = violationDetails?.violations || [];
  if (!violations.length) {
    return "";
  }

  return renderDetailSection(
    "Details",
    `<div class="expandable-list">
      ${violations
        .map((violation) => {
          const detailKey = getViolationDetailKey(violation);
          return renderExpandableBlock(
            renderViolationDetailSummary(violation),
            renderViolationDetailBody(violation),
            {
              open: state.expandedViolationKey === detailKey,
              detailKey,
            },
          );
        })
        .join("")}
    </div>`,
  );
}

function renderViolationMessageSection(processViolation) {
  return renderDetailSection(
    "Violation",
    `<p class="detail-text">${escapeHtml(processViolation?.message || "—")}</p>`,
  );
}

function renderPolicySection(policy) {
  if (!policy) {
    return "";
  }

  return renderDetailSection(
    "Policy",
    renderDetailGrid([
      ["Name", policy.name],
      ["Severity", severityLabel(policy.severity)],
      ["Categories", (policy.categories || []).join(", ") || "—"],
      ["Lifecycle", (policy.lifecycleStages || []).join(", ") || "—"],
    ]) +
      `<p class="detail-text">${escapeHtml(policy.description || "")}</p>` +
      (policy.remediation
        ? `<p class="detail-text"><strong>Remediation:</strong> ${escapeHtml(policy.remediation)}</p>`
        : ""),
  );
}

function sortProcessesByTime(processes) {
  return [...processes].sort((left, right) => {
    const leftTime = Date.parse(left.signal?.time || "") || 0;
    const rightTime = Date.parse(right.signal?.time || "") || 0;
    return rightTime - leftTime;
  });
}

function renderProcessTable(processes) {
  if (!processes?.length) {
    return `<p class="detail-text">No process details available.</p>`;
  }

  const sortedProcesses = sortProcessesByTime(processes);
  const displayedProcesses = sortedProcesses.slice(0, 5);
  const totalCount = sortedProcesses.length;
  const showingNote = totalCount > 5
    ? `<p class="detail-text process-table-note">Showing 5 of ${totalCount} most recent processes.</p>`
    : "";

  return `
    ${showingNote}
    <div class="table-wrap process-table-wrap">
      <table>
        <thead>
          <tr>
            <th>Time</th>
            <th>Process</th>
            <th>Args</th>
            <th>Pod</th>
            <th>Container</th>
          </tr>
        </thead>
        <tbody>
          ${displayedProcesses
            .map((process) => `
              <tr>
                <td>${escapeHtml(formatDate(process.signal?.time))}</td>
                <td><code>${escapeHtml(process.signal?.execFilePath || process.signal?.name || "—")}</code></td>
                <td>${escapeHtml(process.signal?.args || "—")}</td>
                <td><code>${escapeHtml(process.podId || "—")}</code></td>
                <td>${escapeHtml(process.containerName || "—")}</td>
              </tr>
            `)
            .join("")}
        </tbody>
      </table>
    </div>
  `;
}

function renderDetail(event) {
  currentDetailEvent = event;

  if (!event) {
    els.detailPanel.hidden = true;
    els.copyPayloadBtn.hidden = true;
    return;
  }

  els.detailPanel.hidden = false;
  els.copyPayloadBtn.hidden = false;
  els.detailTitle.textContent = event.brief?.policyName || "Webhook event";

  if (!event.decoded) {
    els.detailContent.innerHTML = [
      renderDetailSection("Status", `<p class="detail-text">This webhook could not be decoded as an RHACS alert.</p>`),
      renderDetailSection("Error", `<p class="detail-text">${escapeHtml(event.decodeError || "Unknown error")}</p>`),
    ].join("");
    return;
  }

  const alert = event.decoded?.alert;
  const policy = alert?.policy;
  const deployment = alert?.deployment;
  const violation = alert?.processViolation;
  const violationDetails = alert?.violationDetails;

  els.detailContent.innerHTML = [
    renderDetailSection(
      "Summary",
      renderDetailGrid([
        ["Alert ID", event.brief?.id],
        ["Severity", severityLabel(policy?.severity)],
        ["Cluster", event.brief?.clusterName],
        ["Namespace", event.brief?.deploymentNamespace],
        ["Deployment", event.brief?.deploymentName],
        ["Alert time", formatDate(event.brief?.time)],
        ["First occurred", formatDate(alert?.firstOccurred)],
        ["Received", formatDate(event.receivedAt)],
      ])
    ),
    renderViolationMessageSection(violation),
    renderPolicySection(policy),
    renderDetailSection(
      "Deployment",
      renderDetailGrid([
        ["Name", deployment?.name],
        ["Type", deployment?.type],
        ["Namespace", deployment?.namespace],
        ["Images", (deployment?.images || []).join(", ") || "—"],
      ])
    ),
    renderViolationDetailsSection(violationDetails),
    renderDetailSection(
      `Processes (${violation?.processCount || 0})`,
      renderProcessTable(violation?.processes)
    ),
  ].join("");
  wireViolationDetailExpanders();
}

async function loadEventDetail(eventId) {
  if (!eventId) {
    renderDetail(null);
    return;
  }

  try {
    const response = await fetch(`/api/events/${encodeURIComponent(eventId)}`);
    if (!response.ok) throw new Error("Failed to load event detail");
    const event = await response.json();
    renderDetail(event);
  } catch (error) {
    els.detailContent.innerHTML = `<p class="detail-text">${escapeHtml(error.message)}</p>`;
  }
}

async function refreshData() {
  try {
    const [eventsResponse, statusResponse] = await Promise.all([
      fetch("/api/events"),
      fetch("/status"),
    ]);

    if (!eventsResponse.ok || !statusResponse.ok) {
      throw new Error("Failed to refresh dashboard data");
    }

    const eventsPayload = await eventsResponse.json();
    const statusPayload = await statusResponse.json();

    state.events = eventsPayload.events || [];
    renderStats(statusPayload);

    if (state.selectedEventId && !state.events.some((event) => event.eventId === state.selectedEventId)) {
      state.selectedEventId = null;
      renderDetail(null);
    }

    renderEventList();

    els.pollStatus.textContent = `Updated ${new Date().toLocaleTimeString()}`;
  } catch (error) {
    els.pollStatus.textContent = error.message;
  }
}

async function clearEvents() {
  const response = await fetch("/api/events", { method: "DELETE" });
  if (!response.ok) {
    els.pollStatus.textContent = "Failed to clear events";
    return;
  }

  state.selectedEventId = null;
  renderDetail(null);
  await refreshData();
}

els.filterInput.addEventListener("input", () => {
  state.filterText = els.filterInput.value;
  renderEventList();
});

els.severityFilter.addEventListener("change", () => {
  state.severityFilter = els.severityFilter.value;
  renderEventList();
});

els.refreshBtn.addEventListener("click", () => refreshData());
els.clearBtn.addEventListener("click", () => clearEvents());
els.copyPayloadBtn.addEventListener("click", () => copyCurrentPayload());
els.configBtn.addEventListener("click", () => openConfigModal());
els.configForm.addEventListener("submit", (event) => {
  event.preventDefault();
  setStoredClusterUrl(els.clusterUrlInput.value);
  closeConfigModal();
  renderEventList();
});
els.configModal.querySelectorAll("[data-close-config]").forEach((element) => {
  element.addEventListener("click", () => closeConfigModal());
});
els.closeDetailBtn.addEventListener("click", () => {
  state.selectedEventId = null;
  renderEventList();
  renderDetail(null);
});

initConfig();
refreshData();
setInterval(refreshData, POLL_INTERVAL_MS);
