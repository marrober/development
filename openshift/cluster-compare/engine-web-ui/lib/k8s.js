const k8s = require("@kubernetes/client-node");
const { normalizeClusterSnapshot } = require("./normalize");

const GROUP = process.env.CRD_GROUP || "example.open-cluster-management.io";
const VERSION = process.env.CRD_VERSION || "v1alpha1";
const PLURAL = process.env.CRD_PLURAL || "clustercollectors";
const WATCH_NAMESPACE = process.env.WATCH_NAMESPACE || "";

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

async function listClusterCollectors() {
  const api = getCustomObjectsApi();
  const namespace = WATCH_NAMESPACE.trim();

  const response = namespace
    ? await api.listNamespacedCustomObject({
        group: GROUP,
        version: VERSION,
        namespace,
        plural: PLURAL,
      })
    : await api.listCustomObjectForAllNamespaces({
        group: GROUP,
        version: VERSION,
        plural: PLURAL,
      });

  return response?.items || [];
}

function normalizeClusterCollector(cr) {
  const snapshot = normalizeClusterSnapshot(cr);
  return {
    clusterName: snapshot.clusterName,
    crName: cr.metadata?.name || "",
    namespace: cr.metadata?.namespace || "",
    snapshot,
  };
}

module.exports = {
  listClusterCollectors,
  normalizeClusterCollector,
  config: {
    group: GROUP,
    version: VERSION,
    plural: PLURAL,
    watchNamespace: WATCH_NAMESPACE || "(all namespaces)",
  },
};
