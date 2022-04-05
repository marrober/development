use CQPerlExt;

$session = CQSession::Build();
$session->UserLogon("admin", "", "cogp", "General");

$qryDef = $session->BuildQuery("Action");
$qryDef->BuildField("id");
$qryDef->BuildField("Action_Number");
$qryDef->BuildField("state");

@StateRequired = ("Action_Started");

@DateTime = gmtime(time);

$DateAndTime = @DateTime[3]."/".(@DateTime[4] + 1)."/".(@DateTime[5] + 1900);

print $DateAndTime."\n";

@DateRequired = $DateAndTime;

$Filter = $qryDef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
$Filter->BuildFilter("state", $CQPerlExt::CQ_COMP_OP_EQ,\@StateRequired);
$Filter->BuildFilter("Target_Completion", $CQPerlExt::CQ_COMP_OP_LTE, \@DateRequired); 
$resultSet = $session->BuildResultSet($qryDef);

$resultSet->Execute();

$status = $resultSet->MoveNext();
while ($status == $CQPerlExt::CQ_SUCCESS) 
{
	printf("Action : %s %s %s\n", $resultSet->GetColumnValue(1), $resultSet->GetColumnValue(2), $resultSet->GetColumnValue(3));	
			
	$EntityObject = $session->GetEntity("Action", $resultSet->GetColumnValue(1));
	$session->EditEntity($EntityObject, "Overdue");

	$ValidationResult = $EntityObject->Validate();
	if (length($ValidationResult) != 0)
	{
		print $ValidationResult."\n";
	}
	else
	{
		$EntityObject->Commit();
		print "changed state to overdue\n";
	}

	$status = $resultSet->MoveNext();
}

# This is necessary for a clean shutdown otherwise you get an error.
CQSession::Unbuild($session);

