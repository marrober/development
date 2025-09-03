# Network policy example

## Create the namespaces and deployments.

````bash 
./asset-creation.sh
 ````

Create environment variables for the routes using the information exposed at the end of the script. Example shown below.

````bash 
 export LEFTROUTE=$(oc get route/one -n left -o jsonpath='{"http://"}{.spec.host}{"/call-layers"}')
 export ROGUEROUTE=$(oc get route/rogue -n rogue -o jsonpath='{"http://"}{.spec.host}{"/call-layers"}')
 ````

## Send traffic to the applications

````bash 
./loop.sh
````

## Test external connectivity

From a terminal on the pod called 'two-....' in the 'right' namespace execute the curl command :

````bash
curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/marrober/myApp-cd/commits/62d032f39c0bde2bc62d0c114bd739df46b8a5a5/status 
````

or

````bash
curl -v -LO https://download.fedoraproject.org/pub/fedora/linux/releases/42/Workstation/x86_64/iso/Fedora-Workstation-Live-42-1.1.x86_64.iso --output fedora.iso
````

The above will probe the git repository commit for status information and should return a json payload.

## Apply the 'block egress' network policy

Apply the network policy defined in the file 02-block-egress-right.yaml

Show that the above curl command no longer works.

## View the baseline communications

View the baseline communications and show that all communications is marked as allowed. Mark the rogue traffic as anomolous and rerun the loop command to send traffic.

Generate a network policy based on the requirements for allowed baseline traffic. Copy and paste the newtowk policy to apply it and show that the rogue traffic is now blocked.



