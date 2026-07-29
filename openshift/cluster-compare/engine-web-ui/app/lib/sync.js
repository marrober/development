const { saveSnapshot, listClusters } = require("./db");
const {
  listManagedClusters,
  getClusterCollector,
  normalizeClusterCollector,
  config: k8sConfig,
} = require("./k8s");

// Matches collector-addon deploy template: --resync-interval=60 (minutes).
const RESYNC_INTERVAL_MINUTES = Number(process.env.RESYNC_INTERVAL_MINUTES || 60);

function computeNextSync(lastSync, intervalMinutes = RESYNC_INTERVAL_MINUTES) {
  if (!lastSync) return null;
  const parsed = Date.parse(lastSync);
  if (Number.isNaN(parsed)) return null;
  const minutes = Number(intervalMinutes);
  const safeMinutes = Number.isFinite(minutes) && minutes > 0 ? minutes : 60;
  return new Date(parsed + safeMinutes * 60 * 1000).toISOString();
}

async function lastSyncForCluster(clusterName, fallback = null) {
  try {
    const cr = await getClusterCollector(clusterName, k8sConfig.collectorName);
    if (!cr) return fallback;
    return cr.status?.lastSync || cr.status?.date || fallback;
  } catch {
    return fallback;
  }
}

/**
 * Discover ManagedClusters, then for each cluster namespace read the
 * ClusterCollector CR and import a snapshot when lastSync is new.
 */
async function syncFromCluster() {
  const managedClusters = await listManagedClusters();
  const results = [];

  for (const mc of managedClusters) {
    const clusterName = mc.metadata?.name;
    if (!clusterName) {
      continue;
    }

    const available = mc.status?.conditions?.find(
      (c) => c.type === "ManagedClusterConditionAvailable"
    );
    const hubAccepted = mc.status?.conditions?.find(
      (c) => c.type === "HubAcceptedManagedCluster"
    );

    let cr;
    try {
      cr = await getClusterCollector(clusterName, k8sConfig.collectorName);
    } catch (err) {
      results.push({
        clusterName,
        stored: false,
        reason: `failed to read ClusterCollector: ${err.message || err}`,
        available: available?.status,
        hubAccepted: hubAccepted?.status,
      });
      continue;
    }

    if (!cr) {
      results.push({
        clusterName,
        stored: false,
        reason: `no ClusterCollector/${k8sConfig.collectorName} in namespace ${clusterName}`,
        available: available?.status,
        hubAccepted: hubAccepted?.status,
      });
      continue;
    }

    const normalized = normalizeClusterCollector(cr);
    const lastSync = normalized.lastSync || normalized.snapshot.date;
    if (!lastSync) {
      results.push({
        clusterName,
        crName: normalized.crName,
        namespace: normalized.namespace,
        stored: false,
        reason: "ClusterCollector has no lastSync/date",
        available: available?.status,
        hubAccepted: hubAccepted?.status,
      });
      continue;
    }

    // Index by managed cluster name + lastSync; refresh entries when the CR
    // payload gains fields (nodes/network) even if lastSync is unchanged.
    const snapshot = {
      ...normalized.snapshot,
      clusterName,
      date: lastSync,
    };
    const outcome = await saveSnapshot(snapshot);
    results.push({
      clusterName,
      crName: normalized.crName,
      namespace: normalized.namespace,
      lastSync,
      nextSync: computeNextSync(lastSync),
      available: available?.status,
      hubAccepted: hubAccepted?.status,
      ...outcome,
    });
  }

  return {
    scanned: managedClusters.length,
    resyncIntervalMinutes: RESYNC_INTERVAL_MINUTES,
    results,
  };
}

/**
 * Return tiles for the UI: every managed cluster plus stored snapshot stats.
 * Falls back to database-only clusters when ManagedCluster API is unavailable.
 */
async function listClusterTiles() {
  const dbClusters = await listClusters();
  const byName = new Map(
    dbClusters.map((c) => [c.clusterName, { ...c, source: "database" }])
  );

  try {
    const managedClusters = await listManagedClusters();
    const tiles = await Promise.all(
      managedClusters.map(async (mc) => {
        const clusterName = mc.metadata?.name;
        if (!clusterName) return null;

        const stored = byName.get(clusterName) || {};
        byName.delete(clusterName);
        const available = mc.status?.conditions?.find(
          (c) => c.type === "ManagedClusterConditionAvailable"
        );
        const hubAccepted = mc.status?.conditions?.find(
          (c) => c.type === "HubAcceptedManagedCluster"
        );
        const latestSync = await lastSyncForCluster(clusterName, stored.latestSync || null);

        return {
          clusterName,
          snapshotCount: stored.snapshotCount || 0,
          latestSync,
          nextSync: computeNextSync(latestSync),
          resyncIntervalMinutes: RESYNC_INTERVAL_MINUTES,
          available: available?.status || "Unknown",
          hubAccepted: hubAccepted?.status || "Unknown",
          source: "managedcluster",
        };
      })
    );

    const result = tiles.filter(Boolean);

    // Include any DB-only clusters not present as ManagedClusters.
    for (const leftover of byName.values()) {
      result.push({
        clusterName: leftover.clusterName,
        snapshotCount: leftover.snapshotCount,
        latestSync: leftover.latestSync,
        nextSync: computeNextSync(leftover.latestSync),
        resyncIntervalMinutes: RESYNC_INTERVAL_MINUTES,
        available: "Unknown",
        hubAccepted: "Unknown",
        source: "database",
      });
    }

    result.sort((a, b) => a.clusterName.localeCompare(b.clusterName));
    return result;
  } catch (err) {
    return dbClusters.map((c) => ({
      clusterName: c.clusterName,
      snapshotCount: c.snapshotCount,
      latestSync: c.latestSync,
      nextSync: computeNextSync(c.latestSync),
      resyncIntervalMinutes: RESYNC_INTERVAL_MINUTES,
      available: "Unknown",
      hubAccepted: "Unknown",
      source: "database",
      warning: err.message || String(err),
    }));
  }
}

module.exports = {
  syncFromCluster,
  listClusterTiles,
  computeNextSync,
  RESYNC_INTERVAL_MINUTES,
};
