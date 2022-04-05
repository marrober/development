use CQPerlExt;

$AdminSession = CQAdminSession::Build();

$AdminSession->Logon("admin", "","CQMS.DEMO.SITEA");

$Users = $AdminSession->GetUsers();

for ($Counter = 0; $Counter < $Users->Count(); $Counter++)
{
	$User = $Users->Item($Counter);
	print $User->GetName();
	if ($User->GetActive == FALSE)
	{
		print " (Inactive)";
	}
	else
	{	
		print " (Active)";
	}

	print "\n";

	$Groups = $User->GetGroups();

	for ($GroupCounter = 0; $GroupCounter < $Groups->Count(); $GroupCounter++)
	{
		$Group = $Groups->Item($GroupCounter);
		print " ".$Group->GetName();
		if ($Group->GetActive == FALSE)
		{
			print " (Inactive) ";
		}

		if ($GroupCounter < $Groups->Count() - 1) 
		{
			print ",";
		}
		else
		{
			print "\n";
		}
	}
}


CQSession::Unbuild($AdminSession);

