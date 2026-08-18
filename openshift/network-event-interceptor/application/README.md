# Network Event Interceptor

Node.js application that receives RHACS (Red Hat Advanced Cluster Security) security alert webhooks, decodes alert payloads, stores recent events in memory, and presents them in a web dashboard.

The service listens on port **8080** by default and is designed to run on OpenShift as the `network-event-interceptor` deployment in the `network-event-interceptor` namespace.

## Features

- **Webhook receiver** — accepts POST requests on `/webhook` (and a catch-all POST path for alternate sender URLs)
- **RHACS alert decoding** — parses the `alert` object from webhook JSON, including policy, deployment, process violations, and violation key/value attributes
- **Web dashboard** — lists received alerts, shows detail panels, filters by text and severity, and links to RHACS policy pages when configured
- **In-memory event store** — retains up to 500 webhook events for the UI and API
- **Verbose logging** — optional full JSON payload logging via `--verbose`

## Project layout

```
application/
├── app/                 # Node.js application source
│   ├── server.js        # HTTP server and API routes
│   ├── lib/             # Decoding, storage, CLI parsing
│   ├── public/          # Web UI (HTML, CSS, JS)
│   └── fixtures/        # Sample webhook payload for local testing
├── deploy/              # OpenShift deployment, service, route manifests
└── ci/                  # Tekton pipeline definitions
```

## Local development

```bash
cd application/app
npm install
npm start
```

The server starts on `http://localhost:8080`.

### CLI options

| Option | Environment variable | Description |
|--------|----------------------|-------------|
| `--verbose` / `-v` | `VERBOSE=1`, `true`, `yes`, `on` | Log the full webhook JSON payload for each request |

Example:

```bash
node server.js --verbose
```

In Kubernetes/OpenShift, pass flags via container `args` (the image uses `ENTRYPOINT ["node", "server.js"]`):

```yaml
args:
  - "--verbose"
```

### Test a webhook locally

```bash
curl -X POST http://localhost:8080/webhook \
  -H "Content-Type: application/json" \
  --data-binary @fixtures/sample-alert.json
```

## Web UI

Open `GET /` in a browser.

| Feature | Description |
|---------|-------------|
| Event list | Cards showing policy name, severity, cluster, namespace, deployment, and alert time |
| Detail panel | Summary, violation message, policy/deployment info, processes (5 most recent), full payload with copy button |
| Settings | Configure RHACS **Cluster URL** for POLICY links (`{clusterURL}/main/policy-management/policies/{policy.id}`) |
| Filters | Text search and severity filter |
| Auto-refresh | Polls the API every 4 seconds |

Cluster URL is stored in browser `localStorage` and is not sent to the server.

## Webhook payload

The application expects RHACS generic webhook JSON with a top-level `alert` object (`v1.Alert`). Example structure:

```json
{
  "alert": {
    "id": "<alert-id>",
    "time": "<timestamp>",
    "firstOccurred": "<timestamp>",
    "clusterName": "<cluster>",
    "namespace": "<namespace>",
    "policy": {
      "id": "<policy-id>",
      "name": "<policy-name>",
      "severity": "HIGH_SEVERITY"
    },
    "deployment": {
      "name": "<deployment>",
      "namespace": "<namespace>",
      "type": "Deployment"
    },
    "processViolation": {
      "message": "<violation-message>",
      "processes": [ ... ]
    },
    "violations": [
      {
        "type": "GENERIC",
        "keyValueAttrs": {
          "attrs": [
            { "key": "<name>", "value": "<value>" }
          ]
        }
      }
    ]
  }
}
```

When `--verbose` is not set, the server logs only these brief fields for decoded alerts:

- `id`
- `policyName`
- `time`
- `deploymentName`
- `deploymentNamespace`
- `clusterName`

## API

All API responses are JSON unless noted. Event storage is in-memory only; events are lost on pod restart.

### `GET /health`

Liveness-style health check.

**Response `200`**

```json
{
  "ok": true,
  "port": 8080,
  "verbose": false
}
```

### `GET /status`

Runtime and webhook statistics.

**Response `200`**

```json
{
  "ok": true,
  "port": 8080,
  "verbose": false,
  "startedAt": "2026-08-18T12:00:00.000Z",
  "uptimeSeconds": 3600,
  "webhookRequestCount": 42,
  "decodedAlertCount": 40,
  "storedEventCount": 40,
  "decodedEventCount": 40,
  "lastDecodedAlert": {
    "receivedAt": "2026-08-18T12:30:00.000Z",
    "summary": { ... },
    "brief": { ... }
  }
}
```

### `GET /api/events`

List stored webhook events (summary fields for the dashboard).

**Response `200`**

```json
{
  "events": [
    {
      "eventId": "<uuid>",
      "receivedAt": "<iso-timestamp>",
      "path": "/webhook",
      "decoded": true,
      "brief": {
        "id": "<alert-id>",
        "policyName": "<name>",
        "policyId": "<policy-id>",
        "time": "<timestamp>",
        "deploymentName": "<name>",
        "deploymentNamespace": "<namespace>",
        "clusterName": "<cluster>"
      },
      "summary": {
        "policyName": "<name>",
        "policyId": "<policy-id>",
        "severity": "HIGH_SEVERITY",
        "clusterName": "<cluster>",
        "namespace": "<namespace>",
        "deploymentName": "<name>",
        "deploymentType": "Deployment",
        "processViolationMessage": "<message>",
        "processCount": 10,
        "binaries": ["/usr/bin/curl"],
        "alertTime": "<timestamp>",
        "firstOccurred": "<timestamp>"
      }
    }
  ],
  "storedEventCount": 1,
  "decodedEventCount": 1
}
```

### `GET /api/events/:eventId`

Full event record including decoded alert and original payload.

**Response `200`** — full event object with `decoded`, `payload`, `brief`, `summary`, etc.

**Response `404`**

```json
{
  "error": "Event not found"
}
```

### `DELETE /api/events`

Clear all stored events.

**Response `200`**

```json
{
  "cleared": true
}
```

### `POST /webhook`

Primary webhook endpoint. Any POST path not matched by other routes is also handled by the same logic (catch-all).

**Request**

- Method: `POST`
- Body: raw JSON (any `Content-Type`; body limit 10 MB)

**Response `200`**

```json
{
  "received": true,
  "eventId": "<uuid>",
  "decoded": {
    "ok": true,
    "alert": { ... },
    "summary": { ... }
  }
}
```

If the payload is not a valid RHACS alert:

```json
{
  "received": true,
  "eventId": "<uuid>",
  "decodeError": "Payload does not contain an alert object"
}
```

### `GET /`

Serves the web dashboard static files (`index.html`, `styles.css`, `app.js`).

## Deployment

Manifests are in `deploy/`:

| Resource | Purpose |
|----------|---------|
| `deployment.yaml` | Node.js container on port 8080 |
| `service.yaml` | Cluster service for the app |
| `route.yaml` | OpenShift route with edge TLS |

Configure RHACS to POST alerts to:

```
https://<route-host>/webhook
```

## Container image

Build from `app/Dockerfile` (or `app/dockerfile` for Tekton `build-node-js` task with `source-image` substitution):

```bash
cd application/app
docker build -f Dockerfile -t network-event-interceptor .
```

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | HTTP listen port |
