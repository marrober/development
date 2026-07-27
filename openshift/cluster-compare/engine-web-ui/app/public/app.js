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

let clustersCache = [];
let selectedCluster = null;
let namespacesDialogState = null;

function displayRowLabel(row) {
  if (row.rowKey?.startsWith("installed-operator:")) {
    return row.rowKey.slice("installed-operator:".length);
  }
  // Strip legacy "name [ns1, ns2, …]" labels from older snapshots.
  return String(row.label || "").replace(/\s\[[^\]]*\]$/, "");
}

function namespacesForCell(row, columnId) {
  const namespaces = row.cells[columnId]?.details?.namespaces;
  if (!Array.isArray(namespaces)) return [];
  return [...new Set(namespaces.filter(Boolean))].sort((a, b) => a.localeCompare(b));
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
  nsDiffOnlyATitle.textContent = `Only in ${primaryColumn?.label || "this import"}`;
  nsDiffOnlyBTitle.textContent = `Only in ${compareColumn?.label || "compared import"}`;
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
  if (!cell?.details?.message) return "";
  return cell.details.message;
}

async function fetchJson(url, options) {
  const response = await fetch(url, options);
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.error || `Request failed (${response.status})`);
  }
  return data;
}

function showTiles() {
  selectedCluster = null;
  tileView.hidden = false;
  detailView.hidden = true;
  renderTiles(clustersCache);
}

function showDetail(clusterName) {
  selectedCluster = clusterName;
  tileView.hidden = true;
  detailView.hidden = false;
  detailTitle.textContent = clusterName;
  const meta = clustersCache.find((c) => c.clusterName === clusterName);
  detailMeta.textContent = meta
    ? `${meta.snapshotCount} snapshot(s) · latest ${formatSync(meta.latestSync)} · available ${meta.available}`
    : "";
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

function renderTable(data) {
  const { columns, rows } = data;
  if (!columns.length || !rows.length) {
    detailEmpty.hidden = false;
    tableWrap.hidden = true;
    return;
  }

  detailEmpty.hidden = true;
  tableWrap.hidden = false;

  tableHeadRow.innerHTML = '<th class="sticky-col">Component</th>';
  for (const column of columns) {
    const th = document.createElement("th");
    th.textContent = column.label;
    th.title = column.date;
    tableHeadRow.appendChild(th);
  }

  tableBody.innerHTML = "";
  let lastSortOrder = null;

  for (const row of rows) {
    if (lastSortOrder !== null && Math.floor(row.sortOrder / 100) !== Math.floor(lastSortOrder / 100)) {
      const divider = document.createElement("tr");
      divider.className = "section-divider";
      const td = document.createElement("td");
      td.colSpan = columns.length + 1;
      td.textContent =
        row.sortOrder >= 200 ? "Installed Operators (OLM)" : "Cluster Operators";
      divider.appendChild(td);
      tableBody.appendChild(divider);
    }
    lastSortOrder = row.sortOrder;

    const tr = document.createElement("tr");
    if (row.sortOrder === 0) {
      tr.className = "cluster-version-row";
    }

    const labelTd = document.createElement("td");
    labelTd.className = "label-cell";
    labelTd.textContent = displayRowLabel(row);
    tr.appendChild(labelTd);

    let previousVersion = null;
    for (const column of columns) {
      const td = document.createElement("td");
      const cell = row.cells[column.id];
      const isInstalledOperator = row.sortOrder >= 200;

      if (!cell || (!cell.version && !cell.status && !isInstalledOperator)) {
        td.className = "cell-empty";
        td.textContent = "—";
      } else {
        const title = cellTitle(cell);
        if (title) td.title = title;

        if (cell && (cell.version || cell.status)) {
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
          const nsBtn = document.createElement("button");
          nsBtn.type = "button";
          nsBtn.className = "ns-btn secondary";
          nsBtn.textContent = namespaces.length
            ? `Namespaces (${namespaces.length})`
            : "Namespaces";
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
  const data = await fetchJson(`/api/compare/${encodeURIComponent(clusterName)}`);
  renderTable(data);
}

backBtn.addEventListener("click", () => {
  showTiles();
});

syncBtn.addEventListener("click", async () => {
  syncBtn.disabled = true;
  setStatus("Syncing ManagedClusters and ClusterCollector resources…");
  try {
    const result = await fetchJson("/api/sync", { method: "POST" });
    const stored = result.results.filter((item) => item.stored).length;
    await loadClusters();
    setStatus(
      `Sync complete. Scanned ${result.scanned} managed cluster(s), stored ${stored} new snapshot(s).`,
      "success"
    );
  } catch (err) {
    setStatus(err.message, "error");
  } finally {
    syncBtn.disabled = false;
  }
});

loadClusters().catch((err) => setStatus(err.message, "error"));
