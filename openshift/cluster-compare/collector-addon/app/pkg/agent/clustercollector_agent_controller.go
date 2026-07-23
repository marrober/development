package agent

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/go-logr/logr"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/util/retry"
	ocmv1alpha1 "open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/api/v1alpha1"
	"open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/pkg/collector"
	"open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/pkg/constants"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/predicate"
)

const spokeCollectorName = "clustercollector"

type ClusterCollectorController struct {
	spokeClient client.Client
	hubClient   client.Client
	collector   *collector.Collector
	log         logr.Logger
	clusterName string
	resyncAfter time.Duration
	verbose     bool
	reportJSON  bool
}

func (c *ClusterCollectorController) SetupWithManager(mgr ctrl.Manager) error {
	// Only reconcile the spoke collector CR in the addon namespace. Watching every
	// ClusterCollector (e.g. copies under managed-cluster namespaces) causes
	// overlapping status updates and resourceVersion conflicts.
	nsPredicate := predicate.NewPredicateFuncs(func(obj client.Object) bool {
		return obj.GetNamespace() == constants.AgentInstallationNamespace &&
			obj.GetName() == spokeCollectorName
	})

	return ctrl.NewControllerManagedBy(mgr).
		For(&ocmv1alpha1.ClusterCollector{}).
		WithEventFilter(nsPredicate).
		Complete(c)
}

// EnsureSpokeCollector creates the spoke ClusterCollector CR if it does not exist.
// Without this CR the controller never reconciles, so nothing is collected or synced.
func (c *ClusterCollectorController) EnsureSpokeCollector(ctx context.Context) error {
	existing := &ocmv1alpha1.ClusterCollector{}
	key := types.NamespacedName{
		Namespace: constants.AgentInstallationNamespace,
		Name:      spokeCollectorName,
	}
	err := c.spokeClient.Get(ctx, key, existing)
	switch {
	case err == nil:
		c.vInfo("spoke ClusterCollector already exists", "namespace", key.Namespace, "name", key.Name)
		return nil
	case !errors.IsNotFound(err):
		return fmt.Errorf("get spoke ClusterCollector: %w", err)
	}

	cr := &ocmv1alpha1.ClusterCollector{
		ObjectMeta: metav1.ObjectMeta{
			Name:      spokeCollectorName,
			Namespace: constants.AgentInstallationNamespace,
		},
	}
	if err := c.spokeClient.Create(ctx, cr); err != nil {
		return fmt.Errorf("create spoke ClusterCollector: %w", err)
	}
	c.vInfo("created spoke ClusterCollector", "namespace", key.Namespace, "name", key.Name)
	return nil
}

func (c *ClusterCollectorController) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	c.vInfo("reconciling ClusterCollector", "namespacedName", req.String())
	defer c.vInfo("done reconcile", "namespacedName", req.String())

	if req.Namespace != constants.AgentInstallationNamespace || req.Name != spokeCollectorName {
		c.vInfo("ignoring ClusterCollector outside addon namespace", "namespacedName", req.String())
		return ctrl.Result{}, nil
	}

	collectedStatus, err := c.collector.Collect(ctx)
	if err != nil {
		c.log.Error(err, "failed to collect cluster snapshot")
		return ctrl.Result{}, err
	}

	c.vInfo("collected cluster snapshot",
		"clusterName", collectedStatus.ClusterName,
		"date", collectedStatus.Date,
		"clusterVersion", collectedStatus.ClusterVersion.Version,
		"clusterVersionStatus", collectedStatus.ClusterVersion.Status,
		"clusterOperators", len(collectedStatus.ClusterOperators),
		"installedOperators", len(collectedStatus.InstalledOperators),
	)
	if c.verbose {
		for _, operator := range collectedStatus.ClusterOperators {
			c.log.Info("cluster operator",
				"name", operator.Name,
				"version", operator.Version,
				"status", operator.Status,
				"available", operator.Available,
				"progressing", operator.Progressing,
				"degraded", operator.Degraded,
			)
		}
		for _, operator := range collectedStatus.InstalledOperators {
			c.log.Info("installed operator",
				"name", operator.Name,
				"version", operator.Version,
				"phase", operator.Phase,
				"status", operator.Status,
				"namespaces", operator.Namespaces,
			)
		}
	}
	if c.reportJSON {
		c.reportSnapshot("collected snapshot (pre-hub-sync)", collectedStatus)
	}

	spoke, err := c.updateSpokeStatus(ctx, req.NamespacedName, collectedStatus)
	if err != nil {
		c.log.Error(err, "unable to update spoke ClusterCollector status")
		return ctrl.Result{}, err
	}
	c.vInfo("updated spoke ClusterCollector status")

	if err = c.syncToHub(ctx, spoke); err != nil {
		c.log.Error(err, "unable to sync ClusterCollector to hub")
		return ctrl.Result{}, err
	}
	c.vInfo("synced ClusterCollector status to hub",
		"hubNamespace", c.clusterName,
		"name", spoke.Name,
	)

	return ctrl.Result{RequeueAfter: c.resyncAfter}, nil
}

func (c *ClusterCollectorController) updateSpokeStatus(
	ctx context.Context,
	key types.NamespacedName,
	collectedStatus ocmv1alpha1.ClusterCollectorStatus,
) (*ocmv1alpha1.ClusterCollector, error) {
	var latest ocmv1alpha1.ClusterCollector
	err := retry.RetryOnConflict(retry.DefaultRetry, func() error {
		if err := c.spokeClient.Get(ctx, key, &latest); err != nil {
			return err
		}
		latest.Status = mergeStatus(latest.Status, collectedStatus)
		return c.spokeClient.Status().Update(ctx, &latest)
	})
	if err != nil {
		return nil, err
	}
	return &latest, nil
}

func (c *ClusterCollectorController) syncToHub(ctx context.Context, spoke *ocmv1alpha1.ClusterCollector) error {
	hubKey := types.NamespacedName{Namespace: c.clusterName, Name: spoke.Name}

	return retry.RetryOnConflict(retry.DefaultRetry, func() error {
		hubClusterCollector := ocmv1alpha1.ClusterCollector{}
		err := c.hubClient.Get(ctx, hubKey, &hubClusterCollector)
		switch {
		case errors.IsNotFound(err):
			toCreate := &ocmv1alpha1.ClusterCollector{
				ObjectMeta: metav1.ObjectMeta{
					Name:      spoke.Name,
					Namespace: c.clusterName,
				},
			}
			if err = c.hubClient.Create(ctx, toCreate); err != nil {
				return fmt.Errorf("create hub ClusterCollector: %w", err)
			}
			c.vInfo("created hub ClusterCollector", "namespace", hubKey.Namespace, "name", hubKey.Name)
			hubClusterCollector = *toCreate
		case err != nil:
			return fmt.Errorf("get hub ClusterCollector: %w", err)
		}

		hubClusterCollector.Status = spoke.Status
		if c.verbose {
			c.reportHubSyncSummary(hubKey, hubClusterCollector.Status)
		}
		if c.reportJSON {
			c.reportSnapshot("hub sync payload", hubClusterCollector.Status)
		}
		if err = c.hubClient.Status().Update(ctx, &hubClusterCollector); err != nil {
			return fmt.Errorf("update hub ClusterCollector status: %w", err)
		}
		c.vInfo("updated hub ClusterCollector status",
			"namespace", hubKey.Namespace,
			"name", hubKey.Name,
			"date", hubClusterCollector.Status.Date,
		)
		return nil
	})
}

func mergeStatus(existing, collected ocmv1alpha1.ClusterCollectorStatus) ocmv1alpha1.ClusterCollectorStatus {
	if existing.SpokeURL != "" {
		collected.SpokeURL = existing.SpokeURL
	}
	if collected.ClusterName == "" {
		collected.ClusterName = existing.ClusterName
	}
	return collected
}

func (c *ClusterCollectorController) reportSnapshot(label string, status ocmv1alpha1.ClusterCollectorStatus) {
	payload, err := json.MarshalIndent(status, "", "  ")
	if err != nil {
		c.log.Error(err, "failed to marshal snapshot for json reporting", "label", label)
		return
	}
	c.log.Info(label, "json", string(payload))
}

// reportHubSyncSummary logs what will be sent to the hub without dumping JSON.
func (c *ClusterCollectorController) reportHubSyncSummary(hubKey types.NamespacedName, status ocmv1alpha1.ClusterCollectorStatus) {
	c.log.Info("sending snapshot to hub",
		"hubNamespace", hubKey.Namespace,
		"name", hubKey.Name,
		"clusterName", status.ClusterName,
		"date", status.Date,
		"lastSync", status.LastSync,
		"spokeURL", status.SpokeURL,
		"clusterVersion", status.ClusterVersion.Version,
		"clusterVersionStatus", status.ClusterVersion.Status,
		"clusterOperators", len(status.ClusterOperators),
		"installedOperators", len(status.InstalledOperators),
	)
	for _, operator := range status.ClusterOperators {
		c.log.Info("hub sync cluster operator",
			"name", operator.Name,
			"version", operator.Version,
			"status", operator.Status,
			"available", operator.Available,
			"progressing", operator.Progressing,
			"degraded", operator.Degraded,
			"message", operator.Message,
		)
	}
	for _, operator := range status.InstalledOperators {
		c.log.Info("hub sync installed operator",
			"name", operator.Name,
			"version", operator.Version,
			"phase", operator.Phase,
			"status", operator.Status,
			"namespaces", operator.Namespaces,
			"message", operator.Message,
		)
	}
}

// vInfo logs at Info level when --verbose is enabled.
func (c *ClusterCollectorController) vInfo(msg string, keysAndValues ...interface{}) {
	if c.verbose {
		c.log.Info(msg, keysAndValues...)
	}
}

// resyncInterval converts a minute count into a duration. Invalid or non-positive
// values fall back to the default resync interval.
func resyncInterval(minutes int) time.Duration {
	if minutes <= 0 {
		minutes = constants.DefaultResyncInterval
	}
	return time.Duration(minutes) * time.Minute
}
