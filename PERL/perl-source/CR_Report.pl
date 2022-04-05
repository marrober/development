use CQPerlExt;

# Generate list of ClearCase activities to cross check.

$ClearToolLsActShortCmd = "cleartool lsact -s";
$LsActShortResult = `$ClearToolLsActShortCmd`;
@LsActLines = split("\n", $LsActShortResult);
foreach $Activity (@LsActLines) {
	push(@CC_Activities, $Activity);
	print $Activity."\n";
}

$session = CQSession::Build();
$session->UserLogon("admin", "", "DVLA", "");

$qryDef = $session->BuildQuery("ChangeRequest");
$qryDef->BuildField("id");
$qryDef->BuildField("state");
$qryDef->BuildField("Title");

$Filter = $qryDef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
@Dummy = "dummy";
$Filter->BuildFilter("ParentCR", $CQPerlExt::CQ_COMP_OP_IS_NULL, \@Dummy);

$QueryFieldDefs = $qryDef->GetQueryFieldDefs();
$IDField = $QueryFieldDefs->ItemByName("id"); 
$IDField->SetSortType($CQPerlExt::CQ_SORT_DESC); 
$IDField->SetSortOrder(1);

$resultSet = $session->BuildResultSet($qryDef);
$resultSet->Execute();
$numCol = $resultSet->GetNumberOfColumns();
$status = $resultSet->MoveNext();
@Records = "";
$Level = 0;
while ($status == $CQPerlExt::CQ_SUCCESS) {

	print $resultSet->GetColumnValue(1)." | ".$resultSet->GetColumnValue(2)." | ".$resultSet->GetColumnValue(3)."\n";
	GetChild_CR_Records($resultSet->GetColumnValue(1));

	$status = $resultSet->MoveNext();
}

CQSession::Unbuild($session);

sub GetChild_CR_Records {
	my ($Parent) = @_;
	my ($Counter) = 0;
	my (@ChildRecords) = "";

	$ChangeRecordToProcess = $session->GetEntity("ChangeRequest", $Parent);
	push(@Records, $Parent);
	
	GetChild_Activity_Records($ChangeRecordToProcess);
	if ($ChangeRecordToProcess->GetFieldValue("ChildCRs")->GetValueStatus() == $CQPerlExt::CQ_HAS_VALUE) {
		$ChildRecordList = $ChangeRecordToProcess->GetFieldValue("ChildCRs")->GetValue();
		@ChildRecords = split("\n", $ChildRecordList);
		$Level++;

		foreach $ChildRecord (@ChildRecords) {
			$ChildEntity = $session->GetEntity("ChangeRequest", $ChildRecord);
			TabLevel($Level);
			print "Child CR : ".$ChildEntity->GetFieldValue("id")->GetValue()." | ";
			print $ChildEntity->GetFieldValue("Title")->GetValue()."\n";
			GetChild_CR_Records($ChildRecord);
		}
		$Level--;
	}
	else {
		
		return();
	}
	return();

}

sub GetChild_Activity_Records {
	my ($Parent) = @_;

	if ($Parent->GetFieldValue("Defects")->GetValueStatus() == $CQPerlExt::CQ_HAS_VALUE) {
		$ActivityList = $Parent->GetFieldValue("Defects")->GetValue();
		@Activities = split("\n", $ActivityList);
		$Level++;
		
		foreach $Activity (@Activities) {
			$ActivityRecordToProcess = $session->GetEntity("Defect", $Activity);
			if ($ActivityRecordToProcess->GetFieldValue("ucm_project")->GetValueStatus() == $CQPerlExt::CQ_HAS_VALUE) {
				TabLevel($Level);
				$CurrentActivity = $ActivityRecordToProcess->GetFieldValue("id")->GetValue();
				print "Activity : ".$CurrentActivity." | ";
				print $ActivityRecordToProcess->GetFieldValue("ucm_project")->GetValue()."\n";
				$Found = 0;
				foreach $_ (@CC_Activities) {
					if (m/$CurrentActivity/) {
						$Found = 1;
					}
				}
				if ($Found == 1) {
					$ClearToolLsActCmd = "cleartool lsact -l ".$ActivityRecordToProcess->GetFieldValue("id")->GetValue();
					$LsActResult = `$ClearToolLsActCmd`;
					@LsActLines = split("\n", $LsActResult);
					$Capture = 0;
					$ChangeSetText = "";
					foreach $_ (@LsActLines) {
						if (m/clearquest record id/) {
							$Capture = 0;
						}
						if ($Capture == 1) {
							$_ = substr($_, 0, index($_, "@"));
							$ChangeSetText .= TabInsert($Level).$_."\n";
						}
						if (m/change set versions/) {
							$Capture = 1;
						}
					}
					print $ChangeSetText;
				}
			}
		}
		$Level--;
	}
	else {
		
		return();	
	}
	return();
}

sub TabLevel {
	my ($Level) = @_;			

	for ($TabCounter = 0; $TabCounter < $Level; $TabCounter++) {
		print "\t";
	}

}

sub TabInsert {
	my ($Level) = @_;			

	$TabText = "";
	for ($TabCounter = 0; $TabCounter < $Level; $TabCounter++) {
		$TabText .= "\t";
	}

	return($TabText);
}
