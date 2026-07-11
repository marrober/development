const clusterSelect = document.getElementById("clusterSelect");
const syncBtn = document.getElementById("syncBtn");
const statusBar = document.getElementById("statusBar");
const emptyState = document.getElementById("emptyState");
const tableWrap = document.getElementById("tableWrap");
const tableHeadRow = document.getElementById("tableHeadRow");
const tableBody = document.getElementById("tableBody");

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

async function loadClusters(selected) {
  const { clusters } = await fetchJson("/api/clusters");
  clusterSelect.innerHTML = '<option value="">Select a cluster…</option>';
  for (const cluster of clusters) {
    const option = document.createElement("option");
    option.value = cluster.clusterName;
    option.textContent = `${cluster.clusterName} (${cluster.snapshotCount} snapshots)`;
    clusterSelect.appendChild(option);
  }
  if (selected && [...clusterSelect.options].some((opt) => opt.value === selected)) {
    clusterSelect.value = selected;
  }
}

function renderTable(data) {
  const { columns, rows } = data;
  if (!columns.length || !rows.length) {
    emptyState.hidden = false;
    tableWrap.hidden = true;
    emptyState.innerHTML = "<p>No snapshots stored for this cluster yet. Run sync to collect data.</p>";
    return;
  }

  emptyState.hidden = true;
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
    labelTd.textContent = row.label;
    tr.appendChild(labelTd);

    let previousVersion = null;
    for (const column of columns) {
      const td = document.createElement("td");
      const cell = row.cells[column.id];

      if (!cell || (!cell.version && !cell.status)) {
        td.className = "cell-empty";
        td.textContent = "—";
      } else {
        const title = cellTitle(cell);
        if (title) td.title = title;

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
      }

      tr.appendChild(td);
    }

    tableBody.appendChild(tr);
  }
}

async function loadComparison(clusterName) {
  if (!clusterName) {
    emptyState.hidden = false;
    tableWrap.hidden = true;
    emptyState.innerHTML = "<p>Select a cluster or sync data from your OpenShift hub to begin.</p>";
    return;
  }

  const data = await fetchJson(`/api/compare/${encodeURIComponent(clusterName)}`);
  renderTable(data);
}

clusterSelect.addEventListener("change", () => {
  loadComparison(clusterSelect.value).catch((err) => setStatus(err.message, "error"));
});

syncBtn.addEventListener("click", async () => {
  syncBtn.disabled = true;
  setStatus("Syncing HelloSpoke resources from the cluster…");
  try {
    const result = await fetchJson("/api/sync", { method: "POST" });
    const stored = result.results.filter((item) => item.stored).length;
    await loadClusters(clusterSelect.value);
    if (clusterSelect.value) {
      await loadComparison(clusterSelect.value);
    } else if (result.results.length === 1) {
      clusterSelect.value = result.results[0].clusterName;
      await loadComparison(clusterSelect.value);
    }
    setStatus(
      `Sync complete. Scanned ${result.scanned} CR(s), stored ${stored} new snapshot(s).`,
      "success"
    );
  } catch (err) {
    setStatus(err.message, "error");
  } finally {
    syncBtn.disabled = false;
  }
});

loadClusters()
  .then(() => {
    if (clusterSelect.options.length === 2) {
      clusterSelect.selectedIndex = 1;
      return loadComparison(clusterSelect.value);
    }
  })
  .catch((err) => setStatus(err.message, "error"));
