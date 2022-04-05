use CQPerlExt;

	$AdminSession = CQAdminSession::Build();
	$AdminSession->Logon ("admin", "admin", "");

	$grplist = $AdminSession->GetGroups();
	$numgrp = $grplist->Count();

	print "Numberof groups : ".$numgrp."\n";

	for ($i=0; $i < $numgrp;$i++)
	{
		$grpobj = $grplist->Item($i);
		$grpname = $grpobj->GetName();

		print "Group name : ".$grpname."\n";

		$userlist = $grpobj->GetUsers();
		for ($j=0; $j < $userlist->Count(); $j++)
		{
			print "\t\t .....   ".$userlist->Item($j)->GetName()."\n";
		}
	}


