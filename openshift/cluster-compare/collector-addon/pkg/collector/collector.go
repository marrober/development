package collector

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"time"

	configv1 "github.com/openshift/api/config/v1"
	configclient "github.com/openshift/client-go/config/clientset/versioned"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/dynamic"

	ocmv1alpha1 "open-cluster-management.io/addon-contrib/cluster-compare-collector-addon/api/v1alpha1"
)

const clusterVersionName = "version"

var csvGVR = schema.GroupVersionResource{
	Group:    "operators.coreos.com",
	Version:  "v1alpha1",
	Resource: "clusterserviceversions",
}

// Collector gathers OpenShift cluster version and operator snapshots from a spoke cluster.
type Collector struct {
	configClient  configclient.Interface
	dynamicClient dynamic.Interface
}

func New(configClient configclient.Interface, dynamicClient dynamic.Interface) *Collector {
	return &Collector{
		configClient:  configClient,
		dynamicClient: dynamicClient,
	}
}

func (c *Collector) Collect(ctx context.Context) (ocmv1alpha1.ClusterCollectorStatus, error) {
	now := time.Now().UTC().Format(time.RFC3339)
	status := ocmv1alpha1.ClusterCollectorStatus{
		Date:     now,
		LastSync: now,
	}

	cv, err := c.configClient.ConfigV1().ClusterVersions().Get(ctx, clusterVersionName, metav1.GetOptions{})
	if err != nil {
		return status, fmt.Errorf("get cluster version: %w", err)
	}
	status.ClusterVersion = clusterVersionFromCV(cv)

	operators, err := c.configClient.ConfigV1().ClusterOperators().List(ctx, metav1.ListOptions{})
	if err != nil {
		return status, fmt.Errorf("list cluster operators: %w", err)
	}
	status.ClusterOperators = clusterOperatorsFromList(operators.Items)

	csvs, err := c.listInstalledOperators(ctx)
	if err != nil {
		return status, fmt.Errorf("list installed operators: %w", err)
	}
	status.InstalledOperators = csvs

	return status, nil
}

func clusterVersionFromCV(cv *configv1.ClusterVersion) ocmv1alpha1.ClusterVersionSnapshot {
	snapshot := ocmv1alpha1.ClusterVersionSnapshot{
		Version: completedClusterVersion(cv),
		Status:  conditionStatus(cv.Status.Conditions, configv1.OperatorAvailable),
		Message: conditionMessage(cv.Status.Conditions, configv1.OperatorAvailable),
	}
	if snapshot.Status == "" {
		snapshot.Status = conditionStatus(cv.Status.Conditions, configv1.OperatorProgressing)
	}
	if snapshot.Message == "" {
		snapshot.Message = conditionMessage(cv.Status.Conditions, configv1.OperatorProgressing)
	}
	return snapshot
}

func completedClusterVersion(cv *configv1.ClusterVersion) string {
	for _, history := range cv.Status.History {
		if history.State == configv1.CompletedUpdate {
			return history.Version
		}
	}
	if cv.Spec.DesiredUpdate != nil {
		return cv.Spec.DesiredUpdate.Version
	}
	return ""
}

func clusterOperatorsFromList(items []configv1.ClusterOperator) []ocmv1alpha1.ClusterOperatorSnapshot {
	snapshots := make([]ocmv1alpha1.ClusterOperatorSnapshot, 0, len(items))
	for _, operator := range items {
		snapshots = append(snapshots, ocmv1alpha1.ClusterOperatorSnapshot{
			Name:        operator.Name,
			Version:     operatorVersion(operator),
			Available:   conditionStatus(operator.Status.Conditions, configv1.OperatorAvailable),
			Progressing: conditionStatus(operator.Status.Conditions, configv1.OperatorProgressing),
			Degraded:    conditionStatus(operator.Status.Conditions, configv1.OperatorDegraded),
			Status:      overallOperatorStatus(operator.Status.Conditions),
			Message:     operatorConditionMessage(operator.Status.Conditions),
		})
	}

	sort.Slice(snapshots, func(i, j int) bool {
		return snapshots[i].Name < snapshots[j].Name
	})

	return snapshots
}

func operatorVersion(operator configv1.ClusterOperator) string {
	for _, version := range operator.Status.Versions {
		if version.Name == "operator" {
			return version.Version
		}
	}
	if len(operator.Status.Versions) > 0 {
		return operator.Status.Versions[0].Version
	}
	return ""
}

func overallOperatorStatus(conditions []configv1.ClusterOperatorStatusCondition) string {
	if conditionStatus(conditions, configv1.OperatorDegraded) == string(metav1.ConditionTrue) {
		return "Degraded"
	}
	if conditionStatus(conditions, configv1.OperatorAvailable) == string(metav1.ConditionTrue) {
		return "Available"
	}
	if conditionStatus(conditions, configv1.OperatorProgressing) == string(metav1.ConditionTrue) {
		return "Progressing"
	}
	return "Unknown"
}

func operatorConditionMessage(conditions []configv1.ClusterOperatorStatusCondition) string {
	for _, conditionType := range []configv1.ClusterStatusConditionType{
		configv1.OperatorDegraded,
		configv1.OperatorProgressing,
		configv1.OperatorAvailable,
	} {
		if message := conditionMessage(conditions, conditionType); message != "" {
			return message
		}
	}
	return ""
}

func conditionStatus(conditions []configv1.ClusterOperatorStatusCondition, conditionType configv1.ClusterStatusConditionType) string {
	for _, condition := range conditions {
		if condition.Type == conditionType {
			return string(condition.Status)
		}
	}
	return ""
}

func conditionMessage(conditions []configv1.ClusterOperatorStatusCondition, conditionType configv1.ClusterStatusConditionType) string {
	for _, condition := range conditions {
		if condition.Type == conditionType {
			return condition.Message
		}
	}
	return ""
}

func (c *Collector) listInstalledOperators(ctx context.Context) ([]ocmv1alpha1.InstalledOperatorSnapshot, error) {
	list, err := c.dynamicClient.Resource(csvGVR).List(ctx, metav1.ListOptions{})
	if err != nil {
		return nil, err
	}

	snapshots := make([]ocmv1alpha1.InstalledOperatorSnapshot, 0, len(list.Items))
	for _, item := range list.Items {
		snapshots = append(snapshots, installedOperatorFromCSV(&item))
	}

	sort.Slice(snapshots, func(i, j int) bool {
		if snapshots[i].Namespace == snapshots[j].Namespace {
			return snapshots[i].Name < snapshots[j].Name
		}
		return snapshots[i].Namespace < snapshots[j].Namespace
	})

	return snapshots, nil
}

func installedOperatorFromCSV(csv *unstructured.Unstructured) ocmv1alpha1.InstalledOperatorSnapshot {
	phase, _, _ := unstructured.NestedString(csv.Object, "status", "phase")
	reason, _, _ := unstructured.NestedString(csv.Object, "status", "reason")
	message, _, _ := unstructured.NestedString(csv.Object, "status", "message")
	version, _, _ := unstructured.NestedString(csv.Object, "spec", "version")

	status := phase
	if reason != "" && !strings.Contains(status, reason) {
		status = fmt.Sprintf("%s (%s)", phase, reason)
	}

	return ocmv1alpha1.InstalledOperatorSnapshot{
		Namespace: csv.GetNamespace(),
		Name:      csv.GetName(),
		Version:   version,
		Phase:     phase,
		Status:    status,
		Message:   message,
	}
}
