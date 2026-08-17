/**
 * Parse CLI flags from process.argv.
 * Supports: --verbose / -v
 * Env fallback: VERBOSE=1|true|yes
 */
function parseCliArgs(argv = process.argv.slice(2)) {
  const flags = new Set();
  for (const arg of argv) {
    if (!arg.startsWith("-")) continue;
    if (arg === "--") break;
    if (arg.startsWith("--")) {
      flags.add(arg.slice(2).toLowerCase());
    } else {
      for (const ch of arg.slice(1)) {
        flags.add(ch);
      }
    }
  }

  const envVerbose = String(process.env.VERBOSE || "")
    .trim()
    .toLowerCase();
  const verbose =
    flags.has("verbose") ||
    flags.has("v") ||
    ["1", "true", "yes", "on"].includes(envVerbose);

  return { verbose };
}

module.exports = { parseCliArgs };
