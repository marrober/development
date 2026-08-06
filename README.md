# Development

To use a development environment click on one of the Dev Spaces links below.

## Pacman and Quarkus App

[![Logo](images/DevSpaces-Medium.png)](https://devspaces.apps.cluster-4jhcf.4jhcf.sandbox797.opentlc.com/dashboard/f?override.devfileFilename=openshift/odo/devfile.yaml&url=https://github.com/marrober/development)

### Image pull secret

oc create secret generic redhat-registry-pull-secret  --from-file=.dockerconfigjson=pull-secret.json --type=kubernetes.io/dockerconfigjson

oc secrets link pipeline redhat-registry-pull-secret --for=pull