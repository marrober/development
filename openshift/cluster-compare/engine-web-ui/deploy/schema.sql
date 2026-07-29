-- clustercompare schema for cluster-info-compare
-- Indexed by cluster_name + last_sync (snapshot date/time).

CREATE TABLE IF NOT EXISTS snapshots (
  id SERIAL PRIMARY KEY,
  cluster_name TEXT NOT NULL,
  last_sync TEXT NOT NULL,
  spoke_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (cluster_name, last_sync)
);

CREATE TABLE IF NOT EXISTS version_entries (
  id SERIAL PRIMARY KEY,
  snapshot_id INTEGER NOT NULL REFERENCES snapshots (id) ON DELETE CASCADE,
  row_key TEXT NOT NULL,
  row_label TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  version TEXT,
  status TEXT,
  details TEXT,
  UNIQUE (snapshot_id, row_key)
);

CREATE INDEX IF NOT EXISTS idx_snapshots_cluster
  ON snapshots (cluster_name, last_sync);

CREATE INDEX IF NOT EXISTS idx_entries_snapshot
  ON version_entries (snapshot_id);
