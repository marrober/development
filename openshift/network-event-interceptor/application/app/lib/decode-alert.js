function asArray(value) {
  return Array.isArray(value) ? value : [];
}

function decodeProcess(process) {
  const signal = process?.signal || {};

  return {
    id: process?.id,
    podId: process?.podId,
    podUid: process?.podUid,
    containerName: process?.containerName,
    namespace: process?.namespace,
    containerStartTime: process?.containerStartTime,
    imageId: process?.imageId,
    signal: {
      id: signal.id,
      time: signal.time,
      name: signal.name,
      execFilePath: signal.execFilePath,
      args: signal.args,
      pid: signal.pid,
      uid: signal.uid,
      containerId: signal.containerId,
      lineageInfo: asArray(signal.lineageInfo),
    },
  };
}

function decodeDeployment(deployment) {
  if (!deployment) {
    return null;
  }

  const images = asArray(deployment.containers)
    .map((container) => container?.image?.name?.fullName)
    .filter(Boolean);

  return {
    id: deployment.id,
    name: deployment.name,
    type: deployment.type,
    namespace: deployment.namespace,
    namespaceId: deployment.namespaceId,
    clusterId: deployment.clusterId,
    clusterName: deployment.clusterName,
    labels: deployment.labels || {},
    images,
    containers: asArray(deployment.containers).map((container) => ({
      name: container?.name,
      image: container?.image?.name?.fullName,
      imageId: container?.image?.id,
    })),
  };
}

function decodePolicy(policy) {
  if (!policy) {
    return null;
  }

  return {
    id: policy.id,
    name: policy.name,
    description: policy.description,
    rationale: policy.rationale,
    remediation: policy.remediation,
    severity: policy.severity,
    categories: asArray(policy.categories),
    lifecycleStages: asArray(policy.lifecycleStages),
    eventSource: policy.eventSource,
    policyVersion: policy.policyVersion,
    lastUpdated: policy.lastUpdated,
  };
}

function decodeProcessViolation(processViolation) {
  if (!processViolation) {
    return null;
  }

  const processes = asArray(processViolation.processes).map(decodeProcess);
  const binaries = [...new Set(
    processes
      .map((process) => process.signal.execFilePath)
      .filter(Boolean),
  )];

  return {
    message: processViolation.message,
    processCount: processes.length,
    binaries,
    processes,
  };
}

function summarizeKeyValueAttrs(keyValueAttrs) {
  return asArray(keyValueAttrs?.attrs)
    .map((attr) => ({
      key: attr?.key,
      value: attr?.value,
    }))
    .filter((attr) => attr.key);
}

function extractViolationDetails(alert) {
  const violations = asArray(alert?.violations);
  const attributes = [];

  for (const violation of violations) {
    const keyValuePairs = summarizeKeyValueAttrs(violation?.keyValueAttrs);
    for (const pair of keyValuePairs) {
      attributes.push({
        key: pair.key,
        value: pair.value,
        violationType: violation?.type,
      });
    }
  }

  if (attributes.length === 0) {
    return null;
  }

  return {
    violationCount: violations.length,
    attributes,
  };
}

function decodeAlertWebhook(payload) {
  if (!payload || typeof payload !== "object") {
    return { ok: false, error: "Payload is not a JSON object" };
  }

  const alert = payload.alert;
  if (!alert || typeof alert !== "object") {
    return { ok: false, error: "Payload does not contain an alert object" };
  }

  const policy = decodePolicy(alert.policy);
  const deployment = decodeDeployment(alert.deployment);
  const processViolation = decodeProcessViolation(alert.processViolation);
  const violationDetails = extractViolationDetails(alert);

  return {
    ok: true,
    alert: {
      id: alert.id,
      time: alert.time,
      firstOccurred: alert.firstOccurred,
      entityType: alert.entityType,
      lifecycleStage: alert.lifecycleStage,
      clusterId: alert.clusterId,
      clusterName: alert.clusterName,
      namespace: alert.namespace,
      namespaceId: alert.namespaceId,
      policy,
      deployment,
      processViolation,
      violationDetails,
    },
    summary: {
      policyName: policy?.name,
      policyId: policy?.id,
      severity: policy?.severity,
      clusterName: alert.clusterName,
      namespace: alert.namespace,
      deploymentName: deployment?.name,
      deploymentType: deployment?.type,
      processViolationMessage: processViolation?.message,
      processCount: processViolation?.processCount || 0,
      binaries: processViolation?.binaries || [],
      alertTime: alert.time,
      firstOccurred: alert.firstOccurred,
    },
  };
}

function getBriefAlertFields(decoded) {
  const alert = decoded?.alert;
  if (!alert) {
    return null;
  }

  return {
    id: alert.id,
    policyName: alert.policy?.name,
    policyId: alert.policy?.id,
    time: alert.time,
    deploymentName: alert.deployment?.name,
    deploymentNamespace: alert.deployment?.namespace,
    clusterName: alert.clusterName,
  };
}

module.exports = {
  decodeAlertWebhook,
  getBriefAlertFields,
};
