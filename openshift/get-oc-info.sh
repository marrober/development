echo "ArgoCD password :" $(oc get secret/openshift-gitops-cluster  -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d)
echo "ArgoCD URL :" $(oc get route/openshift-gitops-server -n openshift-gitops -o jsonpath='{"https://"}{.spec.host}')
echo ""
