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
 * { clusterName, date, spokeURL, clusterVersion, clusterOperators, installedOperators,
 *   nodes, network, hostingType, kubernetesVersion }
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
      nodes: normalizeNodes(status.nodes),
      network: status.network || {},
      hostingType: status.hostingType || input.hostingType || "",
      kubernetesVersion: status.kubernetesVersion || input.kubernetesVersion || "",
    };
  }

  return {
    clusterName: input.clusterName || "",
    date: snapshotDateFrom(input),
    spokeURL: input.spokeURL || "",
    clusterVersion: input.clusterVersion || {},
    clusterOperators: input.clusterOperators || [],
    installedOperators: input.installedOperators || [],
    nodes: normalizeNodes(input.nodes),
    network: input.network || {},
    hostingType: input.hostingType || "",
    kubernetesVersion: input.kubernetesVersion || "",
  };
}

/**
 * Normalize node roles: drop legacy "master" when "control-plane" is present,
 * and replace a sole "master" role with "control-plane".
 */
function normalizeNodeRoles(roles) {
  const list = Array.isArray(roles) ? roles.filter(Boolean) : [];
  const hasControlPlane = list.includes("control-plane");
  const hasMaster = list.includes("master");
  const normalized = list.filter((role) => role !== "master" && role !== "control-plane");
  if (hasControlPlane || hasMaster) {
    normalized.push("control-plane");
  }
  return [...new Set(normalized)].sort();
}

function normalizeNodes(nodes) {
  if (!Array.isArray(nodes)) return [];
  return nodes.map((node) => ({
    ...node,
    roles: normalizeNodeRoles(node?.roles),
  }));
}

module.exports = {
  normalizeClusterSnapshot,
  normalizeNodeRoles,
  clusterNameFromCr,
  snapshotDateFrom,
};
