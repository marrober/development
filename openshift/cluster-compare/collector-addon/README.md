# cluster-compare-collector-addon

OCM addon that collects OpenShift cluster version, cluster operator, and OLM operator snapshots from managed clusters and syncs them to the hub as `ClusterCollector` custom resources. The [cluster-compare engine web UI](../engine-web-ui/) reads those hub CRs to build comparison tables.

## Install the addon on the hub cluster

Switch context to the hub cluster.

```
make deploy
```

Check the addon manager status:

```
$ kubectl -n open-cluster-management get deploy cluster-compare-collector-addon-manager
NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
cluster-compare-collector-addon-manager   1/1     1            1           2m17s

kubectl -n cluster1 get managedclusteraddon cluster-compare-collector-addon
NAME                                AVAILABLE   DEGRADED   PROGRESSING
cluster-compare-collector-addon     True
```

## Verify the agent on the managed cluster and create a ClusterCollector CR

Switch context to the managed cluster.

```
$ kubectl -n open-cluster-management-agent-addon get deploy cluster-compare-collector-addon-agent
NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
cluster-compare-collector-addon-agent   1/1     1            1           4m23s
```

```
make deploy-clustercollector-cr-sample
```

The agent collects cluster snapshots on reconcile and every 60 minutes by default.

## Verify the ClusterCollector CR on the hub cluster

Switch context to the hub cluster.

```
$ kubectl -n cluster1 get clustercollector
NAME               AGE
clustercollector   5m35s

$ kubectl -n cluster1 get clustercollector clustercollector -o yaml
apiVersion: open-cluster-management.io/v1alpha1
kind: ClusterCollector
metadata:
  name: clustercollector
  namespace: cluster1
status:
  date: "2026-07-07T15:30:00Z"
  lastSync: "2026-07-07T15:30:00Z"
  clusterVersion:
    version: "4.16.12"
    status: Available
  clusterOperators:
    - name: authentication
      version: "4.16.12"
      status: Available
  installedOperators:
    - namespace: openshift-operators
      name: advanced-cluster-management.v2.12.0
      version: "2.12.0"
      phase: Succeeded
```

## Snapshot format

Each synced `ClusterCollector` status matches the snapshot shape consumed by the engine web UI:

- `clusterVersion` — OpenShift cluster version
- `clusterOperators` — core OpenShift operators and versions
- `installedOperators` — OLM-installed operators (CSV)
- `date` / `lastSync` — snapshot timestamp used as the comparison column identifier

See [engine-web-ui/examples/cluster1-snapshot.json](../engine-web-ui/examples/cluster1-snapshot.json) for a full example.

## Configuration

| Flag / env | Default | Description |
|------------|---------|-------------|
| `--resync-interval` | `60` | How often the agent re-collects and syncs snapshots, in minutes |
| `--verbose` | `false` | Print the full cluster snapshot payload that will be sent to the hub cluster |
| `ADDON_IMAGE` | `quay.io/open-cluster-management/addon-contrib/cluster-compare-collector-addon:latest` | Agent image override for the manager |
