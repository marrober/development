/**
 * Helpers for OCM ManagedCluster status.clusterClaims.
 */

function claimsMap(claims) {
  const map = Object.create(null);
  for (const claim of claims || []) {
    const name = claim?.name;
    if (!name) continue;
    map[name] = claim.value;
  }
  return map;
}

/**
 * hostedcluster.hypershift.openshift.io=true → Hosted control plane.
 * Missing or any other value → Self-managed control plane.
 */
function hostingTypeFromClaims(claims) {
  const value = claimsMap(claims)["hostedcluster.hypershift.openshift.io"];
  if (String(value || "").toLowerCase() === "true") {
    return "Hosted control plane";
  }
  return "Self-managed control plane";
}

function kubernetesVersionFromClaims(claims) {
  const value = claimsMap(claims)["kubeversion.open-cluster-management.io"];
  return value == null ? "" : String(value);
}

function platformInfoFromManagedCluster(managedCluster) {
  const claims = managedCluster?.status?.clusterClaims || [];
  return {
    hostingType: hostingTypeFromClaims(claims),
    kubernetesVersion: kubernetesVersionFromClaims(claims),
  };
}

module.exports = {
  claimsMap,
  hostingTypeFromClaims,
  kubernetesVersionFromClaims,
  platformInfoFromManagedCluster,
};
