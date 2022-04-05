@echo off
d:
echo # Use winzip to unzip %1.zip to d:\cc_store\vobs\%2.vbs
echo # Press any key when done ......
pause
mkdir d:\cc_store\vobs\%2.vbs\db\logs
d:\apps\rational\clearcase\etc\utils\fix_prot -force -r -root -chown mroberts -chgrp clearcase_users d:\cc_store\vobs\%2.vbs
cleartool register -vob \\nw-mroberts\cc_stg\vobs\%2.vbs
cleartool mktag -vob -tag \%2 \\nw-mroberts\cc_stg\vobs\%2.vbs
cleartool protectvob -force -chown mroberts -chgrp clearcase_users \\nw-mroberts\cc_stg\vobs\%2.vbs
net use f: \\view\default
f:
cleartool mount \%2
cd app_vob
cleartool protect -chown mroberts -chgrp clearcase_users -r .
c:
net use f: /d
echo # app_vob now ready for use ..................

