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
$session->UserLogon("admin", "", "SAMPL", "");
#$wkSpc = $session->GetWorkSpace();
$qryDef = $session->BuildQuery("defect");
$qryDef->BuildField("headline");
$resultSet = $session->BuildResultSet($qryDef);

printf("SQL = %s\n", $resultSet->GetSQL());
ListResultSet($resultSet);
CQSession::Unbuild($session);
