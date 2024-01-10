echo "ArgoCD admin password"
echo ""

oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-

echo ""
echo "ArgoCD route"
echo ""

oc get route/openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}'

echo ""
echo ""
echo "ACS admin password"
echo ""

oc -n rhacs-operator  get secret central-htpasswd -o go-template='{{index .data "password" | base64decode}}'

echo ""
echo ""
echo "ACS route"
echo ""

oc get route -n rhacs-operator  central -o jsonpath='{"https://"}{.spec.host}{"\n"}'

echo ""
