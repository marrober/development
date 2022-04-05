use CQPerlExt;

$UserName = "admin";
$Password = "rational";
$CQDB = "CLSIC";
$CQDBSet = "2003.06.00";

$session = CQSession::Build();
$session->UserLogon($UserName, $Password, $CQDB, $CQDBSet);

$qryDef = $session->BuildQuery("Defect");
$qryDef->BuildField("id");
$qryDef->BuildField("State");
$qryDef->BuildField("Owner");
$qryDef->BuildField("Headline");

push(@UserName, "sandy");
push(@UserName, "chris");

push (@States, "Assigned");
push (@States, "Opened");

$Filter = $qryDef->BuildFilterOperator ($CQPerlExt::CQ_BOOL_OP_AND);
$Filter->BuildFilter("Owner", $CQPerlExt::CQ_COMP_OP_IN, \@UserName);
$Filter->BuildFilter("State", $CQPerlExt::CQ_COMP_OP_IN, \@States);

$resultSet = $session->BuildResultSet($qryDef);

$resultSet->Execute();
$numCol = $resultSet->GetNumberOfColumns();
$status = $resultSet->MoveNext();
while ($status == $CQPerlExt::CQ_SUCCESS) {
	for ($Counter = 1; $Counter <= $numCol; $Counter++) {
		printf("%12s", substr($resultSet->GetColumnValue($Counter), 0, 23));
		print "\t";
	}
	print "\n";
	$status = $resultSet->MoveNext();
}



CQSession::Unbuild($session);





