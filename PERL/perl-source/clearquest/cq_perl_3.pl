use CQPerlExt;

$session = CQSession::Build();
$session->UserLogon("admin", "", "IEL_T", "");

$EntityDefNames = $session->GetEntityDefNames();

foreach $EntityDefName (@$EntityDefNames)
{
	print "Record Type Name : ".$EntityDefName."\n";

	$EntityDef = $session->GetEntityDef($EntityDefName);

	$FieldList = $EntityDef->GetFieldDefNames();

	foreach $Field (@$FieldList)
	{
		print "Field name : ".$Field."\n";

	}
}


