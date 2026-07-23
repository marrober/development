package agent

import (
	"context"
	"flag"
	"fmt"

	"github.com/go-logr/logr"
	"github.com/spf13/cobra"
	configclient "github.com/openshift/client-go/config/clientset/versioned"
	"k8s.io/apimachinery/pkg/runtime"
	utilruntime "k8s.io/apimachinery/pkg/util/runtime"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/kubernetes"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/tools/clientcmd"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"

	ocmv1alpha1 "open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/api/v1alpha1"
	"open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/pkg/collector"
	"open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/pkg/constants"
	"open-cluster-management.io/addon-framework/pkg/lease"
	addonv1alpha1 "open-cluster-management.io/api/addon/v1alpha1"
)

var (
	scheme = runtime.NewScheme()
)

func init() {
	utilruntime.Must(clientgoscheme.AddToScheme(scheme))
	utilruntime.Must(addonv1alpha1.AddToScheme(scheme))
	utilruntime.Must(ocmv1alpha1.AddToScheme(scheme))
}

func NewAgentCommand(addonName string, logger logr.Logger) *cobra.Command {
	o := NewAgentOptions(addonName, logger)

	ctx := context.TODO()

	cmd := &cobra.Command{
		Use:   "agent",
		Short: fmt.Sprintf("Start the %s's agent", addonName),
		RunE: func(cmd *cobra.Command, args []string) error {
			return o.runControllerManager(ctx)
		},
	}

	o.AddFlags(cmd)

	cmd.FParseErrWhitelist.UnknownFlags = true

	return cmd
}

// AgentOptions defines the flags for workload agent
type AgentOptions struct {
	Log               logr.Logger
	HubKubeconfigFile string
	SpokeClusterName  string
	AddonName         string
	ResyncInterval    int
	Verbose           bool
}

// NewAgentOptions returns the flags with default value set
func NewAgentOptions(addonName string, logger logr.Logger) *AgentOptions {
	return &AgentOptions{
		AddonName:      addonName,
		Log:            logger,
		ResyncInterval: constants.DefaultResyncInterval,
	}
}

func (o *AgentOptions) AddFlags(cmd *cobra.Command) {
	flags := cmd.Flags()
	flags.StringVar(&o.HubKubeconfigFile, "hub-kubeconfig", o.HubKubeconfigFile, "Location of kubeconfig file to connect to hub cluster.")
	flags.StringVar(&o.SpokeClusterName, "cluster-name", o.SpokeClusterName, "Name of spoke cluster.")
	flags.IntVar(&o.ResyncInterval, "resync-interval", o.ResyncInterval, "How often to collect and sync cluster snapshots, in minutes.")
	flags.BoolVar(&o.Verbose, "verbose", o.Verbose, "Print the full cluster snapshot payload that will be sent to the hub cluster.")
}

func (o *AgentOptions) runControllerManager(ctx context.Context) error {
	log := o.Log.WithName("controller-manager-setup")

	// controller-runtime uses a global logger; without this, Kind/source errors are hidden.
	ctrl.SetLogger(o.Log)

	flag.Parse()

	spokeConfig := ctrl.GetConfigOrDie()
	mgr, err := ctrl.NewManager(spokeConfig, ctrl.Options{
		Scheme:         scheme,
		LeaderElection: false,
	})
	if err != nil {
		log.Error(err, "unable to start manager")
		return fmt.Errorf("unable to create manager, err: %w", err)
	}

	hubConfig, err := clientcmd.BuildConfigFromFlags("" /* leave masterurl as empty */, o.HubKubeconfigFile)
	if err != nil {
		return fmt.Errorf("failed to create hubConfig from flag, err: %w", err)
	}

	hubClient, err := client.New(hubConfig, client.Options{Scheme: scheme})
	if err != nil {
		return fmt.Errorf("failed to create hubClient, err: %w", err)
	}

	spokeKubeClient, err := client.New(spokeConfig, client.Options{Scheme: scheme})
	if err != nil {
		return fmt.Errorf("failed to create spoke client, err: %w", err)
	}

	configClient, err := configclient.NewForConfig(spokeConfig)
	if err != nil {
		return fmt.Errorf("failed to create openshift config client, err: %w", err)
	}

	dynamicClient, err := dynamic.NewForConfig(spokeConfig)
	if err != nil {
		return fmt.Errorf("failed to create dynamic client, err: %w", err)
	}

	leaseClient, err := kubernetes.NewForConfig(spokeConfig)
	if err != nil {
		return fmt.Errorf("failed to create lease client, err: %w", err)
	}

	leaseUpdater := lease.NewLeaseUpdater(
		leaseClient,
		o.AddonName,
		constants.AgentInstallationNamespace,
	)

	go leaseUpdater.Start(ctx)

	log.Info("starting manager")

	clusterCollectorController := &ClusterCollectorController{
		spokeClient: spokeKubeClient,
		hubClient:   hubClient,
		collector:   collector.New(configClient, dynamicClient, o.SpokeClusterName),
		log:         o.Log,
		clusterName: o.SpokeClusterName,
		resyncAfter: resyncInterval(o.ResyncInterval),
		verbose:     o.Verbose,
	}

	if err = clusterCollectorController.SetupWithManager(mgr); err != nil {
		return fmt.Errorf("unable to create cluster compare collector agent controller: %s, err: %w", "cluster-compare-collector-agent", err)
	}

	// Create the spoke CR once the cache is ready so the controller has something to reconcile.
	if err := mgr.Add(managerRunnable(func(ctx context.Context) error {
		if err := clusterCollectorController.EnsureSpokeCollector(ctx); err != nil {
			log.Error(err, "failed to ensure spoke ClusterCollector exists")
			return err
		}
		if o.Verbose {
			log.Info("verbose reporting enabled; full snapshot JSON will be logged each sync")
		}
		return nil
	})); err != nil {
		return fmt.Errorf("unable to register spoke ClusterCollector ensurer: %w", err)
	}

	return mgr.Start(ctrl.SetupSignalHandler())
}

type managerRunnable func(context.Context) error

func (r managerRunnable) Start(ctx context.Context) error {
	return r(ctx)
}
