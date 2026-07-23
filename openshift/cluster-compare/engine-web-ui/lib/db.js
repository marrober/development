const fs = require("fs");
const path = require("path");
const Database = require("better-sqlite3");
const { normalizeClusterSnapshot } = require("./normalize");

const dataDir = path.join(__dirname, "..", "data");
const dbPath = process.env.DATABASE_PATH || path.join(dataDir, "cluster-info.db");

if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const db = new Database(dbPath);

db.pragma("journal_mode = WAL");

db.exec(`
  CREATE TABLE IF NOT EXISTS snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cluster_name TEXT NOT NULL,
    last_sync TEXT NOT NULL,
    spoke_url TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(cluster_name, last_sync)
  );

  CREATE TABLE IF NOT EXISTS version_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    snapshot_id INTEGER NOT NULL,
    row_key TEXT NOT NULL,
    row_label TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    version TEXT,
    status TEXT,
    details TEXT,
    FOREIGN KEY(snapshot_id) REFERENCES snapshots(id) ON DELETE CASCADE,
    UNIQUE(snapshot_id, row_key)
  );

  CREATE INDEX IF NOT EXISTS idx_snapshots_cluster ON snapshots(cluster_name, last_sync);
  CREATE INDEX IF NOT EXISTS idx_entries_snapshot ON version_entries(snapshot_id);
`);

const insertSnapshot = db.prepare(`
  INSERT OR IGNORE INTO snapshots (cluster_name, last_sync, spoke_url)
  VALUES (@clusterName, @lastSync, @spokeUrl)
`);

const selectSnapshotId = db.prepare(`
  SELECT id FROM snapshots
  WHERE cluster_name = @clusterName AND last_sync = @lastSync
`);

const insertEntry = db.prepare(`
  INSERT OR REPLACE INTO version_entries
    (snapshot_id, row_key, row_label, sort_order, version, status, details)
  VALUES
    (@snapshotId, @rowKey, @rowLabel, @sortOrder, @version, @status, @details)
`);

const listClustersStmt = db.prepare(`
  SELECT cluster_name AS clusterName, COUNT(*) AS snapshotCount, MAX(last_sync) AS latestSync
  FROM snapshots
  GROUP BY cluster_name
  ORDER BY cluster_name
`);

const listSnapshotsStmt = db.prepare(`
  SELECT id, cluster_name AS clusterName, last_sync AS lastSync, spoke_url AS spokeUrl, created_at AS createdAt
  FROM snapshots
  WHERE cluster_name = @clusterName
  ORDER BY last_sync ASC
`);

const listEntriesStmt = db.prepare(`
  SELECT row_key AS rowKey, row_label AS rowLabel, sort_order AS sortOrder,
         version, status, details
  FROM version_entries
  WHERE snapshot_id = @snapshotId
  ORDER BY sort_order ASC, row_label ASC
`);

function saveSnapshot(snapshot) {
  const normalized = normalizeClusterSnapshot(snapshot);

  const { clusterName, date } = normalized;
  if (!clusterName || !date) {
    return { stored: false, reason: "missing clusterName or date" };
  }

  insertSnapshot.run({
    clusterName,
    lastSync: date,
    spokeUrl: normalized.spokeURL || null,
  });

  const row = selectSnapshotId.get({ clusterName, lastSync: date });
  if (!row) {
    return { stored: false, reason: "failed to resolve snapshot id" };
  }

  const entries = buildEntries(normalized);
  const tx = db.transaction((items) => {
    for (const entry of items) {
      insertEntry.run({
        snapshotId: row.id,
        ...entry,
      });
    }
  });
  tx(entries);

  return { stored: true, snapshotId: row.id, entryCount: entries.length };
}

function buildEntries(snapshot) {
  const entries = [];

  const clusterVersion = snapshot.clusterVersion || {};
  entries.push({
    rowKey: "cluster-version",
    rowLabel: "Cluster Version",
    sortOrder: 0,
    version: clusterVersion.version || "",
    status: clusterVersion.status || "",
    details: JSON.stringify({
      message: clusterVersion.message || "",
    }),
  });

  const clusterOperators = [...(snapshot.clusterOperators || [])].sort((a, b) =>
    a.name.localeCompare(b.name)
  );
  for (const operator of clusterOperators) {
    entries.push({
      rowKey: `cluster-operator:${operator.name}`,
      rowLabel: operator.name,
      sortOrder: 100,
      version: operator.version || "",
      status: operator.status || "",
      details: JSON.stringify({
        available: operator.available || "",
        progressing: operator.progressing || "",
        degraded: operator.degraded || "",
        message: operator.message || "",
      }),
    });
  }

  const installedOperators = [...(snapshot.installedOperators || [])].sort((a, b) =>
    (a.name || "").localeCompare(b.name || "")
  );
  for (const operator of installedOperators) {
    const namespaces = Array.isArray(operator.namespaces)
      ? operator.namespaces
      : operator.namespace
        ? [operator.namespace]
        : [];
    const nsLabel = namespaces.length > 0 ? namespaces.join(", ") : "unknown";
    const label = `${operator.name} [${nsLabel}]`;
    entries.push({
      rowKey: `installed-operator:${operator.name}`,
      rowLabel: label,
      sortOrder: 200,
      version: operator.version || "",
      status: operator.status || "",
      details: JSON.stringify({
        namespaces,
        phase: operator.phase || "",
        message: operator.message || "",
      }),
    });
  }

  return entries;
}

function listClusters() {
  return listClustersStmt.all();
}

function getComparison(clusterName) {
  const snapshots = listSnapshotsStmt.all({ clusterName });
  if (snapshots.length === 0) {
    return { clusterName, columns: [], rows: [] };
  }

  const snapshotData = snapshots.map((snapshot) => ({
    ...snapshot,
    entries: listEntriesStmt.all({ snapshotId: snapshot.id }),
  }));

  const rowMap = new Map();
  for (const snapshot of snapshotData) {
    for (const entry of snapshot.entries) {
      if (!rowMap.has(entry.rowKey)) {
        rowMap.set(entry.rowKey, {
          rowKey: entry.rowKey,
          label: entry.rowLabel,
          sortOrder: entry.sortOrder,
          cells: {},
        });
      }
    }
  }

  for (const snapshot of snapshotData) {
    const columnId = snapshot.lastSync;
    for (const entry of snapshot.entries) {
      const row = rowMap.get(entry.rowKey);
      row.cells[columnId] = {
        version: entry.version,
        status: entry.status,
        details: entry.details ? JSON.parse(entry.details) : {},
      };
    }
  }

  const rows = [...rowMap.values()].sort((a, b) => {
    if (a.sortOrder !== b.sortOrder) return a.sortOrder - b.sortOrder;
    return a.label.localeCompare(b.label);
  });

  const columns = snapshots.map((snapshot) => ({
    id: snapshot.lastSync,
    date: snapshot.lastSync,
    label: formatColumnLabel(snapshot.lastSync),
    createdAt: snapshot.createdAt,
  }));

  return { clusterName, columns, rows };
}

function formatColumnLabel(lastSync) {
  const date = new Date(lastSync);
  if (Number.isNaN(date.getTime())) {
    return lastSync;
  }
  return date.toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

module.exports = {
  db,
  dbPath,
  saveSnapshot,
  listClusters,
  getComparison,
};
