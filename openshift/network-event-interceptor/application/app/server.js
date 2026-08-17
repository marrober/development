const express = require("express");
const { decodeAlertWebhook, getBriefAlertFields } = require("./lib/decode-alert");
const { parseCliArgs } = require("./lib/cli");

const { verbose: VERBOSE } = parseCliArgs();
const PORT = Number(process.env.PORT) || 8080;
const app = express();
const startTime = Date.now();
let webhookRequestCount = 0;
let decodedAlertCount = 0;
let lastDecodedAlert = null;

app.use(express.raw({ type: "*/*", limit: "10mb" }));

function parseBody(buffer) {
  if (!buffer || buffer.length === 0) {
    return { raw: "", parsed: null };
  }

  const raw = buffer.toString("utf8");
  try {
    return { raw, parsed: JSON.parse(raw) };
  } catch {
    return { raw, parsed: null };
  }
}

function logBriefAlert(decoded) {
  const fields = getBriefAlertFields(decoded);
  console.log(JSON.stringify(fields, null, 2));
}

function logWebhook(req, body, decoded) {
  if (!body.raw) {
    console.log("webhook: (empty body)");
    return;
  }

  if (VERBOSE) {
    if (body.parsed !== null) {
      console.log(JSON.stringify(body.parsed, null, 2));
    } else {
      console.log(body.raw);
    }
    return;
  }

  if (decoded?.ok) {
    logBriefAlert(decoded);
    return;
  }

  if (body.parsed !== null) {
    console.log(`webhook: unrecognized payload (${decoded?.error || "unknown format"})`);
    return;
  }

  console.log(`webhook: invalid JSON (${decoded?.error || "parse error"})`);
}

function handleWebhook(req, res) {
  webhookRequestCount += 1;
  const body = parseBody(req.body);
  const decoded = body.parsed ? decodeAlertWebhook(body.parsed) : { ok: false, error: "Invalid JSON" };

  if (decoded.ok) {
    decodedAlertCount += 1;
    lastDecodedAlert = {
      receivedAt: new Date().toISOString(),
      summary: decoded.summary,
      brief: getBriefAlertFields(decoded),
    };
  }

  logWebhook(req, body, decoded);

  res.status(200).json({
    received: true,
    decoded: decoded.ok ? decoded : undefined,
    decodeError: decoded.ok ? undefined : decoded.error,
  });
}

app.get("/health", (_req, res) => {
  res.json({ ok: true, port: PORT, verbose: VERBOSE });
});

app.get("/status", (_req, res) => {
  const uptimeSeconds = Math.floor(process.uptime());
  res.json({
    ok: true,
    port: PORT,
    verbose: VERBOSE,
    startedAt: new Date(startTime).toISOString(),
    uptimeSeconds,
    webhookRequestCount,
    decodedAlertCount,
    lastDecodedAlert,
  });
});

app.post("/webhook", handleWebhook);
app.post("*", handleWebhook);

app.listen(PORT, () => {
  console.log(`Webhook listener ready on port ${PORT} (verbose=${VERBOSE})`);
  console.log(`  POST /webhook  — primary webhook endpoint`);
  console.log(`  POST /*        — catch-all for alternate paths`);
  console.log(`  GET  /health   — health check`);
  console.log(`  GET  /status   — uptime and webhook request count`);
});
