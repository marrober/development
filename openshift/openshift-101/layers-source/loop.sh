for i in {1..200}
do
   echo "attempt ... $i"
   curl https://layers-ocp-101-03.apps.ocp4.mr-openshift.co.uk
   sleep 2
done
