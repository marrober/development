const syncBtn = document.getElementById("syncBtn");
const statusBar = document.getElementById("statusBar");
const tileView = document.getElementById("tileView");
const tileGrid = document.getElementById("tileGrid");
const emptyState = document.getElementById("emptyState");
const detailView = document.getElementById("detailView");
const backBtn = document.getElementById("backBtn");
const detailTitle = document.getElementById("detailTitle");
const detailMeta = document.getElementById("detailMeta");
const detailEmpty = document.getElementById("detailEmpty");
const tableWrap = document.getElementById("tableWrap");
const tableHeadRow = document.getElementById("tableHeadRow");
const tableBody = document.getElementById("tableBody");
const prevClusterBtn = document.getElementById("prevClusterBtn");
const nextClusterBtn = document.getElementById("nextClusterBtn");
const compareColumnsBtn = document.getElementById("compareColumnsBtn");
const closeCompareBtn = document.getElementById("closeCompareBtn");
const diffOnlyWrap = document.getElementById("diffOnlyWrap");
const diffOnlyCheckbox = document.getElementById("diffOnlyCheckbox");
const namespacesDialog = document.getElementById("namespacesDialog");
const namespacesDialogTitle = document.getElementById("namespacesDialogTitle");
const namespacesDialogSubtitle = document.getElementById("namespacesDialogSubtitle");
const namespacesDialogCount = document.getElementById("namespacesDialogCount");
const namespacesDialogList = document.getElementById("namespacesDialogList");
const namespacesCompareSelect = document.getElementById("namespacesCompareSelect");
const namespacesSingleView = document.getElementById("namespacesSingleView");
const namespacesCompareView = document.getElementById("namespacesCompareView");
const nsDiffOnlyA = document.getElementById("nsDiffOnlyA");
const nsDiffBoth = document.getElementById("nsDiffBoth");
const nsDiffOnlyB = document.getElementById("nsDiffOnlyB");
const nsDiffOnlyATitle = document.getElementById("nsDiffOnlyATitle");
const nsDiffOnlyBTitle = document.getElementById("nsDiffOnlyBTitle");
const nsDiffOnlyAWhen = document.getElementById("nsDiffOnlyAWhen");
const nsDiffOnlyBWhen = document.getElementById("nsDiffOnlyBWhen");

const MAX_COMPARE_COLUMNS = 3;

let clustersCache = [];
let selectedCluster = null;
let namespacesDialogState = null;
let comparisonData = null;
let selectedColumnIds = new Set();
let compareMode = false;
let compareColumnIds = [];

function displayRowLabel(row) {
  if (row.rowKey?.startsWith("installed-operator:")) {
    return row.rowKey.slice("installed-operator:".length);
  }
  return String(row.label || "").replace(/\s\[[^\]]*\]$/, "");
}

function namespacesForCell(row, columnId) {
  const namespaces = row.cells[columnId]?.details?.namespaces;
  if (!Array.isArray(namespaces)) return [];
  return [...new Set(namespaces.filter(Boolean))].sort((a, b) => a.localeCompare(b));
}

function namespacesSignature(namespaces) {
  return namespaces.join("\0");
}

function fillNamespaceList(listEl, namespaces, emptyText) {
  listEl.innerHTML = "";
  if (!namespaces.length) {
    const li = document.createElement("li");
    li.className = "ns-empty";
    li.textContent = emptyText;
    listEl.appendChild(li);
    return;
  }
  for (const ns of namespaces) {
    const li = document.createElement("li");
    li.textContent = ns;
    listEl.appendChild(li);
  }
}

function diffNamespaces(left, right) {
  const leftSet = new Set(left);
  const rightSet = new Set(right);
  const onlyLeft = left.filter((ns) => !rightSet.has(ns));
  const onlyRight = right.filter((ns) => !leftSet.has(ns));
  const both = left.filter((ns) => rightSet.has(ns));
  return { onlyLeft, onlyRight, both };
}

function renderNamespacesDialogContent() {
  if (!namespacesDialogState) return;

  const { row, columns, primaryColumnId } = namespacesDialogState;
  const primaryColumn = columns.find((c) => c.id === primaryColumnId);
  const primaryNamespaces = namespacesForCell(row, primaryColumnId);
  const compareId = namespacesCompareSelect.value;

  namespacesDialogSubtitle.textContent = primaryColumn
    ? `Import: ${primaryColumn.label}`
    : "";

  if (!compareId) {
    namespacesSingleView.hidden = false;
    namespacesCompareView.hidden = true;
    namespacesDialogCount.textContent =
      primaryNamespaces.length === 0
        ? "No namespaces recorded for this import."
        : `${primaryNamespaces.length} namespace${primaryNamespaces.length === 1 ? "" : "s"}`;
    fillNamespaceList(namespacesDialogList, primaryNamespaces, "None");
    return;
  }

  const compareColumn = columns.find((c) => c.id === compareId);
  const compareNamespaces = namespacesForCell(row, compareId);
  const { onlyLeft, onlyRight, both } = diffNamespaces(primaryNamespaces, compareNamespaces);

  namespacesSingleView.hidden = true;
  namespacesCompareView.hidden = false;
  nsDiffOnlyATitle.textContent = "Only in current";
  nsDiffOnlyBTitle.textContent = "Only in prior";
  nsDiffOnlyAWhen.textContent = primaryColumn?.label || "";
  nsDiffOnlyBWhen.textContent = compareColumn?.label || "";
  fillNamespaceList(nsDiffOnlyA, onlyLeft, "None");
  fillNamespaceList(nsDiffBoth, both, "None");
  fillNamespaceList(nsDiffOnlyB, onlyRight, "None");
}

function openNamespacesDialog(row, columns, primaryColumnId) {
  const operatorName = displayRowLabel(row);
  namespacesDialogState = { row, columns, primaryColumnId };
  namespacesDialogTitle.textContent = operatorName;

  namespacesCompareSelect.innerHTML = '<option value="">No comparison</option>';
  for (const column of columns) {
    if (column.id === primaryColumnId) continue;
    const option = document.createElement("option");
    option.value = column.id;
    option.textContent = column.label;
    namespacesCompareSelect.appendChild(option);
  }
  namespacesCompareSelect.disabled = columns.length < 2;
  namespacesCompareSelect.value = "";

  renderNamespacesDialogContent();
  namespacesDialog.showModal();
}

namespacesCompareSelect.addEventListener("change", () => {
  renderNamespacesDialogContent();
});

namespacesDialog.addEventListener("close", () => {
  namespacesDialogState = null;
});

function setStatus(message, type = "") {
  statusBar.hidden = !message;
  statusBar.textContent = message;
  statusBar.className = `status-bar${type ? ` ${type}` : ""}`;
}

function statusClass(status) {
  const value = String(status || "").toLowerCase();
  if (["available", "succeeded", "healthy", "true"].includes(value)) return "ok";
  if (["progressing", "pending", "installing", "replacing"].includes(value)) return "warn";
  if (
    ["degraded", "unavailable", "false"].includes(value) ||
    value.startsWith("failed")
  ) {
    return "bad";
  }
  return "";
}

function formatSync(value) {
  if (!value) return "No snapshots yet";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString();
}

function cellTitle(cell) {
  if (!cell?.details) return "";
  const details = cell.details;
  if (details.kind === "node-resource") {
    const parts = [
      `allocatable ${details.allocatable || "—"}`,
      `allocated ${details.allocated || "—"}`,
      `capacity ${details.capacity || "—"}`,
      `available ${details.available || "—"}`,
    ];
    if (details.gpuResource) parts.push(details.gpuResource);
    return parts.join(" · ");
  }
  if (details.kind === "node-type-count") {
    return `${details.nodeCount} node(s)`;
  }
  if (details.message) return details.message;
  return "";
}

function cellFingerprint(cell) {
  if (!cell) return "";
  return JSON.stringify({
    version: cell.version || "",
    status: cell.status || "",
    namespaces: Array.isArray(cell.details?.namespaces)
      ? [...cell.details.namespaces].sort()
      : [],
  });
}

function rowDiffersAcrossColumns(row, columns) {
  if (columns.length < 2) return true;
  const first = cellFingerprint(row.cells[columns[0].id]);
  return columns.some((column) => cellFingerprint(row.cells[column.id]) !== first);
}

async function fetchJson(url, options) {
  const response = await fetch(url, options);
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.error || `Request failed (${response.status})`);
  }
  return data;
}

function clustersInChronologicalOrder() {
  return [...clustersCache].sort((a, b) => {
    const aTime = a.latestSync ? Date.parse(a.latestSync) : 0;
    const bTime = b.latestSync ? Date.parse(b.latestSync) : 0;
    if (aTime !== bTime) return aTime - bTime;
    return a.clusterName.localeCompare(b.clusterName);
  });
}

function updateClusterNavButtons() {
  const ordered = clustersInChronologicalOrder();
  const index = ordered.findIndex((c) => c.clusterName === selectedCluster);
  prevClusterBtn.disabled = index <= 0;
  nextClusterBtn.disabled = index < 0 || index >= ordered.length - 1;
}

function updateCompareControls() {
  const selectedCount = selectedColumnIds.size;
  compareColumnsBtn.disabled = compareMode || selectedCount < 2 || selectedCount > MAX_COMPARE_COLUMNS;
  compareColumnsBtn.textContent =
    selectedCount > 0 ? `Compare (${selectedCount})` : "Compare";

  diffOnlyWrap.hidden = !compareMode;
  closeCompareBtn.hidden = !compareMode;
  compareColumnsBtn.hidden = compareMode;
}

function showTiles() {
  selectedCluster = null;
  comparisonData = null;
  selectedColumnIds = new Set();
  compareMode = false;
  compareColumnIds = [];
  diffOnlyCheckbox.checked = false;
  tileView.hidden = false;
  detailView.hidden = true;
  updateCompareControls();
  renderTiles(clustersCache);
}

function showDetail(clusterName) {
  selectedCluster = clusterName;
  selectedColumnIds = new Set();
  compareMode = false;
  compareColumnIds = [];
  diffOnlyCheckbox.checked = false;
  tileView.hidden = true;
  detailView.hidden = false;
  detailTitle.textContent = clusterName;
  const meta = clustersCache.find((c) => c.clusterName === clusterName);
  detailMeta.textContent = meta
    ? `${meta.snapshotCount} snapshot(s) · latest ${formatSync(meta.latestSync)}`
    : "";
  updateClusterNavButtons();
  updateCompareControls();
  loadComparison(clusterName).catch((err) => setStatus(err.message, "error"));
}

function renderTiles(clusters) {
  tileGrid.innerHTML = "";
  if (!clusters.length) {
    emptyState.hidden = false;
    return;
  }
  emptyState.hidden = true;

  for (const cluster of clusters) {
    const tile = document.createElement("button");
    tile.type = "button";
    tile.className = "cluster-tile";
    tile.setAttribute("aria-label", `Open ${cluster.clusterName}`);

    const name = document.createElement("div");
    name.className = "tile-name";
    name.textContent = cluster.clusterName;

    const sync = document.createElement("div");
    sync.className = "tile-sync";
    sync.textContent = formatSync(cluster.latestSync);

    const footer = document.createElement("div");
    footer.className = "tile-footer";

    const count = document.createElement("span");
    count.textContent = `${cluster.snapshotCount} snapshot${cluster.snapshotCount === 1 ? "" : "s"}`;

    const pill = document.createElement("span");
    pill.className = `status-pill ${statusClass(cluster.available)}`;
    pill.textContent = cluster.available === "True" ? "Available" : cluster.available || "Unknown";

    footer.append(count, pill);
    tile.append(name, sync, footer);
    tile.addEventListener("click", () => showDetail(cluster.clusterName));
    tileGrid.appendChild(tile);
  }
}

function visibleColumns() {
  if (!comparisonData) return [];
  if (compareMode) {
    return comparisonData.columns.filter((column) => compareColumnIds.includes(column.id));
  }
  return comparisonData.columns;
}

function onColumnCheckboxChange(columnId, checked, checkbox) {
  if (compareMode) return;

  if (checked) {
    if (selectedColumnIds.size >= MAX_COMPARE_COLUMNS) {
      checkbox.checked = false;
      setStatus(`Select at most ${MAX_COMPARE_COLUMNS} columns to compare.`, "error");
      return;
    }
    selectedColumnIds.add(columnId);
    setStatus("");
  } else {
    selectedColumnIds.delete(columnId);
  }
  updateCompareControls();
}

function renderTable() {
  if (!comparisonData) return;

  const columns = visibleColumns();
  const rows = comparisonData.rows;
  const showDiffOnly = compareMode && diffOnlyCheckbox.checked;

  if (!comparisonData.columns.length || !rows.length) {
    detailEmpty.hidden = false;
    tableWrap.hidden = true;
    return;
  }

  if (!columns.length) {
    detailEmpty.hidden = false;
    detailEmpty.innerHTML = "<p>Select columns and click Compare to view a comparison.</p>";
    tableWrap.hidden = true;
    return;
  }

  detailEmpty.hidden = true;
  tableWrap.hidden = false;

  tableHeadRow.innerHTML = '<th class="sticky-col">Component</th>';
  for (const column of columns) {
    const th = document.createElement("th");
    const head = document.createElement("div");
    head.className = "column-head";

    if (!compareMode) {
      const label = document.createElement("label");
      label.className = "column-select";
      const checkbox = document.createElement("input");
      checkbox.type = "checkbox";
      checkbox.checked = selectedColumnIds.has(column.id);
      checkbox.addEventListener("change", (event) => {
        onColumnCheckboxChange(column.id, event.target.checked, event.target);
      });
      const text = document.createElement("span");
      text.textContent = column.label;
      text.title = column.date;
      label.append(checkbox, text);
      head.appendChild(label);
    } else {
      const text = document.createElement("span");
      text.className = "column-label";
      text.textContent = column.label;
      text.title = column.date;
      head.appendChild(text);
    }

    th.appendChild(head);
    tableHeadRow.appendChild(th);
  }

  tableBody.innerHTML = "";
  let lastSortOrder = null;
  let renderedRows = 0;

  for (const row of rows) {
    if (showDiffOnly && !rowDiffersAcrossColumns(row, columns)) {
      continue;
    }

    if (lastSortOrder !== null && Math.floor(row.sortOrder / 100) !== Math.floor(lastSortOrder / 100)) {
      const divider = document.createElement("tr");
      divider.className = "section-divider";
      const td = document.createElement("td");
      td.colSpan = columns.length + 1;
      if (row.sortOrder >= 400) {
        td.textContent = "Network";
      } else if (row.sortOrder >= 300) {
        td.textContent = "Nodes";
      } else if (row.sortOrder >= 200) {
        td.textContent = "Installed Operators (OLM)";
      } else {
        td.textContent = "Cluster Operators";
      }
      divider.appendChild(td);
      tableBody.appendChild(divider);
    }
    lastSortOrder = row.sortOrder;
    renderedRows += 1;

    const tr = document.createElement("tr");
    if (row.sortOrder === 0) {
      tr.className = "cluster-version-row";
    }

    const labelTd = document.createElement("td");
    labelTd.className = "label-cell";
    labelTd.textContent = displayRowLabel(row);
    tr.appendChild(labelTd);

    let previousVersion = null;
    let previousNsSignature = null;

    for (const column of columns) {
      const td = document.createElement("td");
      const cell = row.cells[column.id];
      const isInstalledOperator = row.sortOrder >= 200 && row.sortOrder < 300;
      const isNodeOrNetwork = row.sortOrder >= 300;

      if (!cell || (!cell.version && !cell.status && !isInstalledOperator && !isNodeOrNetwork)) {
        td.className = "cell-empty";
        td.textContent = "—";
        previousVersion = previousVersion;
        previousNsSignature = previousNsSignature;
      } else {
        const title = cellTitle(cell);
        if (title) td.title = title;

        if (cell && (cell.version || cell.status || isNodeOrNetwork)) {
          const versionSpan = document.createElement("span");
          versionSpan.className = "version";
          versionSpan.textContent = cell.version || "—";
          td.appendChild(versionSpan);

          if (cell.status) {
            const pill = document.createElement("span");
            pill.className = `status-pill ${statusClass(cell.status)}`;
            pill.textContent = cell.status;
            td.appendChild(pill);
          }

          if (previousVersion !== null && cell.version && previousVersion !== cell.version) {
            td.classList.add("changed");
          }
          previousVersion = cell.version || previousVersion;
        } else if (!cell) {
          td.className = "cell-empty";
          const empty = document.createElement("span");
          empty.textContent = "—";
          td.appendChild(empty);
        }

        if (isInstalledOperator && cell) {
          const namespaces = namespacesForCell(row, column.id);
          const signature = namespacesSignature(namespaces);
          const nsBtn = document.createElement("button");
          nsBtn.type = "button";
          nsBtn.className = "ns-btn secondary";
          nsBtn.textContent = namespaces.length
            ? `Namespaces (${namespaces.length})`
            : "Namespaces";
          if (previousNsSignature !== null && signature !== previousNsSignature) {
            nsBtn.classList.add("ns-btn-changed");
          }
          previousNsSignature = signature;
          nsBtn.addEventListener("click", (event) => {
            event.stopPropagation();
            openNamespacesDialog(row, columns, column.id);
          });
          td.appendChild(nsBtn);
        }
      }

      tr.appendChild(td);
    }

    tableBody.appendChild(tr);
  }

  if (showDiffOnly && renderedRows === 0) {
    const empty = document.createElement("tr");
    const td = document.createElement("td");
    td.colSpan = columns.length + 1;
    td.className = "cell-empty";
    td.textContent = "No differences across the selected imports.";
    empty.appendChild(td);
    tableBody.appendChild(empty);
  }

  updateCompareControls();
}

async function loadClusters() {
  const { clusters } = await fetchJson("/api/clusters");
  clustersCache = clusters;
  if (selectedCluster) {
    showDetail(selectedCluster);
  } else {
    renderTiles(clusters);
  }
}

async function loadComparison(clusterName) {
  comparisonData = await fetchJson(`/api/compare/${encodeURIComponent(clusterName)}`);
  selectedColumnIds = new Set();
  compareMode = false;
  compareColumnIds = [];
  diffOnlyCheckbox.checked = false;
  renderTable();
}

prevClusterBtn.addEventListener("click", () => {
  const ordered = clustersInChronologicalOrder();
  const index = ordered.findIndex((c) => c.clusterName === selectedCluster);
  if (index > 0) {
    showDetail(ordered[index - 1].clusterName);
  }
});

nextClusterBtn.addEventListener("click", () => {
  const ordered = clustersInChronologicalOrder();
  const index = ordered.findIndex((c) => c.clusterName === selectedCluster);
  if (index >= 0 && index < ordered.length - 1) {
    showDetail(ordered[index + 1].clusterName);
  }
});

compareColumnsBtn.addEventListener("click", () => {
  if (selectedColumnIds.size < 2 || selectedColumnIds.size > MAX_COMPARE_COLUMNS) {
    setStatus(`Select 2 or ${MAX_COMPARE_COLUMNS} date columns to compare.`, "error");
    return;
  }
  if (!comparisonData) return;

  compareColumnIds = comparisonData.columns
    .filter((column) => selectedColumnIds.has(column.id))
    .map((column) => column.id);
  compareMode = true;
  diffOnlyCheckbox.checked = false;
  setStatus(`Comparing ${compareColumnIds.length} selected imports.`, "success");
  updateCompareControls();
  renderTable();
});

closeCompareBtn.addEventListener("click", () => {
  compareMode = false;
  compareColumnIds = [];
  diffOnlyCheckbox.checked = false;
  setStatus("");
  updateCompareControls();
  renderTable();
});

diffOnlyCheckbox.addEventListener("change", () => {
  if (compareMode) {
    renderTable();
  }
});

backBtn.addEventListener("click", () => {
  showTiles();
});

syncBtn.addEventListener("click", async () => {
  syncBtn.disabled = true;
  setStatus("Syncing ManagedClusters and ClusterCollector resources…");
  try {
    const result = await fetchJson("/api/sync", { method: "POST" });
    const stored = result.results.filter((item) => item.stored).length;
    const refreshed = result.results.filter((item) => item.refreshed).length;
    await loadClusters();
    setStatus(
      `Sync complete. Scanned ${result.scanned} managed cluster(s), stored ${stored}, refreshed ${refreshed}.`,
      "success"
    );
  } catch (err) {
    setStatus(err.message, "error");
  } finally {
    syncBtn.disabled = false;
  }
});

updateCompareControls();
loadClusters().catch((err) => setStatus(err.message, "error"));
