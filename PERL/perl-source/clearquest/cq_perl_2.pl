use CQPerlExt;

sub ListResultSet {
	my ($resultSet) = @_;
	
	$resultSet->Execute();
	$numCol = $resultSet->GetNumberOfColumns();
	print "Number of columns :  ".$numCol."\n";
	$status = $resultSet->MoveNext();
	while ($status == $CQPerlExt::CQ_SUCCESS) {
		printf("first field = %s\n", $resultSet->GetColumnValue(1));	
		$status = $resultSet->MoveNext();
	}
}

$session = CQSession::Build();
$session->UserLogon("admin", "", "pk2", "");

$EntityDefNames = $session->GetEntityDefNames();

foreach $EntityDefName (@$EntityDefNames)
{
	print "Record Type Name : ".$EntityDefName."\n";

	$EntityDef = $session->GetEntityDef($EntityDefName);

	$FieldList = $EntityDef->GetFieldDefNames();

	foreach $Field (@$FieldList)
	{
		print "    ".$Field."\n";
	}


}

$entityDefObj = $session->GetEntityDef("defect");

print "Name : ".$entityDefObj->GetName()."\n";

@FieldList = $entityDefObj->GetFieldDefNames();

print "HHHHHHHHHHHHHHH".$#FieldList."\n";

foreach $Field (@FieldList)
{
	print $Field."\n";
}


#$wkSpc = $session->GetWorkSpace();
$qryDef = $session->BuildQuery("defect");
$qryDef->BuildField("headline");
$resultSet = $session->BuildResultSet($qryDef);

printf("SQL = %s\n", $resultSet->GetSQL());
ListResultSet($resultSet);
CQSession::Unbuild($session);
