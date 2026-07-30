const fs = require("fs");
const path = require("path");
const { normalizeClusterSnapshot } = require("./normalize");
const { buildNodeEntries, buildNetworkEntries } = require("./resources");
const { operatorDisplayName, operatorRowKey, operatorPackageName, shouldShowStatus } = require("./operators");

function normalizeEntryIdentity(entry) {
  const rowKey = String(entry.rowKey || "");
  if (!rowKey.startsWith("installed-operator:")) {
    return {
      rowKey,
      label: entry.rowLabel,
      status: shouldShowStatus(entry.status) ? entry.status : "",
    };
  }

  let details = {};
  try {
    details =
      typeof entry.details === "string"
        ? JSON.parse(entry.details || "{}")
        : entry.details || {};
  } catch {
    details = {};
  }

  const packageName =
    details.packageName ||
    operatorPackageName(rowKey.slice("installed-operator:".length)) ||
    operatorPackageName(entry.rowLabel || "");
  const label =
    details.displayName ||
    operatorDisplayName({
      name: packageName,
      displayName: details.displayName || "",
    });

  const rawStatus = entry.status || details.phase || "";
  return {
    rowKey: `installed-operator:${packageName || "unknown"}`,
    label,
    status: shouldShowStatus(rawStatus) ? rawStatus : "",
  };
}

const DATABASE_TYPE = (process.env.DATABASE_TYPE || process.env.DB_TYPE || "").toLowerCase();
const usePostgres =
  DATABASE_TYPE === "postgresql" ||
  DATABASE_TYPE === "postgres" ||
  Boolean(process.env.PGHOST || process.env.DATABASE_URL);

let backend = null;

function buildEntries(snapshot) {
  const entries = [];

  const clusterVersion = snapshot.clusterVersion || {};
  entries.push({
    rowKey: "cluster-version",
    rowLabel: "Cluster Version",
    sortOrder: 0,
    version: clusterVersion.version || "",
    status: shouldShowStatus(clusterVersion.status) ? clusterVersion.status : "",
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
      status: shouldShowStatus(operator.status) ? operator.status : "",
      details: JSON.stringify({
        available: operator.available || "",
        progressing: operator.progressing || "",
        degraded: operator.degraded || "",
        message: operator.message || "",
      }),
    });
  }

  const installedOperators = [...(snapshot.installedOperators || [])].sort((a, b) =>
    operatorDisplayName(a).localeCompare(operatorDisplayName(b))
  );
  for (const operator of installedOperators) {
    const namespaces = Array.isArray(operator.namespaces)
      ? operator.namespaces
      : operator.namespace
        ? [operator.namespace]
        : [];
    const status = shouldShowStatus(operator.status)
      ? operator.status
      : shouldShowStatus(operator.phase)
        ? operator.phase
        : "";
    entries.push({
      rowKey: operatorRowKey(operator),
      rowLabel: operatorDisplayName(operator),
      sortOrder: 200,
      version: operator.version || "",
      status,
      details: JSON.stringify({
        namespaces,
        phase: operator.phase || "",
        message: operator.message || "",
        packageName: operatorPackageName(operator.name || ""),
        displayName: operatorDisplayName(operator),
        csvName: operator.name || "",
      }),
    });
  }

  entries.push(...buildNodeEntries(snapshot.nodes));
  entries.push(...buildNetworkEntries(snapshot.network));

  return entries;
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

function createSqliteBackend() {
  let Database;
  try {
    Database = require("better-sqlite3");
  } catch (err) {
    throw new Error(
      "SQLite support requires the better-sqlite3 package. Install with `npm install` (no --omit=dev), or set DATABASE_TYPE=postgresql / PGHOST for PostgreSQL.",
      { cause: err }
    );
  }
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
    SELECT cluster_name AS "clusterName", COUNT(*) AS "snapshotCount",
           MAX(last_sync) AS "latestSync"
    FROM snapshots
    GROUP BY cluster_name
    ORDER BY cluster_name
  `);
  const listSnapshotsStmt = db.prepare(`
    SELECT id, cluster_name AS "clusterName", last_sync AS "lastSync",
           spoke_url AS "spokeUrl", created_at AS "createdAt"
    FROM snapshots
    WHERE cluster_name = @clusterName
    ORDER BY last_sync ASC
  `);
  const listEntriesStmt = db.prepare(`
    SELECT row_key AS "rowKey", row_label AS "rowLabel", sort_order AS "sortOrder",
           version, status, details
    FROM version_entries
    WHERE snapshot_id = @snapshotId
    ORDER BY sort_order ASC, row_label ASC
  `);
  const hasSnapshotStmt = db.prepare(`
    SELECT 1 AS found FROM snapshots
    WHERE cluster_name = @clusterName AND last_sync = @lastSync
    LIMIT 1
  `);

  const listAllSnapshotsByTimeStmt = db.prepare(`
    SELECT s.id,
           s.cluster_name AS "clusterName",
           s.last_sync AS "lastSync",
           s.spoke_url AS "spokeUrl",
           s.created_at AS "createdAt",
           COUNT(e.id) AS "entryCount"
    FROM snapshots s
    LEFT JOIN version_entries e ON e.snapshot_id = s.id
    GROUP BY s.id
    ORDER BY s.last_sync ASC, s.cluster_name ASC
  `);
  const listAllSnapshotsByClusterStmt = db.prepare(`
    SELECT s.id,
           s.cluster_name AS "clusterName",
           s.last_sync AS "lastSync",
           s.spoke_url AS "spokeUrl",
           s.created_at AS "createdAt",
           COUNT(e.id) AS "entryCount"
    FROM snapshots s
    LEFT JOIN version_entries e ON e.snapshot_id = s.id
    GROUP BY s.id
    ORDER BY s.cluster_name ASC, s.last_sync DESC
  `);
  const deleteSnapshotByIdStmt = db.prepare(`DELETE FROM snapshots WHERE id = ?`);

  return {
    type: "sqlite",
    info: dbPath,
    async init() {},
    async hasSnapshot(clusterName, lastSync) {
      return Boolean(hasSnapshotStmt.get({ clusterName, lastSync }));
    },
    async saveSnapshot(snapshot) {
      const normalized = normalizeClusterSnapshot(snapshot);
      const { clusterName, date } = normalized;
      if (!clusterName || !date) {
        return { stored: false, reason: "missing clusterName or date" };
      }

      const existing = selectSnapshotId.get({ clusterName, lastSync: date });
      if (!existing) {
        insertSnapshot.run({
          clusterName,
          lastSync: date,
          spokeUrl: normalized.spokeURL || null,
        });
      }

      const row = selectSnapshotId.get({ clusterName, lastSync: date });
      if (!row) {
        return { stored: false, reason: "failed to resolve snapshot id" };
      }

      const entries = buildEntries(normalized);
      const tx = db.transaction((items) => {
        db.prepare(`DELETE FROM version_entries WHERE snapshot_id = ?`).run(row.id);
        for (const entry of items) {
          insertEntry.run({
            snapshotId: row.id,
            ...entry,
          });
        }
      });
      tx(entries);

      return {
        stored: !existing,
        refreshed: Boolean(existing),
        reason: existing ? "refreshed" : undefined,
        snapshotId: row.id,
        entryCount: entries.length,
      };
    },
    async listClusters() {
      return listClustersStmt.all();
    },
    async listSnapshots(sort = "time") {
      const rows =
        sort === "cluster"
          ? listAllSnapshotsByClusterStmt.all()
          : listAllSnapshotsByTimeStmt.all();
      return rows.map((row) => ({
        ...row,
        entryCount: Number(row.entryCount) || 0,
      }));
    },
    async deleteSnapshots(ids) {
      const uniqueIds = [
        ...new Set(
          (Array.isArray(ids) ? ids : [])
            .map((id) => Number(id))
            .filter((id) => Number.isInteger(id) && id > 0)
        ),
      ];
      if (!uniqueIds.length) {
        return { deleted: 0, ids: [] };
      }
      const tx = db.transaction((snapshotIds) => {
        let deleted = 0;
        for (const id of snapshotIds) {
          const result = deleteSnapshotByIdStmt.run(id);
          deleted += result.changes;
        }
        return deleted;
      });
      const deleted = tx(uniqueIds);
      return { deleted, ids: uniqueIds };
    },
    async getComparison(clusterName) {
      const snapshots = listSnapshotsStmt.all({ clusterName });
      return buildComparison(clusterName, snapshots, (snapshotId) =>
        listEntriesStmt.all({ snapshotId })
      );
    },
    async close() {
      db.close();
    },
  };
}

function createPostgresBackend() {
  const { Pool } = require("pg");

  const connectionString = process.env.DATABASE_URL;
  const pool = connectionString
    ? new Pool({ connectionString })
    : new Pool({
        host: process.env.PGHOST || "localhost",
        port: Number(process.env.PGPORT || 5432),
        database: process.env.PGDATABASE || process.env.POSTGRES_DB || "clustercompare",
        user: process.env.PGUSER || process.env.POSTGRES_USER || "clustercompare",
        password: process.env.PGPASSWORD || process.env.POSTGRES_PASSWORD || "",
        ssl: process.env.PGSSLMODE === "require" ? { rejectUnauthorized: false } : undefined,
      });

  const info = connectionString
    ? "DATABASE_URL"
    : `${process.env.PGUSER || "clustercompare"}@${process.env.PGHOST || "localhost"}:${process.env.PGPORT || 5432}/${process.env.PGDATABASE || "clustercompare"}`;

  return {
    type: "postgresql",
    info,
    async init() {
      await pool.query(`
        CREATE TABLE IF NOT EXISTS snapshots (
          id SERIAL PRIMARY KEY,
          cluster_name TEXT NOT NULL,
          last_sync TEXT NOT NULL,
          spoke_url TEXT,
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          UNIQUE(cluster_name, last_sync)
        );

        CREATE TABLE IF NOT EXISTS version_entries (
          id SERIAL PRIMARY KEY,
          snapshot_id INTEGER NOT NULL REFERENCES snapshots(id) ON DELETE CASCADE,
          row_key TEXT NOT NULL,
          row_label TEXT NOT NULL,
          sort_order INTEGER NOT NULL,
          version TEXT,
          status TEXT,
          details TEXT,
          UNIQUE(snapshot_id, row_key)
        );

        CREATE INDEX IF NOT EXISTS idx_snapshots_cluster ON snapshots(cluster_name, last_sync);
        CREATE INDEX IF NOT EXISTS idx_entries_snapshot ON version_entries(snapshot_id);
      `);
    },
    async hasSnapshot(clusterName, lastSync) {
      const result = await pool.query(
        `SELECT 1 AS found FROM snapshots
         WHERE cluster_name = $1 AND last_sync = $2
         LIMIT 1`,
        [clusterName, lastSync]
      );
      return result.rowCount > 0;
    },
    async saveSnapshot(snapshot) {
      const normalized = normalizeClusterSnapshot(snapshot);
      const { clusterName, date } = normalized;
      if (!clusterName || !date) {
        return { stored: false, reason: "missing clusterName or date" };
      }

      const client = await pool.connect();
      try {
        await client.query("BEGIN");
        const existing = await client.query(
          `SELECT id FROM snapshots WHERE cluster_name = $1 AND last_sync = $2`,
          [clusterName, date]
        );
        let snapshotId = existing.rows[0]?.id;
        const wasExisting = Boolean(snapshotId);

        if (!snapshotId) {
          const insert = await client.query(
            `INSERT INTO snapshots (cluster_name, last_sync, spoke_url)
             VALUES ($1, $2, $3)
             ON CONFLICT (cluster_name, last_sync) DO UPDATE SET
               spoke_url = COALESCE(EXCLUDED.spoke_url, snapshots.spoke_url)
             RETURNING id`,
            [clusterName, date, normalized.spokeURL || null]
          );
          snapshotId = insert.rows[0]?.id;
        } else if (normalized.spokeURL) {
          await client.query(
            `UPDATE snapshots SET spoke_url = $1 WHERE id = $2`,
            [normalized.spokeURL, snapshotId]
          );
        }

        if (!snapshotId) {
          await client.query("ROLLBACK");
          return { stored: false, reason: "failed to resolve snapshot id" };
        }

        const entries = buildEntries(normalized);
        await client.query(`DELETE FROM version_entries WHERE snapshot_id = $1`, [snapshotId]);
        for (const entry of entries) {
          await client.query(
            `INSERT INTO version_entries
               (snapshot_id, row_key, row_label, sort_order, version, status, details)
             VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [
              snapshotId,
              entry.rowKey,
              entry.rowLabel,
              entry.sortOrder,
              entry.version,
              entry.status,
              entry.details,
            ]
          );
        }

        await client.query("COMMIT");
        return {
          stored: !wasExisting,
          refreshed: wasExisting,
          reason: wasExisting ? "refreshed" : undefined,
          snapshotId,
          entryCount: entries.length,
        };
      } catch (err) {
        await client.query("ROLLBACK");
        throw err;
      } finally {
        client.release();
      }
    },
    async listClusters() {
      const result = await pool.query(`
        SELECT cluster_name AS "clusterName",
               COUNT(*)::int AS "snapshotCount",
               MAX(last_sync) AS "latestSync"
        FROM snapshots
        GROUP BY cluster_name
        ORDER BY cluster_name
      `);
      return result.rows;
    },
    async listSnapshots(sort = "time") {
      const orderBy =
        sort === "cluster"
          ? `s.cluster_name ASC, s.last_sync DESC`
          : `s.last_sync ASC, s.cluster_name ASC`;
      const result = await pool.query(`
        SELECT s.id,
               s.cluster_name AS "clusterName",
               s.last_sync AS "lastSync",
               s.spoke_url AS "spokeUrl",
               s.created_at AS "createdAt",
               COUNT(e.id)::int AS "entryCount"
        FROM snapshots s
        LEFT JOIN version_entries e ON e.snapshot_id = s.id
        GROUP BY s.id, s.cluster_name, s.last_sync, s.spoke_url, s.created_at
        ORDER BY ${orderBy}
      `);
      return result.rows;
    },
    async deleteSnapshots(ids) {
      const uniqueIds = [
        ...new Set(
          (Array.isArray(ids) ? ids : [])
            .map((id) => Number(id))
            .filter((id) => Number.isInteger(id) && id > 0)
        ),
      ];
      if (!uniqueIds.length) {
        return { deleted: 0, ids: [] };
      }
      const result = await pool.query(
        `DELETE FROM snapshots WHERE id = ANY($1::int[])`,
        [uniqueIds]
      );
      return { deleted: result.rowCount || 0, ids: uniqueIds };
    },
    async getComparison(clusterName) {
      const snapshotsResult = await pool.query(
        `SELECT id, cluster_name AS "clusterName", last_sync AS "lastSync",
                spoke_url AS "spokeUrl", created_at AS "createdAt"
         FROM snapshots
         WHERE cluster_name = $1
         ORDER BY last_sync ASC`,
        [clusterName]
      );
      const snapshots = snapshotsResult.rows;
      const entriesBySnapshot = new Map();
      for (const snapshot of snapshots) {
        const entries = await pool.query(
          `SELECT row_key AS "rowKey", row_label AS "rowLabel", sort_order AS "sortOrder",
                  version, status, details
           FROM version_entries
           WHERE snapshot_id = $1
           ORDER BY sort_order ASC, row_label ASC`,
          [snapshot.id]
        );
        entriesBySnapshot.set(snapshot.id, entries.rows);
      }
      return buildComparison(clusterName, snapshots, (snapshotId) =>
        entriesBySnapshot.get(snapshotId) || []
      );
    },
    async close() {
      await pool.end();
    },
  };
}

function buildComparison(clusterName, snapshots, getEntries) {
  if (snapshots.length === 0) {
    return { clusterName, columns: [], rows: [] };
  }

  const snapshotData = snapshots.map((snapshot) => ({
    ...snapshot,
    entries: getEntries(snapshot.id),
  }));

  const rowMap = new Map();
  for (const snapshot of snapshotData) {
    for (const entry of snapshot.entries) {
      const identity = normalizeEntryIdentity(entry);
      if (!rowMap.has(identity.rowKey)) {
        rowMap.set(identity.rowKey, {
          rowKey: identity.rowKey,
          label: identity.label,
          sortOrder: entry.sortOrder,
          cells: {},
        });
      } else {
        const existing = rowMap.get(identity.rowKey);
        // Prefer a clean display name over legacy CSV names with versions/namespaces.
        if (identity.label && (!existing.label || /\.v\d+/i.test(existing.label) || /\[/.test(existing.label))) {
          existing.label = identity.label;
        }
      }
    }
  }

  for (const snapshot of snapshotData) {
    const columnId = snapshot.lastSync;
    for (const entry of snapshot.entries) {
      const identity = normalizeEntryIdentity(entry);
      const row = rowMap.get(identity.rowKey);
      let details = {};
      try {
        details =
          typeof entry.details === "string"
            ? JSON.parse(entry.details || "{}")
            : entry.details || {};
      } catch {
        details = {};
      }
      row.cells[columnId] = {
        version: entry.version,
        status: identity.status,
        details,
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

async function initDb() {
  if (backend) {
    return backend;
  }
  backend = usePostgres ? createPostgresBackend() : createSqliteBackend();
  await backend.init();
  return backend;
}

function getBackend() {
  if (!backend) {
    throw new Error("database not initialized; call initDb() first");
  }
  return backend;
}

async function hasSnapshot(clusterName, lastSync) {
  return getBackend().hasSnapshot(clusterName, lastSync);
}

async function saveSnapshot(snapshot) {
  return getBackend().saveSnapshot(snapshot);
}

async function listClusters() {
  return getBackend().listClusters();
}

async function listSnapshots(sort = "time") {
  return getBackend().listSnapshots(sort === "cluster" ? "cluster" : "time");
}

async function deleteSnapshots(ids) {
  return getBackend().deleteSnapshots(ids);
}

async function getComparison(clusterName) {
  return getBackend().getComparison(clusterName);
}

async function closeDb() {
  if (backend) {
    await backend.close();
    backend = null;
  }
}

module.exports = {
  initDb,
  closeDb,
  hasSnapshot,
  saveSnapshot,
  listClusters,
  listSnapshots,
  deleteSnapshots,
  getComparison,
  get dbType() {
    return backend?.type || (usePostgres ? "postgresql" : "sqlite");
  },
  get dbInfo() {
    return backend?.info || "";
  },
};
