/*
Copyright 2022.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// ClusterCollectorSpec defines the desired state of ClusterCollector
type ClusterCollectorSpec struct {
}

// ClusterVersionSnapshot holds OpenShift cluster version information.
type ClusterVersionSnapshot struct {
	Version string `json:"version,omitempty"`
	Status  string `json:"status,omitempty"`
	Message string `json:"message,omitempty"`
}

// ClusterOperatorSnapshot holds OpenShift cluster operator information.
type ClusterOperatorSnapshot struct {
	Name        string `json:"name,omitempty"`
	Version     string `json:"version,omitempty"`
	Available   string `json:"available,omitempty"`
	Progressing string `json:"progressing,omitempty"`
	Degraded    string `json:"degraded,omitempty"`
	Status      string `json:"status,omitempty"`
	Message     string `json:"message,omitempty"`
}

// InstalledOperatorSnapshot holds OLM ClusterServiceVersion information.
type InstalledOperatorSnapshot struct {
	Namespace string `json:"namespace,omitempty"`
	Name      string `json:"name,omitempty"`
	Version   string `json:"version,omitempty"`
	Phase     string `json:"phase,omitempty"`
	Status    string `json:"status,omitempty"`
	Message   string `json:"message,omitempty"`
}

// ClusterCollectorStatus defines the observed state of ClusterCollector.
// Fields match the cluster snapshot JSON shape used by the engine web UI:
// clusterName, date, clusterVersion, clusterOperators, installedOperators.
type ClusterCollectorStatus struct {
	// ClusterName is the managed cluster name (also used as hub namespace).
	ClusterName string `json:"clusterName,omitempty"`

	// SpokeURL is the url of spoke cluster
	SpokeURL string `json:"spokeURL,omitempty"`

	// Date is the snapshot timestamp used as the comparison column identifier.
	Date string `json:"date,omitempty"`

	// LastSync is the time the snapshot was last collected.
	LastSync string `json:"lastSync,omitempty"`

	ClusterVersion     ClusterVersionSnapshot      `json:"clusterVersion,omitempty"`
	ClusterOperators   []ClusterOperatorSnapshot   `json:"clusterOperators,omitempty"`
	InstalledOperators []InstalledOperatorSnapshot `json:"installedOperators,omitempty"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status

// ClusterCollector is the Schema for the clustercollectors API
type ClusterCollector struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   ClusterCollectorSpec   `json:"spec,omitempty"`
	Status ClusterCollectorStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// ClusterCollectorList contains a list of ClusterCollector
type ClusterCollectorList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []ClusterCollector `json:"items"`
}

func init() {
	SchemeBuilder.Register(&ClusterCollector{}, &ClusterCollectorList{})
}
