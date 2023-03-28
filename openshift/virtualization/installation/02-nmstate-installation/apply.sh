oc apply -k part-1/
sleep 60
oc apply -k part-2/
sleep 20
oc get clusterserviceversion -n openshift-nmstate -o custom-columns=Name:.metadata.name,Phase:.status.phase