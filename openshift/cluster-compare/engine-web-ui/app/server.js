const path = require("path");
const express = require("express");
const db = require("./lib/db");
const { syncFromCluster, listClusterTiles } = require("./lib/sync");
const k8sConfig = require("./lib/k8s").config;
const { isInCluster } = require("./lib/k8s");

const app = express();
const PORT = Number(process.env.PORT) || 3950;
// Default to 60s polling when running in-cluster; disable locally unless set.
const defaultPoll = isInCluster() ? 60000 : 0;
const POLL_INTERVAL_MS = Number(
  process.env.POLL_INTERVAL_MS !== undefined ? process.env.POLL_INTERVAL_MS : defaultPoll
);
const publicDir = path.join(__dirname, "public");

app.use(express.json({ limit: "10mb" }));
app.use(express.static(publicDir));

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    database: { type: db.dbType, info: db.dbInfo },
    k8s: k8sConfig,
    pollIntervalMs: POLL_INTERVAL_MS,
    inCluster: isInCluster(),
  });
});

app.get("/api/clusters", async (_req, res) => {
  try {
    const clusters = await listClusterTiles();
    res.json({ clusters });
  } catch (err) {
    res.status(500).json({ error: err.message || String(err) });
  }
});

app.get("/api/compare/:clusterName", async (req, res) => {
  try {
    const data = await db.getComparison(req.params.clusterName);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message || String(err) });
  }
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

app.post("/api/snapshots", async (req, res) => {
  try {
    const outcome = await db.saveSnapshot(req.body);
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

  const run = async () => {
    try {
      const result = await syncFromCluster();
      const stored = result.results.filter((r) => r.stored).length;
      const refreshed = result.results.filter((r) => r.refreshed).length;
      console.log(
        `[poll] managedClusters=${result.scanned} stored=${stored} refreshed=${refreshed}`
      );
    } catch (err) {
      console.error("[poll] sync failed:", err.message || err);
    }
  };

  // Initial sync shortly after startup, then on interval.
  setTimeout(run, 2000);
  pollTimer = setInterval(run, POLL_INTERVAL_MS);
}

async function main() {
  await db.initDb();

  app.listen(PORT, () => {
    console.log(`cluster-info-compare listening on http://localhost:${PORT}`);
    console.log(`database: ${db.dbType} (${db.dbInfo})`);
    console.log(
      `managed clusters: ${k8sConfig.managedClusterGroup}/${k8sConfig.managedClusterVersion}/${k8sConfig.managedClusterPlural}`
    );
    console.log(
      `collectors: ${k8sConfig.group}/${k8sConfig.version}/${k8sConfig.plural}/${k8sConfig.collectorName} in each managed-cluster namespace`
    );
    if (POLL_INTERVAL_MS >= 1000) {
      console.log(`polling every ${POLL_INTERVAL_MS}ms`);
    } else {
      console.log("polling disabled (set POLL_INTERVAL_MS to enable)");
    }
    startPolling();
  });
}

main().catch((err) => {
  console.error("failed to start:", err);
  process.exit(1);
});

async function shutdown() {
  if (pollTimer) clearInterval(pollTimer);
  await db.closeDb();
  process.exit(0);
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
