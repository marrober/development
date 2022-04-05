use CQPerlExt;

$session = CQSession::Build();
$session->UserLogon("admin", "rational", "didb", "");

$qryDef = $session->BuildQuery("TaskCard");
$qryDef->BuildField("id");
$qryDef->BuildField("headline");
$qryDef->BuildField("state");
$qryDef->BuildField("record_type");
$qryDef->BuildField("DateCompleted");

push (@StateList, "Submitted");
push (@StateList, "Open");
push (@StateList, "Active");
push (@StateList, "Withdrawn");
push (@StateList, "Completed");

push(@States, "Completed");

push (@Dates, "1-06-2003");
push (@Dates, "1-07-2003");
push (@Dates, "1-08-2003");
push (@Dates, "1-09-2003");
push (@Dates, "1-10-2003");
push (@Dates, "1-11-2003");
push (@Dates, "1-12-2003");
push (@Dates, "1-13-2003");
push (@Dates, "1-14-2003");
push (@Dates, "1-15-2003");
push (@Dates, "1-16-2003");
push (@Dates, "1-17-2003");
push (@Dates, "1-18-2003");
push (@Dates, "1-19-2003");
push (@Dates, "1-20-2003");
push (@Dates, "1-21-2003");
push (@Dates, "1-22-2003");
push (@Dates, "1-23-2003");
push (@Dates, "1-24-2003");
push (@Dates, "1-25-2003");
push (@Dates, "1-26-2003");
push (@Dates, "1-27-2003");
push (@Dates, "1-28-2003");
push (@Dates, "1-29-2003");
push (@Dates, "1-30-2003");
push (@Dates, "1-31-2003");
push (@Dates, "2-01-2003");
push (@Dates, "2-02-2003");
push (@Dates, "2-03-2003");
push (@Dates, "2-04-2003");
push (@Dates, "2-05-2003");
push (@Dates, "2-06-2003");
push (@Dates, "2-07-2003");
push (@Dates, "2-08-2003");
push (@Dates, "2-09-2003");
push (@Dates, "2-10-2003");
push (@Dates, "2-11-2003");
push (@Dates, "2-12-2003");
push (@Dates, "2-13-2003");
push (@Dates, "2-14-2003");
push (@Dates, "2-15-2003");
push (@Dates, "2-16-2003");
push (@Dates, "2-17-2003");
push (@Dates, "2-18-2003");
push (@Dates, "2-19-2003");
push (@Dates, "2-20-2003");
push (@Dates, "2-21-2003");
push (@Dates, "2-22-2003");
push (@Dates, "2-23-2003");
push (@Dates, "2-24-2003");
push (@Dates, "2-25-2003");
push (@Dates, "2-26-2003");
push (@Dates, "2-27-2003");
push (@Dates, "2-28-2003");
$PreviousDate = "";

for $DateRequired (@Dates)
{
    push (@DateRange, $DateRequired);
    push (@DateRange, $DateRequired);

    for $StateRequired (@StateList)
    {
        push (@State, $StateRequired);

        my $Filter = $qryDef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);

        $FilterStateName = "Date".$StateRequired;
        if ($StateRequired eq "Open")
        {
            $FilterStateName .= "ed";
        }
        $Filter->BuildFilter($FilterStateName, $CQPerlExt::CQ_COMP_OP_BETWEEN, \@DateRange);

        $resultSet = $session->BuildResultSet($qryDef);

        ListResultSet($resultSet);
        if ($PreviousDate ne "")
        {
            $Behaviour{$DateRequired}{@State[0]} = $Counter + $Behaviour{$PreviousDate}{@State[0]};
        }
        else
        {
            $Behaviour{$DateRequired}{@State[0]} = $Counter;
        }

        pop (@State);
    }
    pop (@DateRange);
    pop (@DateRange);
    $PreviousDate = $DateRequired;
}
CQSession::Unbuild($session);

foreach $Key (sort keys(%Behaviour))
{
    print $Key.",".$Behaviour{$Key}{"Submitted"}.",".$Behaviour{$Key}{"Open"}.",".$Behaviour{$Key}{"Active"}.",".$Behaviour{$Key}{"Withdrawn"}.",".$Behaviour{$Key}{"Completed"}."\n";
}



sub ListResultSet {
	my ($resultSet) = @_;

	$resultSet->Execute();
	$numCol = $resultSet->GetNumberOfColumns();
    $status = $resultSet->MoveNext();
    $Counter = 0;
	while ($status == $CQPerlExt::CQ_SUCCESS) {

        push (@Data, $resultSet->GetColumnValue(1)."|".$resultSet->GetColumnValue(5)."|".$resultSet->GetColumnValue(3)."|".$resultSet->GetColumnValue(4));
		$status = $resultSet->MoveNext();
        $Counter += 1;
	}
}
