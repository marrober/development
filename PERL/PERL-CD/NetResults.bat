@echo off
se32 open,loading.htm
cd netresults
echo please wait until searcher starts on port 6010
jvm\win\bin\jre -cp . -ms8m itm.nr.serve.NRServer 

