use CQPerlExt;

$UserName = @ARGV[0];
$Password = @ARGV[1];
$PerforceCSID = @ARGV[2];

$CQDB = "CQPRF";
$CQDBSet = "050";

# Get Perforce information about the change set.
$P4DescribeCommand = "p4 describe ".$PerforceCSID;
@P4DescResult = split("\n", `$P4DescribeCommand`);

$RecordFlag = 0;
$LineCounter = 1;
foreach $_ (@P4DescResult) {
	if ($LineCounter == 1) {
		@Line1 = split(" ", $_);
		$ChangeSetNumber = @Line1[1];
		$P4UserAndMachine = @Line1[3];
		$DateAndTime = @Line1[5]." ".@Line1[6];
		$Line1Processed = 1;
	}
	if ($LineCounter == 3) {
		$CommentString = $_;
		$CommentString =~ s/^\t//;
		if (index($CommentString, " ") > 0) {
			$CQID = substr($CommentString, 0, index($CommentString, " "));
		}
		else {
			$CQID = $CommentString;
		}
	}		
	if (m/Differences .../) {
		$RecordFlag = 0;
	}
	if ($RecordFlag == 1) {
		$_ =~ s/^... //g;
		if (length($_) > 0) {
			push (@FileList, $_);	
		}
	}
	if (m/Affected files .../) {
		$RecordFlag = 1;
	}
	$LineCounter++;
}

$IDLength = length($CQID);
for ($Counter = 1; $Counter <= (8 - $IDLength); $Counter++) {
	$CQID = "0".$CQID;
}
$CQID = $CQDB.$CQID;

print $CQID."\n";

foreach $FileToProcess (@FileList) {
	print $FileToProcess."\n";
}

$session = CQSession::Build();
$session->UserLogon($UserName, $Password, $CQDB, $CQDBSet);

$qryDef = $session->BuildQuery("Defect");
$qryDef->BuildField("id");
$qryDef->BuildField("Headline");
$qryDef->BuildField("State");
$qryDef->BuildField("Owner");

push(@CQIDArray, $CQID);
$Filter = $qryDef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
$Filter->BuildFilter("id", $CQPerlExt::CQ_COMP_OP_EQ, \@CQIDArray);

$resultSet = $session->BuildResultSet($qryDef);

$resultSet->Execute();
$numCol = $resultSet->GetNumberOfColumns();
$status = $resultSet->MoveNext();

if ($status == $CQPerlExt::CQ_SUCCESS) {
	# Validate that this record is in the right state and open for the right person.
	# Then perform the record edit and update the PerforceRecords field.
	
	$RecordState = $resultSet->GetColumnValue(3);
	$RecordOwner = $resultSet->GetColumnValue(4);
	
	if ((($RecordState cmp "Opened") ==0) && (($RecordOwner cmp $UserName) == 0)) {
		print "modify record\n";
		# Modify record.
		$EntityObject = $session->GetEntity("Defect", $CQID);			
		$session->EditEntity($EntityObject, "Modify");
		$PerforceRecordValue =  "Perforce user information   : ".$P4UserAndMachine."\n";
		$PerforceRecordValue .= "Perforce change set number  : ".$ChangeSetNumber."\n";
		$PerforceRecordValue .= "Perforce action date & time : ".$DateAndTime."\n";
		foreach $FileToProcess (@FileList) {
			$PerforceRecordValue .= $FileToProcess."\n";
		}
		$PerforceRecordValue .= "--------------------------------------------\n";
		$PerforceRecordValue .= $EntityObject->GetFieldValue("PerforceRecords")->GetValue();
		$EntityObject->SetFieldValue("PerforceRecords", $PerforceRecordValue);
		$ValidationResult = $EntityObject->Validate();
		if (length($ValidationResult) != 0)
		{
			print $ValidationResult."\n";
			exit(1);
		}
		else
		{
			$EntityObject->Commit();
			print "Modify completed successfully\n";
		}
	}
	else {
		if (($RecordState cmp "Opened") != 0) {
			print "Record is not in the opened state\n";
		}
		if (($RecordOwner cmp $UserName) != 0) {
			print "Record owner and the Perforce action user don't match\n";
			print "Record owner is  : ".$RecordOwner."\n";
			print "Perforce user is : ".$UserName."\n";
		}
	}	
}
elsif ($status == $CQPerlExt::CQ_NO_DATA_FOUND) {
	print "Record not found\n";
	exit(1);
}
else {
	# Unknown error.	
	print "Unknown error\n";
	exit(1);
}

exit(0);





