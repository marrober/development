# Add the github access token before executing.

oc process -f project-template.yaml -p PROJECT_NAME=left -p ASPECT=network-security | oc create -f -

oc create secret generic github-access -n left --type=kubernetes.io/basic-auth \
 --from-literal=username=marrober \
 --from-literal=password=$1

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --source-secret=github-access --name=one --env=NEXT_LAYER_NAME=two --env=NEXT_LAYER_NAMESPACE=right --env=THIS_LAYER_NAME=one --env=VERSION_ID=v1 --namespace=left 

oc expose svc/one --namespace left

oc process -f project-template.yaml -p PROJECT_NAME=right -p ASPECT=network-security | oc create -f -

oc create secret generic github-access -n right --type=kubernetes.io/basic-auth \
 --from-literal=username=marrober \
 --from-literal=password=$1

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --source-secret=github-access --name=two --env=THIS_LAYER_NAME=two --env=VERSION_ID=v1 --namespace=right --source-secret=github-access

oc process -f project-template.yaml -p PROJECT_NAME=rogue -p ASPECT=network-security | oc create -f -

oc create secret generic github-access -n rogue --type=kubernetes.io/basic-auth \
 --from-literal=username=marrober \
 --from-literal=password=$1

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --source-secret=github-access --name=rogue --env=NEXT_LAYER_NAME=two --env=NEXT_LAYER_NAMESPACE=right --env=THIS_LAYER_NAME=rogue --env=VERSION_ID=v1 --namespace=rogue

oc expose svc/rogue --namespace rogue

oc get route/one -n left -o jsonpath='{"http://"}{.spec.host}{"/call-layers\n"}'

oc get route/rogue -n rogue -o jsonpath='{"http://"}{.spec.host}{"/call-layers\n"}'
