const express = require("express");

const PORT = Number(process.env.PORT) || 8080;
const app = express();

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

function logWebhook(req, body) {
  const timestamp = new Date().toISOString();
  const contentType = req.get("content-type") || "unknown";

  console.log(`[${timestamp}] Webhook received`);
  console.log(`  method: ${req.method}`);
  console.log(`  path: ${req.originalUrl}`);
  console.log(`  content-type: ${contentType}`);
  console.log(`  headers: ${JSON.stringify(req.headers, null, 2)}`);

  if (!body.raw) {
    console.log("  body: (empty)");
    return;
  }

  console.log(`  body (raw): ${body.raw}`);
  if (body.parsed !== null) {
    console.log(`  body (parsed): ${JSON.stringify(body.parsed, null, 2)}`);
  }
}

function handleWebhook(req, res) {
  const body = parseBody(req.body);
  logWebhook(req, body);
  res.status(200).json({ received: true });
}

app.get("/health", (_req, res) => {
  res.json({ ok: true, port: PORT });
});

app.post("/webhook", handleWebhook);
app.post("*", handleWebhook);

app.listen(PORT, () => {
  console.log(`Webhook listener ready on port ${PORT}`);
  console.log(`  POST /webhook  — primary webhook endpoint`);
  console.log(`  POST /*        — catch-all for alternate paths`);
  console.log(`  GET  /health   — health check`);
});
