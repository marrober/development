function clusterNameFromCr(cr) {
  if (process.env.CLUSTER_NAME_FROM === "metadata.name") {
    return cr.metadata?.name || "unknown";
  }
  return cr.metadata?.namespace || cr.metadata?.name || "unknown";
}

function snapshotDateFrom(input) {
  if (!input || typeof input !== "object") return "";

  return (
    input.date ||
    input.lastSync ||
    input.collectedAt ||
    input.status?.date ||
    input.status?.lastSync ||
    ""
  );
}

/**
 * Normalize ClusterCollector CRs and flat JSON payloads into a single snapshot shape:
 * { clusterName, date, spokeURL, clusterVersion, clusterOperators, installedOperators }
 */
function normalizeClusterSnapshot(input) {
  if (!input || typeof input !== "object") {
    throw new Error("snapshot payload must be an object");
  }

  if (input.metadata && !input.clusterName) {
    const status = input.status || {};
    return {
      clusterName: status.clusterName || clusterNameFromCr(input),
      date: snapshotDateFrom({ status, ...input }),
      spokeURL: status.spokeURL || "",
      clusterVersion: status.clusterVersion || {},
      clusterOperators: status.clusterOperators || [],
      installedOperators: status.installedOperators || [],
    };
  }

  return {
    clusterName: input.clusterName || "",
    date: snapshotDateFrom(input),
    spokeURL: input.spokeURL || "",
    clusterVersion: input.clusterVersion || {},
    clusterOperators: input.clusterOperators || [],
    installedOperators: input.installedOperators || [],
  };
}

module.exports = {
  normalizeClusterSnapshot,
  clusterNameFromCr,
  snapshotDateFrom,
};
