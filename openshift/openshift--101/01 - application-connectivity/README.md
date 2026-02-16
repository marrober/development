# Layers application

Deploy the content using the command :

oc apply -k .

Get the route address from :

````bash
oc get route/01-app-con -n ocp-101-01-app-connectivity -o jsonpath='{"http://"}{.spec.host}{"/call-layers"}'
````

call the application :

````bash
curl $( oc get route/01-app-con -n ocp-101-01-app-connectivity -o jsonpath='{"http://"}{.spec.host}{"/call-layers"}')
````

Or use the URL from the previous command.



