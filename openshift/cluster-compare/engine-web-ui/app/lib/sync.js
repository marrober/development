const { saveSnapshot, hasSnapshot, listClusters } = require("./db");
const {
  listManagedClusters,
  getClusterCollector,
  normalizeClusterCollector,
  config: k8sConfig,
} = require("./k8s");

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

    if (await hasSnapshot(clusterName, lastSync)) {
      results.push({
        clusterName,
        crName: normalized.crName,
        namespace: normalized.namespace,
        lastSync,
        stored: false,
        reason: "unchanged",
        available: available?.status,
        hubAccepted: hubAccepted?.status,
      });
      continue;
    }

    // Ensure snapshot is indexed by managed cluster name and lastSync timestamp.
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
      available: available?.status,
      hubAccepted: hubAccepted?.status,
      ...outcome,
    });
  }

  return {
    scanned: managedClusters.length,
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
    const tiles = [];

    for (const mc of managedClusters) {
      const clusterName = mc.metadata?.name;
      if (!clusterName) continue;

      const stored = byName.get(clusterName) || {};
      const available = mc.status?.conditions?.find(
        (c) => c.type === "ManagedClusterConditionAvailable"
      );
      const hubAccepted = mc.status?.conditions?.find(
        (c) => c.type === "HubAcceptedManagedCluster"
      );

      tiles.push({
        clusterName,
        snapshotCount: stored.snapshotCount || 0,
        latestSync: stored.latestSync || null,
        available: available?.status || "Unknown",
        hubAccepted: hubAccepted?.status || "Unknown",
        source: "managedcluster",
      });
      byName.delete(clusterName);
    }

    // Include any DB-only clusters not present as ManagedClusters.
    for (const leftover of byName.values()) {
      tiles.push({
        clusterName: leftover.clusterName,
        snapshotCount: leftover.snapshotCount,
        latestSync: leftover.latestSync,
        available: "Unknown",
        hubAccepted: "Unknown",
        source: "database",
      });
    }

    tiles.sort((a, b) => a.clusterName.localeCompare(b.clusterName));
    return tiles;
  } catch (err) {
    return dbClusters.map((c) => ({
      clusterName: c.clusterName,
      snapshotCount: c.snapshotCount,
      latestSync: c.latestSync,
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
};
