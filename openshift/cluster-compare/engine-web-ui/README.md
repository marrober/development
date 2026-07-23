# cluster-info-compare

Node.js application that reads `ClusterCollector` custom resources from an OpenShift / OCM hub cluster, stores cluster version and operator snapshots in SQLite, and presents a comparison table with one column per snapshot `date`.

## Snapshot format

Snapshots use this flat JSON shape (from ClusterCollector `status` or posted directly):

```json
{
  "clusterName": "cluster1",
  "date": "2026-07-07T15:30:00Z",
  "clusterVersion": {
    "version": "4.16.12",
    "status": "Available",
    "message": ""
  },
  "clusterOperators": [
    {
      "name": "authentication",
      "version": "4.16.12",
      "available": "True",
      "progressing": "False",
      "degraded": "False",
      "status": "Available",
      "message": ""
    }
  ],
  "installedOperators": [
    {
      "namespace": "openshift-operators",
      "name": "advanced-cluster-management.v2.12.0",
      "version": "2.12.0",
      "phase": "Succeeded",
      "status": "Succeeded",
      "message": "all requirements found, attempting install"
    }
  ]
}
```

`date` is required and becomes the comparison column identifier (date and time of the snapshot). See `examples/cluster1-snapshot.json`.

### Post a snapshot manually

```bash
curl -X POST http://localhost:3950/api/snapshots \
  -H 'Content-Type: application/json' \
  -d @examples/cluster1-snapshot.json
```

## Data source

The app expects `ClusterCollector` CRs created by [cluster-compare-collector-addon](../collector-addon/). Each CR's `status` contains:

- `clusterVersion` — OpenShift cluster version (shown at the top of the table)
- `clusterOperators` — core OpenShift operators and versions
- `installedOperators` — OLM-installed operators (CSV)
- `date` — snapshot date and time used as the column identifier (ClusterCollector CRs fall back to `status.lastSync` when syncing)

On an OCM hub, ClusterCollector resources are typically stored in a namespace named after the spoke cluster.

## Quick start

```bash
cd development/openshift/cluster-compare/engine-web-ui
npm install
cp .env.example .env
# edit .env — set WATCH_NAMESPACE if needed
npm start
```

Open http://localhost:3950 and click **Sync from cluster**.

### One-off sync from the CLI

```bash
npm run sync
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3950` | HTTP port |
| `WATCH_NAMESPACE` | _(empty)_ | Limit sync to one namespace; empty lists all namespaces |
| `CRD_GROUP` | `open-cluster-management.io` | ClusterCollector API group |
| `CRD_VERSION` | `v1alpha1` | ClusterCollector API version |
| `CRD_PLURAL` | `clustercollectors` | ClusterCollector resource plural |
| `CLUSTER_NAME_FROM` | `metadata.namespace` | Field used as cluster name in the database |
| `POLL_INTERVAL_MS` | `0` | Background sync interval; `0` disables polling |
| `DATABASE_PATH` | `./data/cluster-info.db` | SQLite database location |

Kubernetes authentication uses in-cluster credentials when running inside a cluster, otherwise your default kubeconfig.

## Comparison view

- **Rows:** Cluster Version first, then cluster operators, then installed OLM operators
- **Columns:** One per stored snapshot, labelled by `date`
- **Highlights:** Cells are highlighted when the version changes from the previous column

## API

- `GET /api/clusters` — clusters with snapshot counts
- `GET /api/compare/:clusterName` — comparison table payload
- `POST /api/snapshots` — store a snapshot using the flat JSON format above
- `POST /api/sync` — fetch CRs from the cluster and store new snapshots
- `GET /api/health` — health and configuration
