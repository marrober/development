oc new-project left
oc label namespace left projectName=left

oc create secret generic github-access -n left \
 --from-literal=username=marrober \
 --from-literal=password=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

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=first --env=NEXT_LAYER_NAME=second --env=NEXT_LAYER_NAMESPACE=left --env=THIS_LAYER_NAME=first --env=VERSION_ID=v1 --namespace=left --source-secret=github-access

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=second --env=NEXT_LAYER_NAME=third --env=NEXT_LAYER_NAMESPACE=right --env=THIS_LAYER_NAME=second --env=VERSION_ID=v1 --namespace=left --source-secret=github-access

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=one --env=NEXT_LAYER_NAME=two --env=NEXT_LAYER_NAMESPACE=right --env=THIS_LAYER_NAME=one --env=VERSION_ID=v1 --namespace=left --source-secret=github-access

oc expose svc/first --namespace left
oc expose svc/one --namespace left

oc new-project right
oc label namespace right projectName=right

oc create secret generic github-access -n right \
 --from-literal=username=marrober \
 --from-literal=password=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

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=third --env=NEXT_LAYER_NAME=fourth --env=NEXT_LAYER_NAMESPACE=right --env=THIS_LAYER_NAME=third --env=VERSION_ID=v1 --namespace=right --source-secret=github-access

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=fourth --env=THIS_LAYER_NAME=fourth --env=VERSION_ID=v1 --namespace=right --source-secret=github-access

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=two --env=THIS_LAYER_NAME=two --env=VERSION_ID=v1 --namespace=right --source-secret=github-access

oc new-project rogue
oc label namespace rogue projectName=rogue

oc create secret generic github-access -n rogue \
 --from-literal=username=marrober \
 --from-literal=password=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

oc new-app nodejs~https://github.com/marrober/development.git#main --context-dir=openshift/network-policy --name=rogue --env=NEXT_LAYER_NAME=two --env=NEXT_LAYER_NAMESPACE=right --env=THIS_LAYER_NAME=rogue --env=VERSION_ID=v1 --namespace=rogue --source-secret=github-access

oc expose svc/rogue --namespace rogue
