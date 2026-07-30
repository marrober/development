/**
 * Parse Kubernetes resource quantities into a comparable number.
 * CPU → millicores; memory → bytes; dimensionless (GPU) → milli-units (×1000).
 */
function parseQuantity(value) {
  if (value === null || value === undefined || value === "") return 0;
  const raw = String(value).trim();
  if (!raw) return 0;

  const match = raw.match(/^([+-]?[0-9]*\.?[0-9]+)([a-zA-Z]+)?$/);
  if (!match) {
    const asNumber = Number(raw);
    return Number.isFinite(asNumber) ? asNumber * 1000 : 0;
  }

  const amount = Number(match[1]);
  if (!Number.isFinite(amount)) return 0;
  const suffix = match[2] || "";

  switch (suffix) {
    case "n":
      return amount / 1e6;
    case "u":
      return amount / 1e3;
    case "m":
      return amount;
    case "k":
    case "K":
      return amount * 1e3 * 1000;
    case "M":
      return amount * 1e6 * 1000;
    case "G":
      return amount * 1e9 * 1000;
    case "T":
      return amount * 1e12 * 1000;
    case "Ki":
      return amount * 1024;
    case "Mi":
      return amount * 1024 ** 2;
    case "Gi":
      return amount * 1024 ** 3;
    case "Ti":
      return amount * 1024 ** 4;
    case "":
      // Bare numbers are treated as whole CPU cores / GPU counts → millounits.
      return amount * 1000;
    default:
      return amount * 1000;
  }
}

function formatCpu(milli) {
  if (!milli) return "0";
  if (Math.abs(milli) >= 1000 && milli % 1000 === 0) {
    return String(milli / 1000);
  }
  if (Math.abs(milli) >= 1000) {
    const cores = milli / 1000;
    return Number.isInteger(cores) ? String(cores) : cores.toFixed(2).replace(/\.?0+$/, "");
  }
  return `${Math.round(milli)}m`;
}

function formatMemory(bytes) {
  if (!bytes) return "0";
  const units = [
    ["Ti", 1024 ** 4],
    ["Gi", 1024 ** 3],
    ["Mi", 1024 ** 2],
    ["Ki", 1024],
  ];
  for (const [suffix, size] of units) {
    if (Math.abs(bytes) >= size) {
      const value = bytes / size;
      if (Number.isInteger(value)) return `${value}${suffix}`;
      return `${value.toFixed(2).replace(/\.?0+$/, "")}${suffix}`;
    }
  }
  return String(Math.round(bytes));
}

function formatGpu(milli) {
  if (!milli) return "0";
  if (milli % 1000 === 0) return String(milli / 1000);
  return (milli / 1000).toFixed(2).replace(/\.?0+$/, "");
}

function formatResource(kind, milliOrBytes) {
  if (kind === "cpu") return formatCpu(milliOrBytes);
  if (kind === "memory") return formatMemory(milliOrBytes);
  return formatGpu(milliOrBytes);
}

function nodeTypeKey(node) {
  const roles = normalizeNodeRoles([...(node.roles || [])]);
  return roles.length ? roles.join(",") : "unknown";
}

/**
 * Normalize node roles: drop legacy "master" when "control-plane" is present,
 * and replace a sole "master" role with "control-plane".
 */
function normalizeNodeRoles(roles) {
  const list = (roles || []).filter(Boolean);
  const hasControlPlane = list.includes("control-plane");
  const hasMaster = list.includes("master");
  const normalized = list.filter((role) => role !== "master" && role !== "control-plane");
  if (hasControlPlane || hasMaster) {
    normalized.push("control-plane");
  }
  return [...new Set(normalized)].sort();
}

function nodeTypeLabel(typeKey) {
  if (!typeKey || typeKey === "unknown") return "unknown role";
  return typeKey.split(",").join(" + ");
}

function emptyResourceTotals() {
  return { capacity: 0, allocatable: 0, allocated: 0, available: 0 };
}

function addResourceTotals(target, resource) {
  const src = resource || {};
  target.capacity += parseQuantity(src.capacity);
  target.allocatable += parseQuantity(src.allocatable);
  target.allocated += parseQuantity(src.allocated);
  target.available += parseQuantity(src.available);
}

/**
 * Aggregate nodes by role type (ignoring node names).
 * Returns Map typeKey → { count, cpu, memory, gpu, gpuResource }
 */
function aggregateNodesByType(nodes) {
  const byType = new Map();

  for (const node of nodes || []) {
    const typeKey = nodeTypeKey(node);
    let group = byType.get(typeKey);
    if (!group) {
      group = {
        typeKey,
        count: 0,
        cpu: emptyResourceTotals(),
        memory: emptyResourceTotals(),
        gpu: emptyResourceTotals(),
        gpuResource: "",
      };
      byType.set(typeKey, group);
    }
    group.count += 1;
    addResourceTotals(group.cpu, node.cpu);
    addResourceTotals(group.memory, node.memory);
    addResourceTotals(group.gpu, node.gpu);
    if (!group.gpuResource && node.gpuResource) {
      group.gpuResource = node.gpuResource;
    }
  }

  return byType;
}

function resourceLabel(resourceName) {
  if (resourceName === "cpu") return "CPU";
  if (resourceName === "memory") return "Memory";
  if (resourceName === "gpu") return "GPU";
  return resourceName;
}

function pushNodeResourceRows(entries, group, resourceName, totals, nextOrder) {
  const label = nodeTypeLabel(group.typeKey);
  const hasCapacity =
    totals.capacity > 0 || totals.allocatable > 0 || totals.allocated > 0;
  if (!hasCapacity && resourceName === "gpu") {
    return nextOrder;
  }

  for (const metric of ["allocatable", "allocated"]) {
    entries.push({
      rowKey: `nodes:type:${group.typeKey}:${resourceName}:${metric}`,
      rowLabel: `${label} · ${resourceLabel(resourceName)} ${metric}`,
      sortOrder: nextOrder++,
      version: formatResource(resourceName, totals[metric]),
      status: "",
      details: JSON.stringify({
        kind: "node-resource",
        nodeType: group.typeKey,
        resource: resourceName,
        metric,
        capacity: formatResource(resourceName, totals.capacity),
        allocatable: formatResource(resourceName, totals.allocatable),
        allocated: formatResource(resourceName, totals.allocated),
        available: formatResource(resourceName, totals.available),
        gpuResource: group.gpuResource || "",
        nodeCount: group.count,
      }),
    });
  }
  return nextOrder;
}

function buildNodeEntries(nodes) {
  const entries = [];
  const list = Array.isArray(nodes) ? nodes : [];
  const byType = aggregateNodesByType(list);

  // Keep node rows ordered: total → per-type count → allocatable/allocated metrics.
  let order = 300;

  entries.push({
    rowKey: "nodes:total",
    rowLabel: "Total nodes",
    sortOrder: order++,
    version: String(list.length),
    status: "",
    details: JSON.stringify({
      kind: "node-total",
      nodeCount: list.length,
      types: [...byType.keys()].sort(),
    }),
  });

  const types = [...byType.values()].sort((a, b) => a.typeKey.localeCompare(b.typeKey));
  for (const group of types) {
    const label = nodeTypeLabel(group.typeKey);
    entries.push({
      rowKey: `nodes:type:${group.typeKey}:count`,
      rowLabel: `${label} nodes`,
      sortOrder: order++,
      version: String(group.count),
      status: "",
      details: JSON.stringify({
        kind: "node-type-count",
        nodeType: group.typeKey,
        nodeCount: group.count,
        cpu: {
          allocatable: formatCpu(group.cpu.allocatable),
          allocated: formatCpu(group.cpu.allocated),
        },
        memory: {
          allocatable: formatMemory(group.memory.allocatable),
          allocated: formatMemory(group.memory.allocated),
        },
        gpu: {
          allocatable: formatGpu(group.gpu.allocatable),
          allocated: formatGpu(group.gpu.allocated),
          resource: group.gpuResource || "",
        },
      }),
    });

    order = pushNodeResourceRows(entries, group, "cpu", group.cpu, order);
    order = pushNodeResourceRows(entries, group, "memory", group.memory, order);
    order = pushNodeResourceRows(entries, group, "gpu", group.gpu, order);
  }

  return entries;
}

function formatClusterNetwork(entries) {
  if (!Array.isArray(entries) || entries.length === 0) return "";
  return entries
    .map((entry) => {
      const cidr = entry.cidr || entry.CIDR || "";
      const prefix = entry.hostPrefix ?? entry.host_prefix;
      if (prefix === undefined || prefix === null || prefix === "") return cidr;
      return `${cidr} (hostPrefix ${prefix})`;
    })
    .filter(Boolean)
    .join(", ");
}

function buildNetworkEntries(network) {
  const net = network || {};
  const clusterNetwork = formatClusterNetwork(net.clusterNetwork || []);
  const serviceNetwork = Array.isArray(net.serviceNetwork)
    ? net.serviceNetwork.filter(Boolean).join(", ")
    : net.serviceNetwork || "";

  return [
    {
      rowKey: "network:type",
      rowLabel: "Network type",
      sortOrder: 400,
      version: net.networkType || "",
      status: "",
      details: JSON.stringify({ kind: "network-type", networkType: net.networkType || "" }),
    },
    {
      rowKey: "network:cluster",
      rowLabel: "Cluster network",
      sortOrder: 401,
      version: clusterNetwork,
      status: "",
      details: JSON.stringify({
        kind: "network-cluster",
        clusterNetwork: net.clusterNetwork || [],
      }),
    },
    {
      rowKey: "network:service",
      rowLabel: "Service network",
      sortOrder: 402,
      version: serviceNetwork,
      status: "",
      details: JSON.stringify({
        kind: "network-service",
        serviceNetwork: net.serviceNetwork || [],
      }),
    },
  ];
}

module.exports = {
  parseQuantity,
  formatCpu,
  formatMemory,
  formatGpu,
  formatResource,
  nodeTypeKey,
  nodeTypeLabel,
  aggregateNodesByType,
  buildNodeEntries,
  buildNetworkEntries,
};
