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

function reportCollectedClusterInfo(snapshot, meta = {}) {
  const clusterVersion = snapshot.clusterVersion || {};
  const network = snapshot.network || {};
  const clusterOperators = snapshot.clusterOperators || [];
  const installedOperators = snapshot.installedOperators || [];
  const nodes = snapshot.nodes || [];

  console.log("[verbose] cluster information collected", {
    clusterName: snapshot.clusterName,
    date: snapshot.date,
    lastSync: meta.lastSync || snapshot.date,
    spokeURL: snapshot.spokeURL || "",
    available: meta.available,
    hubAccepted: meta.hubAccepted,
    stored: meta.stored,
    refreshed: meta.refreshed,
    reason: meta.reason,
    clusterVersion: clusterVersion.version || "",
    clusterVersionStatus: clusterVersion.status || "",
    clusterVersionMessage: clusterVersion.message || "",
    clusterOperators: clusterOperators.length,
    installedOperators: installedOperators.length,
    nodes: nodes.length,
    networkType: network.networkType || "",
    clusterNetwork: network.clusterNetwork || [],
    serviceNetwork: network.serviceNetwork || [],
  });

  for (const operator of clusterOperators) {
    console.log("[verbose] cluster operator", {
      clusterName: snapshot.clusterName,
      name: operator.name,
      version: operator.version,
      status: operator.status,
      available: operator.available,
      progressing: operator.progressing,
      degraded: operator.degraded,
      message: operator.message,
    });
  }

  for (const operator of installedOperators) {
    console.log("[verbose] installed operator", {
      clusterName: snapshot.clusterName,
      name: operator.name,
      displayName: operator.displayName,
      version: operator.version,
      phase: operator.phase,
      status: operator.status,
      namespaces: operator.namespaces,
      message: operator.message,
    });
  }

  for (const node of nodes) {
    console.log("[verbose] node", {
      clusterName: snapshot.clusterName,
      name: node.name,
      roles: node.roles,
      ready: node.ready,
      cpu: node.cpu,
      memory: node.memory,
      gpu: node.gpu,
      gpuResource: node.gpuResource,
    });
  }
}

/**
 * Discover ManagedClusters, then for each cluster namespace read the
 * ClusterCollector CR and import a snapshot when lastSync is new.
 *
 * @param {{ verbose?: boolean }} [options]
 */
async function syncFromCluster(options = {}) {
  const verbose = Boolean(options.verbose);
  const managedClusters = await listManagedClusters();
  const results = [];

  if (verbose) {
    console.log(
      `[verbose] syncing ${managedClusters.length} managed cluster(s)`
    );
  }

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
      const result = {
        clusterName,
        stored: false,
        reason: `failed to read ClusterCollector: ${err.message || err}`,
        available: available?.status,
        hubAccepted: hubAccepted?.status,
      };
      if (verbose) {
        console.log("[verbose] cluster sync skipped", result);
      }
      results.push(result);
      continue;
    }

    if (!cr) {
      const result = {
        clusterName,
        stored: false,
        reason: `no ClusterCollector/${k8sConfig.collectorName} in namespace ${clusterName}`,
        available: available?.status,
        hubAccepted: hubAccepted?.status,
      };
      if (verbose) {
        console.log("[verbose] cluster sync skipped", result);
      }
      results.push(result);
      continue;
    }

    const normalized = normalizeClusterCollector(cr);
    const lastSync = normalized.lastSync || normalized.snapshot.date;
    if (!lastSync) {
      const result = {
        clusterName,
        crName: normalized.crName,
        namespace: normalized.namespace,
        stored: false,
        reason: "ClusterCollector has no lastSync/date",
        available: available?.status,
        hubAccepted: hubAccepted?.status,
      };
      if (verbose) {
        console.log("[verbose] cluster sync skipped", result);
      }
      results.push(result);
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
    const result = {
      clusterName,
      crName: normalized.crName,
      namespace: normalized.namespace,
      lastSync,
      nextSync: computeNextSync(lastSync),
      available: available?.status,
      hubAccepted: hubAccepted?.status,
      ...outcome,
    };
    if (verbose) {
      reportCollectedClusterInfo(snapshot, result);
    }
    results.push(result);
  }

  if (verbose) {
    const stored = results.filter((r) => r.stored).length;
    const refreshed = results.filter((r) => r.refreshed).length;
    console.log("[verbose] sync complete", {
      scanned: managedClusters.length,
      stored,
      refreshed,
      skipped: results.length - stored - refreshed,
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
