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
	ocmv1alpha1 "open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/api/v1alpha1"
	"open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/pkg/collector"
	"open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/pkg/constants"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
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
}

func (c *ClusterCollectorController) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&ocmv1alpha1.ClusterCollector{}).
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
		c.log.Info("spoke ClusterCollector already exists", "namespace", key.Namespace, "name", key.Name)
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
	c.log.Info("created spoke ClusterCollector", "namespace", key.Namespace, "name", key.Name)
	return nil
}

func (c *ClusterCollectorController) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	c.log.Info("reconciling ClusterCollector", "namespacedName", req.String())
	defer c.log.Info("done reconcile", "namespacedName", req.String())

	clusterCollector := ocmv1alpha1.ClusterCollector{}
	err := c.spokeClient.Get(ctx, req.NamespacedName, &clusterCollector)
	switch {
	case errors.IsNotFound(err):
		return ctrl.Result{}, nil
	case err != nil:
		c.log.Error(err, "unable to get ClusterCollector")
		return ctrl.Result{}, err
	}

	collectedStatus, err := c.collector.Collect(ctx)
	if err != nil {
		c.log.Error(err, "failed to collect cluster snapshot")
		return ctrl.Result{RequeueAfter: c.resyncAfter}, err
	}

	clusterCollector.Status = mergeStatus(clusterCollector.Status, collectedStatus)
	c.log.Info("collected cluster snapshot",
		"clusterName", collectedStatus.ClusterName,
		"date", collectedStatus.Date,
		"clusterVersion", collectedStatus.ClusterVersion.Version,
		"clusterOperators", len(collectedStatus.ClusterOperators),
		"installedOperators", len(collectedStatus.InstalledOperators),
	)
	if c.verbose {
		c.reportSnapshot("collected snapshot (pre-hub-sync)", clusterCollector.Status)
	}

	if err = c.spokeClient.Status().Update(ctx, &clusterCollector); err != nil {
		c.log.Error(err, "unable to update spoke ClusterCollector status")
		return ctrl.Result{RequeueAfter: c.resyncAfter}, err
	}
	c.log.Info("updated spoke ClusterCollector status")

	if err = c.syncToHub(ctx, &clusterCollector); err != nil {
		c.log.Error(err, "unable to sync ClusterCollector to hub")
		return ctrl.Result{RequeueAfter: c.resyncAfter}, err
	}
	c.log.Info("synced ClusterCollector status to hub",
		"hubNamespace", c.clusterName,
		"name", clusterCollector.Name,
	)

	return ctrl.Result{RequeueAfter: c.resyncAfter}, nil
}

func (c *ClusterCollectorController) syncToHub(ctx context.Context, spoke *ocmv1alpha1.ClusterCollector) error {
	hubKey := types.NamespacedName{Namespace: c.clusterName, Name: spoke.Name}
	hubClusterCollector := ocmv1alpha1.ClusterCollector{}
	err := c.hubClient.Get(ctx, hubKey, &hubClusterCollector)
	switch {
	case errors.IsNotFound(err):
		// Create the object first (status is ignored on create), then update status.
		toCreate := &ocmv1alpha1.ClusterCollector{
			ObjectMeta: metav1.ObjectMeta{
				Name:      spoke.Name,
				Namespace: c.clusterName,
			},
		}
		if err = c.hubClient.Create(ctx, toCreate); err != nil {
			return fmt.Errorf("create hub ClusterCollector: %w", err)
		}
		c.log.Info("created hub ClusterCollector", "namespace", hubKey.Namespace, "name", hubKey.Name)
		hubClusterCollector = *toCreate
	case err != nil:
		return fmt.Errorf("get hub ClusterCollector: %w", err)
	}

	hubClusterCollector.Status = spoke.Status
	if c.verbose {
		c.reportSnapshot("hub sync payload", hubClusterCollector.Status)
	}
	if err = c.hubClient.Status().Update(ctx, &hubClusterCollector); err != nil {
		return fmt.Errorf("update hub ClusterCollector status: %w", err)
	}
	return nil
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
		c.log.Error(err, "failed to marshal snapshot for verbose reporting", "label", label)
		return
	}
	// Use the controller logger so output appears with the same sink as other agent logs.
	c.log.Info(label, "json", string(payload))
}

// resyncInterval converts a minute count into a duration. Invalid or non-positive
// values fall back to the default resync interval.
func resyncInterval(minutes int) time.Duration {
	if minutes <= 0 {
		minutes = constants.DefaultResyncInterval
	}
	return time.Duration(minutes) * time.Minute
}
