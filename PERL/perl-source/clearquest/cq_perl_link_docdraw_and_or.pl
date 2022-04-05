
# Link docdraw stateless records with OR's.

use CQPerlExt;

$session = CQSession::Build();
$session->UserLogon("admin", "", "cog", "2003.06.00");


$qryDef1 = $session->BuildQuery("DocDrawPart");
$qryDef1->BuildField("dbid");
$qryDef1->BuildField("Original_ORNumber");

my $Filter1 = $qryDef1->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);

@Blank = "blank";

$Filter1->BuildFilter("ORs", $CQPerlExt::CQ_COMP_OP_IS_NULL, \@Blank);

$resultSet1 = $session->BuildResultSet($qryDef1);

$resultSet1->Execute();
$status1 = $resultSet1->MoveNext();

while ($status1 == $CQPerlExt::CQ_SUCCESS) {
	print $resultSet1->GetColumnValue(1)."    ".$resultSet1->GetColumnValue(2)."\n";
	$OriginalORNumber = $resultSet1->GetColumnValue(2);
	$DocDrawID = $resultSet1->GetColumnValue(1);

	$qryDef2 = $session->BuildQuery("OR");
	$qryDef2->BuildField("id");

	my $Filter2 = $qryDef2->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);

	@Value = $OriginalORNumber;

	$Filter2->BuildFilter("ORNumber", $CQPerlExt::CQ_COMP_OP_EQ, \@Value);

	$resultSet2 = $session->BuildResultSet($qryDef2);

	$resultSet2->Execute();
	$status2 = $resultSet2->MoveNext();

	if ($status2 == $CQPerlExt::CQ_SUCCESS)
	{
		print "Link OR   ".$resultSet2->GetColumnValue(1)."\n";

		$OREntity = $session->GetEntity("OR", $resultSet2->GetColumnValue(1));

		$session->EditEntity($OREntity, "Modify");

		$OREntity->SetFieldValue("DocDrawPart", $DocDrawID);

		$ValidationResult = $OREntity->Validate();
		
		if (length($ValidationResult) != 0)
		{
			print $ValidationResult."\n";
		}
		else
		{
			$OREntity->Commit();
		}		
	}

	$status1 = $resultSet1->MoveNext();
}


# This is necessary for a clean shutdown otherwise you get an error.
CQSession::Unbuild($session);


