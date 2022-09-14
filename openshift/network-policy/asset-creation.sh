oc new-project left
oc label namespace left projectName=left

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=first --env=NEXT_LAYER_NAME=second --env=NEXT_LAYER_NAMESPACE=left --env=THIS_LAYER_NAME=first --env=VERSION_ID=v1 --namespace=left

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=second --env=NEXT_LAYER_NAME=third --env=NEXT_LAYER_NAMESPACE=right --env=THIS_LAYER_NAME=second --env=VERSION_ID=v1 --namespace=left

oc expose svc/first --namespace left

oc new-project right
oc label namespace right projectName=right

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=third --env=NEXT_LAYER_NAME=fourth --env=NEXT_LAYER_NAMESPACE=right --env=THIS_LAYER_NAME=third --env=VERSION_ID=v1 --namespace=right

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=fourth --env=THIS_LAYER_NAME=fourth --env=VERSION_ID=v1 --namespace=right

oc new-project rogue
oc label namespace rogue projectName=rogue

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=rogue --env=NEXT_LAYER_NAME=third --env=NEXT_LAYER_NAMESPACE=right --env=THIS_LAYER_NAME=rogue --env=VERSION_ID=v1 --namespace=rogue

oc expose svc/rogue --namespace rogue
