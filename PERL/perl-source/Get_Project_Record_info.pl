use CQPerlExt;

$session = CQSession::Build();
$session->UserLogon("admin", "admin", "CQINT", "7.0.0");

$qryDef = $session->BuildQuery("Project");
$qryDef->BuildField("dbid");
$qryDef->BuildField("Name");

$resultSet = $session->BuildResultSet($qryDef);

$resultSet->Execute();
$numCol = $resultSet->GetNumberOfColumns();
print "Number of columns :  ".$numCol."\n";
$status = $resultSet->MoveNext();
$counter = 0;
while ($status == $CQPerlExt::CQ_SUCCESS) {
	printf("%s | %s | %s\n", $resultSet->GetColumnValue(1), $resultSet->GetColumnValue(2));	
	$status = $resultSet->MoveNext();
	$counter++;
}
print $counter."\n";

$qryDef = $session->BuildQuery("Defect");
$qryDef->BuildField("dbid");
$qryDef->BuildField("id");
$qryDef->BuildField("Headline");
$qryDef->BuildField("State");

$resultSet = $session->BuildResultSet($qryDef);

$resultSet->Execute();
$numCol = $resultSet->GetNumberOfColumns();
print "Number of columns :  ".$numCol."\n";
$status = $resultSet->MoveNext();
$counter = 0;
while ($status == $CQPerlExt::CQ_SUCCESS) {
	printf("%s | %s | %s| %s\n", $resultSet->GetColumnValue(1), $resultSet->GetColumnValue(2), $resultSet->GetColumnValue(3), $resultSet->GetColumnValue(4));	
	$status = $resultSet->MoveNext();
	$counter++;
}
print $counter."\n";

CQSession::Unbuild($session);

