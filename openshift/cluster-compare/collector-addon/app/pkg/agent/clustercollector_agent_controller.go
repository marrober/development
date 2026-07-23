package agent

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/go-logr/logr"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/types"
	ocmv1alpha1 "open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/api/v1alpha1"
	"open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/pkg/collector"
	"open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/pkg/constants"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
)

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

func (c *ClusterCollectorController) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	c.log.Info(fmt.Sprintf("reconciling... %s", req))
	defer c.log.Info(fmt.Sprintf("done reconcile %s", req))

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
		c.reportHubPayload(clusterCollector.Status)
	}
	if err = c.spokeClient.Status().Update(ctx, &clusterCollector); err != nil {
		c.log.Error(err, "unable to update spoke ClusterCollector status")
		return ctrl.Result{RequeueAfter: c.resyncAfter}, err
	}

	hubClusterCollector := ocmv1alpha1.ClusterCollector{}
	err = c.hubClient.Get(ctx, types.NamespacedName{Namespace: c.clusterName, Name: clusterCollector.Name}, &hubClusterCollector)
	switch {
	case errors.IsNotFound(err):
		hubClusterCollector.Name = clusterCollector.Name
		hubClusterCollector.Namespace = c.clusterName
		hubClusterCollector.Status = clusterCollector.Status
		if err = c.hubClient.Create(ctx, &hubClusterCollector); err != nil {
			c.log.Error(err, "unable to create hub ClusterCollector")
			return ctrl.Result{RequeueAfter: c.resyncAfter}, err
		}
	case err != nil:
		c.log.Error(err, "unable to get hub ClusterCollector")
		return ctrl.Result{RequeueAfter: c.resyncAfter}, err
	default:
		hubClusterCollector.Status = clusterCollector.Status
		if err = c.hubClient.Status().Update(ctx, &hubClusterCollector); err != nil {
			c.log.Error(err, "unable to update hub ClusterCollector")
			return ctrl.Result{RequeueAfter: c.resyncAfter}, err
		}
	}

	return ctrl.Result{RequeueAfter: c.resyncAfter}, nil
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

func (c *ClusterCollectorController) reportHubPayload(status ocmv1alpha1.ClusterCollectorStatus) {
	payload, err := json.MarshalIndent(status, "", "  ")
	if err != nil {
		c.log.Error(err, "failed to marshal hub sync payload for verbose reporting")
		return
	}
	fmt.Fprintln(os.Stdout, "hub sync payload:")
	fmt.Fprintln(os.Stdout, string(payload))
}

// resyncInterval converts a minute count into a duration. Invalid or non-positive
// values fall back to the default resync interval.
func resyncInterval(minutes int) time.Duration {
	if minutes <= 0 {
		minutes = constants.DefaultResyncInterval
	}
	return time.Duration(minutes) * time.Minute
}
