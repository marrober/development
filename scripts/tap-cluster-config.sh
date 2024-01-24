#!/bin/sh

# Will output a kubeconfig file named <name>@<clustername>

# This is actually a slightly modified version of a script I found on Stack
# Overflow: https://stackoverflow.com/a/72918618

# symbolic name of cluster (only used in generated kubeconfig)
clustername=summitconnect
# name of the serviceaccount to create or use
name=byoc
# namespace of the serviceaccount
ns=default

server="$1"

if [ -z "$server" ]
then
	echo "USAGE: $0 <api_url> <sa_namespace> <sa_name>" 2>&1
	exit 1
fi

# set to oc or kubectl
kubectl=oc

# Check for existing serviceaccount first
sa_precheck=$($kubectl get sa $name -o jsonpath='{.metadata.name}' -n $ns) > /dev/null 2>&1

if [ -z "$sa_precheck" ]
then
    echo "serviceacccount/"$sa_precheck" doesn't exists"  
    exit 1
fi

sa_name=$($kubectl get sa $name -o jsonpath='{.metadata.name}' -n $ns)
sa_uid=$($kubectl get sa $name -o jsonpath='{.metadata.uid}' -n $ns)

# Check for existing secret/service-account-token, if one does not exist create one but do not output to external file
secret_precheck=$($kubectl get secret $sa_name-token-$sa_uid -o jsonpath='{.metadata.name}' -n $ns) > /dev/null 2>&1

if [ -z "$secret_precheck" ]
then 
    $kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Secret
    type: kubernetes.io/service-account-token
    metadata:
      name: $sa_name-token-$sa_uid
      namespace: $ns
      annotations:
        kubernetes.io/service-account.name: $sa_name
EOF
else
    echo "secret/"$secret_precheck" already exists"
fi

# Create Kube Config and output to config file
ca=$($kubectl get secret $sa_name-token-$sa_uid -o jsonpath='{.data.ca\.crt}' -n $ns)
token=$($kubectl get secret $sa_name-token-$sa_uid -o jsonpath='{.data.token}' -n $ns | base64 --decode)

echo "
apiVersion: v1
kind: Config
clusters:
  - name: ${clustername}
    cluster:
      certificate-authority-data: ${ca}
      server: ${server}
contexts:
  - name: ${sa_name}@${clustername}
    context:
      cluster: ${clustername}
      namespace: ${ns}
      user: ${sa_name}
users:
  - name: ${sa_name}
    user:
      token: ${token}
current-context: ${sa_name}@${clustername}
" | tee $sa_name@${clustername}