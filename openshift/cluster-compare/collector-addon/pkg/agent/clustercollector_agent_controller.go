package agent

import (
	"context"
	"fmt"
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
	return collected
}

func parseResyncInterval(value string) time.Duration {
	if value == "" {
		value = constants.DefaultResyncInterval
	}

	parsed, err := time.ParseDuration(value)
	if err != nil {
		return time.Hour
	}

	return parsed
}
