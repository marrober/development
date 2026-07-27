const k8s = require("@kubernetes/client-node");
const { normalizeClusterSnapshot } = require("./normalize");

const GROUP = process.env.CRD_GROUP || "open-cluster-management.io";
const VERSION = process.env.CRD_VERSION || "v1alpha1";
const PLURAL = process.env.CRD_PLURAL || "clustercollectors";
const COLLECTOR_NAME = process.env.COLLECTOR_NAME || "clustercollector";

const MC_GROUP = process.env.MANAGEDCLUSTER_GROUP || "cluster.open-cluster-management.io";
const MC_VERSION = process.env.MANAGEDCLUSTER_VERSION || "v1";
const MC_PLURAL = process.env.MANAGEDCLUSTER_PLURAL || "managedclusters";

function createKubeConfig() {
  const kc = new k8s.KubeConfig();
  if (process.env.KUBERNETES_SERVICE_HOST) {
    kc.loadFromCluster();
  } else {
    kc.loadFromDefault();
  }
  return kc;
}

function getCustomObjectsApi() {
  const kc = createKubeConfig();
  return kc.makeApiClient(k8s.CustomObjectsApi);
}

function isInCluster() {
  return Boolean(process.env.KUBERNETES_SERVICE_HOST);
}

/**
 * List all OCM ManagedCluster resources on the hub.
 */
async function listManagedClusters() {
  const api = getCustomObjectsApi();
  // ManagedCluster is cluster-scoped.
  const response = await api.listClusterCustomObject({
    group: MC_GROUP,
    version: MC_VERSION,
    plural: MC_PLURAL,
  });
  return response?.items || [];
}

/**
 * Get the ClusterCollector CR named COLLECTOR_NAME in the given namespace
 * (expected to match the managed cluster name).
 */
async function getClusterCollector(namespace, name = COLLECTOR_NAME) {
  const api = getCustomObjectsApi();
  try {
    const response = await api.getNamespacedCustomObject({
      group: GROUP,
      version: VERSION,
      namespace,
      plural: PLURAL,
      name,
    });
    return response;
  } catch (err) {
    const statusCode = err?.statusCode || err?.response?.statusCode || err?.code;
    if (statusCode === 404) {
      return null;
    }
    throw err;
  }
}

function normalizeClusterCollector(cr) {
  const snapshot = normalizeClusterSnapshot(cr);
  return {
    clusterName: snapshot.clusterName,
    crName: cr.metadata?.name || "",
    namespace: cr.metadata?.namespace || "",
    lastSync: cr.status?.lastSync || snapshot.date || "",
    snapshot,
  };
}

module.exports = {
  listManagedClusters,
  getClusterCollector,
  normalizeClusterCollector,
  isInCluster,
  config: {
    group: GROUP,
    version: VERSION,
    plural: PLURAL,
    collectorName: COLLECTOR_NAME,
    managedClusterGroup: MC_GROUP,
    managedClusterVersion: MC_VERSION,
    managedClusterPlural: MC_PLURAL,
  },
};
