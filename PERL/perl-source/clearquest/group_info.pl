use CQPerlExt;

$AdminSession = CQAdminSession::Build();

$AdminSession->Logon("admin", "","");

$Groups = $AdminSession->GetGroups();

for ($Counter = 0; $Counter < $Groups->Count(); $Counter++)
{
	$Group = $Groups->Item($Counter);
	print $Group->GetName();
	if ($Group->GetActive == FALSE)
	{
		print " (Inactive)";
	}

	print "\n";

	$Users = $Group->GetUsers();

	for ($UserCounter = 0; $UserCounter < $Users->Count(); $UserCounter++)
	{
		$User = $Users->Item($UserCounter);

		print " ".$User->GetName();
		if ($User->GetActive == FALSE)
		{
			print " (Inactive)";
		}
		print "\n";
	}
}


CQSession::Unbuild($AdminSession);

