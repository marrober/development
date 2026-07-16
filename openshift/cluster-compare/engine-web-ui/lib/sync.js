const { saveSnapshot } = require("./db");
const { listClusterCollectors, normalizeClusterCollector } = require("./k8s");

async function syncFromCluster() {
  const resources = await listClusterCollectors();
  const results = [];

  for (const cr of resources) {
    const normalized = normalizeClusterCollector(cr);
    const outcome = saveSnapshot(normalized.snapshot);
    results.push({
      clusterName: normalized.clusterName,
      crName: normalized.crName,
      namespace: normalized.namespace,
      lastSync: normalized.snapshot.date,
      ...outcome,
    });
  }

  return {
    scanned: resources.length,
    results,
  };
}

module.exports = {
  syncFromCluster,
};
