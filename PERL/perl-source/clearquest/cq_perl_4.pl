use CQPerlExt;

$session = CQSession::Build();
$session->UserLogon("admin", "", "CLSIC", "");

$qryDef = $session->BuildQuery("users");
$qryDef->BuildField("login_name");

$resultSet = $session->BuildResultSet($qryDef);

printf("SQL = %s\n", $resultSet->GetSQL());
$resultSet->Execute();
$numCol = $resultSet->GetNumberOfColumns();
print "Number of columns :  ".$numCol."\n";
$status = $resultSet->MoveNext();
$counter = 0;
while ($status == $CQPerlExt::CQ_SUCCESS) {
	printf("%s | %s | %s\n", $resultSet->GetColumnValue(1));	
	push(@users, $resultSet->GetColumnValue(1));
	$status = $resultSet->MoveNext();
	$counter++;
}
print $counter."\n";

foreach $U (@users) 
{
	$qryDef = $session->BuildQuery("Defect");
	$qryDef->BuildField("id");
	$qryDef->BuildField("StartDate");
	$qryDef->BuildField("EndDate");

	push(@States, "Opened");
	push(@States, "Submitted");

	push(@Owner, $U);

	my $Filter = $qryDef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
	$Filter->BuildFilter("State", $CQPerlExt::CQ_COMP_OP_EQ, \@States);
	$Filter->BuildFilter("Owner", $CQPerlExt::CQ_COMP_OP_EQ, \@Owner);

	$resultSet = $session->BuildResultSet($qryDef);

	print $U."\n";
	ListResultSet($resultSet);
}
CQSession::Unbuild($session);


sub ListResultSet {
	my ($resultSet) = @_;
	
	$resultSet->Execute();
	$numCol = $resultSet->GetNumberOfColumns();
	$status = $resultSet->MoveNext();
	$counter = 0;
	while ($status == $CQPerlExt::CQ_SUCCESS) {
		printf("%s | %s | %s\n", $resultSet->GetColumnValue(1), $resultSet->GetColumnValue(2), $resultSet->GetColumnValue(3));	
		$status = $resultSet->MoveNext();
		$counter++;
	}
	print $counter."\n";
}
