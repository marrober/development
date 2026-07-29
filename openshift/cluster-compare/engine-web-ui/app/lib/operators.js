/**
 * Strip trailing OLM CSV version suffix (.v1.2.3 / .v1.2.3-xyz) from a name.
 */
function operatorPackageName(name) {
  const raw = String(name || "").trim();
  if (!raw) return "";
  const match = raw.match(/^(.*)\.v\d+(?:[.\-][\w+]+)*$/i);
  return match ? match[1] : raw;
}

function humanizeOperatorName(name) {
  const pkg = operatorPackageName(name);
  if (!pkg) return "unknown";
  return pkg
    .split(/[-_.]+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

/**
 * Prefer CSV displayName when present; otherwise humanize the package name.
 */
function operatorDisplayName(operator) {
  if (!operator || typeof operator !== "object") return "unknown";
  const displayName = String(operator.displayName || "").trim();
  if (displayName) return displayName;
  return humanizeOperatorName(operator.name || "");
}

function operatorRowKey(operator) {
  const pkg = operatorPackageName(operator?.name || "");
  return `installed-operator:${pkg || "unknown"}`;
}

function shouldShowStatus(status) {
  const value = String(status || "").trim().toLowerCase();
  if (!value) return false;
  return value !== "succeeded" && value !== "available";
}

module.exports = {
  operatorPackageName,
  humanizeOperatorName,
  operatorDisplayName,
  operatorRowKey,
  shouldShowStatus,
};
