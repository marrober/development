# Add the github access token before executing.

oc new-project left
oc label namespace left projectName=left

oc create secret generic github-access -n left \
 --from-literal=username=marrober \
 --from-literal=password=

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=one --env=NEXT_LAYER_NAME=two --env=NEXT_LAYER_NAMESPACE=right --env=THIS_LAYER_NAME=one --env=VERSION_ID=v1 --namespace=left 

oc expose svc/one --namespace left

oc new-project right
oc label namespace right projectName=right

oc create secret generic github-access -n right \
 --from-literal=username=marrober \
 --from-literal=password=

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=two --env=THIS_LAYER_NAME=two --env=VERSION_ID=v1 --namespace=right --source-secret=github-access

oc new-project rogue
oc label namespace rogue projectName=rogue

oc create secret generic github-access -n rogue \
 --from-literal=username=marrober \
 --from-literal=password=

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=rogue --env=NEXT_LAYER_NAME=two --env=NEXT_LAYER_NAMESPACE=right --env=THIS_LAYER_NAME=rogue --env=VERSION_ID=v1 --namespace=rogue

oc expose svc/rogue --namespace rogue

oc get route/one -n left -o jsonpath='{"http://"}{.spec.host}{"/call-layers\n"}'

oc get route/rogue -n rogue -o jsonpath='{"http://"}{.spec.host}{"/call-layers\n"}'
