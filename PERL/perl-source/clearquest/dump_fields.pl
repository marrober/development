use CQPerlExt;

$session = CQSession::Build();
$session->UserLogon("admin", "", @ARGV[1], @ARGV[0]);
# $session->UserLogon("admin", "", "Clsic", "2002.05.00");

$EntityDefNames = $session->GetEntityDefNames();

foreach $EntityDefName (@$EntityDefNames)
{
	$EntityDef = $session->GetEntityDef($EntityDefName);

	if ($EntityDef->GetType == $CQPerlExt::CQ_REQ_ENTITY)
	{
		print "Record Type Name : ".$EntityDefName."\n";

		$StateNames = $EntityDef->GetStateDefNames();

		print "States : \n";

		foreach  $State (@$StateNames)
		{
			print "    ".$State."\n";
		}

		$ActionList = $EntityDef->GetActionDefNames();

		print "Actions : \n";

		foreach $Action (@$ActionList)
		{
			print "    ".$Action." ".$EntityDef->GetActionDestStateName($Action)."\n";
		}

	}


}

foreach $EntityDefName (@$EntityDefNames)
{
	print "Record Type Name : ".$EntityDefName."\n";

	$EntityDef = $session->GetEntityDef($EntityDefName);

	$FieldList = $EntityDef->GetFieldDefNames();

	foreach $Field (@$FieldList)
	{

		if (!$EntityDef->IsSystemOwnedFieldDefName($Field))
		{
			print "    ".$Field.", ";
			$FieldType = $EntityDef->GetFieldDefType($Field);

			if ($FieldType == 1) { print "SS"; }
			elsif ($FieldType == 2) { print "MLS"; }
			elsif ($FieldType == 3) { print "INT"; }
			elsif ($FieldType == 4) { print "DATE"; }
			elsif ($FieldType == 5) { print "REF"; }
			elsif ($FieldType == 6) { print "REF-List"; }
			elsif ($FieldType == 7) { print "Att"; }
			elsif ($FieldType == 8) { print "ID"; }
			elsif ($FieldType == 9) { print "STATE"; }
			elsif ($FieldType == 10) { print "JOURNAL"; }
			else { print "DBID"; }

			if (($FieldType >= 5) && ($FieldType <= 6)) 
			{ 
				$RefObj = $EntityDef->GetFieldReferenceEntityDef($Field); 
				print ",".$RefObj->GetName()."\n";
			}
			else
			{
				print "\n";
			}
		}
	}
}



CQSession::Unbuild($session);
