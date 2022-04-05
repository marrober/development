use CQPerlExt;

$CQSession = CQPerlExt::CQSession_Build();

$CQSession->UserLogon("admin", "","SAMPL", "CQMS.DEMO.SITEA");

$qryDef = $CQSession->BuildQuery("users");
$qryDef->BuildField("login_name");
$qryDef->BuildField("fullname");
$qryDef->BuildField("dbid");

$resultSet = $CQSession->BuildResultSet($qryDef);

ListResultSet($resultSet);
CQSession::Unbuild($CQSession);


sub ListResultSet {
	my ($resultSet) = @_;
	
	$resultSet->Execute();
	$numCol = $resultSet->GetNumberOfColumns();
	print "Number of columns :  ".$numCol."\n";
	$status = $resultSet->MoveNext();
	while ($status == $CQPerlExt::CQ_SUCCESS) {
		printf("%s | %s | %s", $resultSet->GetColumnValue(1), $resultSet->GetColumnValue(2), $resultSet->GetColumnValue(3));	
		$EntityObject = $CQSession->GetEntity("Users", $resultSet->GetColumnValue(1));
		if ($CQSession->IsSiteExtendedName($resultSet->GetColumnValue(1)))
		{
			print "Extended name ....\n";
		}
		else
		{
			print "normal name\n";
		}

		$status = $resultSet->MoveNext();
	}
}



