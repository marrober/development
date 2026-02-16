# Layers application

Deploy the content using the command :

oc apply -k .

Get the route address from :

````bash
oc get route/01-app-con -n ocp-101-01 -o jsonpath='{"http://"}{.spec.host}{"/call-layers"}'
````

call the application :

````bash
curl $(oc get route/01-app-con -n ocp-101-01 -o jsonpath='{"http://"}{.spec.host}{"/call-layers"}')
````

Or use the URL from the previous command.

Put the application URL into the GATEWAY environment variable so that it can be called in a loop by the shell script.

copy and paste this command :

````bash
export GATEWAY=$(oc get route/01-app-con -n ocp-101-01 -o jsonpath='{"http://"}{.spec.host}{"/call-layers"}')
````
Call the application in a loop 300 times from the script:

````bash
./loop.sh
````