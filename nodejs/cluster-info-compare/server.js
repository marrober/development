const path = require("path");
const express = require("express");
const { listClusters, getComparison, dbPath, saveSnapshot } = require("./lib/db");
const { syncFromCluster } = require("./lib/sync");
const k8sConfig = require("./lib/k8s").config;

const app = express();
const PORT = Number(process.env.PORT) || 3950;
const POLL_INTERVAL_MS = Number(process.env.POLL_INTERVAL_MS || 0);
const publicDir = path.join(__dirname, "public");

app.use(express.json());
app.use(express.static(publicDir));

app.get("/api/health", (_req, res) => {
  res.json({ ok: true, database: dbPath, k8s: k8sConfig });
});

app.get("/api/clusters", (_req, res) => {
  res.json({ clusters: listClusters() });
});

app.get("/api/compare/:clusterName", (req, res) => {
  const data = getComparison(req.params.clusterName);
  res.json(data);
});

app.post("/api/sync", async (_req, res) => {
  try {
    const result = await syncFromCluster();
    res.json(result);
  } catch (err) {
    res.status(500).json({
      error: err.message || String(err),
    });
  }
});

app.post("/api/snapshots", (req, res) => {
  try {
    const outcome = saveSnapshot(req.body);
    res.json(outcome);
  } catch (err) {
    res.status(400).json({
      error: err.message || String(err),
    });
  }
});

let pollTimer = null;

function startPolling() {
  if (!POLL_INTERVAL_MS || POLL_INTERVAL_MS < 1000) {
    return;
  }

  pollTimer = setInterval(async () => {
    try {
      const result = await syncFromCluster();
      console.log(
        `[poll] scanned=${result.scanned} stored=${result.results.filter((r) => r.stored).length}`
      );
    } catch (err) {
      console.error("[poll] sync failed:", err.message || err);
    }
  }, POLL_INTERVAL_MS);
}

app.listen(PORT, () => {
  console.log(`cluster-info-compare listening on http://localhost:${PORT}`);
  console.log(`database: ${dbPath}`);
  console.log(`watching CRD ${k8sConfig.group}/${k8sConfig.version}/${k8sConfig.plural} in ${k8sConfig.watchNamespace}`);
  if (POLL_INTERVAL_MS >= 1000) {
    console.log(`polling every ${POLL_INTERVAL_MS}ms`);
  }
  startPolling();
});

process.on("SIGINT", () => {
  if (pollTimer) clearInterval(pollTimer);
  process.exit(0);
});
