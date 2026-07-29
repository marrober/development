# cluster-info-compare

Node.js application that discovers OCM **ManagedCluster** resources on an OpenShift hub, reads the `ClusterCollector` custom resource in each managed-cluster namespace, stores version/operator snapshots in **PostgreSQL** (SQLite locally by default), and presents a tile-based comparison UI.

## How sync works

1. List all `ManagedCluster` resources (`cluster.open-cluster-management.io/v1`).
2. For each managed cluster name `N`, look in namespace `N` for `ClusterCollector` named `clustercollector`.
3. Compare `status.lastSync` to snapshots already stored for that cluster.
4. When `lastSync` is new, import the CR status into the database indexed by **cluster name** and **date/time** (`lastSync`).

Polling runs automatically in-cluster every 60s (`POLL_INTERVAL_SECONDS`). Locally it is off unless you set that variable.

## Snapshot format

```json
{
  "clusterName": "cluster1",
  "date": "2026-07-07T15:30:00Z",
  "clusterVersion": { "version": "4.16.12", "status": "Available", "message": "" },
  "clusterOperators": [],
  "installedOperators": [],
  "nodes": [
    {
      "name": "worker-0",
      "roles": ["worker"],
      "ready": "True",
      "cpu": { "capacity": "8", "allocatable": "7500m", "allocated": "2", "available": "5500m" },
      "memory": { "capacity": "32Gi", "allocatable": "30Gi", "allocated": "8Gi", "available": "22Gi" },
      "gpu": { "capacity": "2", "allocatable": "2", "allocated": "1", "available": "1" },
      "gpuResource": "nvidia.com/gpu"
    }
  ],
  "network": {
    "networkType": "OVNKubernetes",
    "clusterNetwork": [{ "cidr": "10.128.0.0/14", "hostPrefix": 23 }],
    "serviceNetwork": ["172.30.0.0/16"]
  }
}
```

### Post a snapshot manually

```bash
curl -X POST http://localhost:3950/api/snapshots \
  -H 'Content-Type: application/json' \
  -d @examples/cluster1-snapshot.json
```

## Quick start (local)

```bash
cd engine-web-ui/app
npm install
npm start
# or with detailed sync logging:
npm start -- --verbose
```

Open http://localhost:3950. Without `PGHOST` / `DATABASE_TYPE=postgresql`, the app uses SQLite under `./data/`.

### One-off sync from the CLI

```bash
npm run sync
npm run sync -- --verbose
```
## OpenShift / ArgoCD database delivery

Application code lives under [`app/`](app/). Manifests under [`deploy/`](deploy/) are intended for ArgoCD:

| File | Purpose |
|------|---------|
| `postgrescluster.yaml` | Crunchy Data `PostgresCluster` CR (operator template on the cluster) |
| `db-configmap.yaml` | Non-secret PostgreSQL connection settings for the app |
| `namespace.yaml` | `cluster-compare` namespace |
| `argocd-application.yaml` | Example ArgoCD `Application` |

Install the **Crunchy Postgres for Kubernetes** operator from OperatorHub first, then sync the Application (update `repoURL` in `argocd-application.yaml`).

The operator creates a user Secret (`cluster-compare-pg-pguser-clustercompare`). Wire the app Deployment to:

- envFrom ConfigMap `cluster-compare-db-config`
- `PGPASSWORD` (or `DATABASE_URL`) from that Secret

Example env fragment:

```yaml
envFrom:
  - configMapRef:
      name: cluster-compare-db-config
env:
  - name: PGPASSWORD
    valueFrom:
      secretKeyRef:
        name: cluster-compare-pg-pguser-clustercompare
        key: password
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3950` | HTTP port |
| `DATABASE_TYPE` | _(sqlite unless PGHOST set)_ | Set to `postgresql` on OpenShift via ConfigMap |
| `PGHOST` / `PGPORT` / `PGDATABASE` / `PGUSER` / `PGPASSWORD` | — | PostgreSQL connection |
| `DATABASE_URL` | — | Optional full connection string |
| `POLL_INTERVAL_SECONDS` | `60` in-cluster, `0` local | Background sync interval (seconds) |
| `--verbose` / `VERBOSE` | off | Log collected cluster details (version, operators, nodes, network) on each sync |
| `COLLECTOR_NAME` | `clustercollector` | ClusterCollector CR name in each namespace |
| `CRD_GROUP` | `open-cluster-management.io` | ClusterCollector API group |
| `CRD_VERSION` | `v1alpha1` | ClusterCollector API version |
| `CRD_PLURAL` | `clustercollectors` | ClusterCollector plural |
| `MANAGEDCLUSTER_GROUP` | `cluster.open-cluster-management.io` | ManagedCluster API group |

Kubernetes authentication uses in-cluster credentials when running inside a cluster, otherwise your default kubeconfig.

## UI

- **Home:** one tile per managed cluster (availability + latest snapshot).
- **Cluster detail:** comparison table of stored snapshots (version changes highlighted).

## API

- `GET /api/clusters` — managed clusters with snapshot counts
- `GET /api/compare/:clusterName` — comparison table payload
- `POST /api/snapshots` — store a snapshot manually
- `POST /api/sync` — discover ManagedClusters and import updated collectors
- `GET /api/health` — health and configuration
