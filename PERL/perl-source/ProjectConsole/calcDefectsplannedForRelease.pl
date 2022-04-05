use PjCLib;
use Win32::OLE;
require CQPerlExt;

$Debug = 5;

$CurrentDate = getCurrentDate();

$session = logon();
print "logged in ...\n";

Main();
exit;

sub Main {

    PjCLib->initializePjCLibrary($session, PjCLib->BOOLEAN_TRUE);
	print "Collect data ...\n";

	($CQ_defect_rel_ag_Tab, $CQ_defect_rel_count_Field) = split("\,", GetFieldInternalNameAndTable("count", "defect_rel_agregate_me"));

	($Defect_rel_fk_Tab, $Defect_rel_fk_Field) = split("\,", GetFieldInternalNameAndTable("release_fk", "defect_rel_agregate_me"));
	($Defect_coll_date_fk_Tab, $Defect_coll_date_fk_Field) = split("\,", GetFieldInternalNameAndTable("collectiondate_fk", "defect_rel_agregate_me"));

	$DayNumber = GetDayNumber($CurrentDate);

    $QryString = "Select * from $CQ_defect_rel_ag_Tab";
	my $ResultSetObj = $session->BuildSQLQuery($QryString);
	$ResultSetObj->EnableRecordCount();
	$ResultSetObj->Execute();
	print " Record Count : ".$ResultSetObj->GetRecordCount()."\n";
	$NumColumns = $ResultSetObj->GetNumberOfColumns();
    print " Column Count : ".$NumColumns."\n";
    $ResultSetObj->MoveNext();
    while ($ResultSetObj->MoveNext() == $CQPerlExt::CQ_SUCCESS)
	{
		for ($Counter = 1; $Counter <= $NumColumns; $Counter++)
 		{
            if (lc($ResultSetObj->GetColumnLabel($Counter)) eq lc($Defect_rel_fk_Field))
            {
				$DefectRelease = GetData($Defect_rel_fk_Field, $Defect_Id_Tab, $ResultSetObj->GetColumnValue($Counter));
			}
            if (lc($ResultSetObj->GetColumnLabel($Counter)) eq lc($Defect_coll_date_fk_Field))
            {
				$DefectCollDate = GetData($Defect_coll_date_Field, $Defect_coll_date_Tab, $ResultSetObj->GetColumnValue($Counter));
			}
		}		
	}

	GetReleaseList();

	foreach $Release (@TargetReleases)
	{
		$NumForRelease = GetReleaseTargetCount($Release);
		print "number for release : ".$Release." : ".$NumForRelease."\n";
	}
} 


sub logon {
    my $session = Win32::OLE->new('CLEARQUEST.SESSION');
    my $session = CQPerlExt::CQSession_Build();
    $session->UserLogon("dashboardsystem", "dashboardsystem", "TstD1", "Dashboard");
    return $session;
}

sub getCurrentDate {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my ($CurrentDate) = "";

    $mon = $mon + 1;
    $year = $year + 1900;

    if ($mday<10) {$mday="0$mday"; }
    if ($mon<10) {$mon="0$mon"; }

    $CurrentDate="$year-$mon-$mday";

	return ($CurrentDate);
}

sub GetFieldName {
	my($FieldNameRequired) = @_;
    $FieldNameQry = "Select name from dbm_field where default_display_name_1 = '$FieldNameRequired'";
	my $FieldResultSetObj = $session->BuildSQLQuery($FieldNameQry);
	$FieldResultSetObj->Execute();
	$NumColumns = $FieldResultSetObj->GetNumberOfColumns();
	if ($FieldResultSetObj->MoveNext() == $CQPerlExt::CQ_SUCCESS)
	{
		return $FieldResultSetObj->GetColumnValue(1);
	}
	else
	{
		return("Error !!");
	}
}

sub GetAllFieldNames {
    $FieldNameQry = "Select name,default_display_name_1,table_fk from dbm_field";
	my $FieldResultSetObj = $session->BuildSQLQuery($FieldNameQry);
	$FieldResultSetObj->Execute();
	$NumColumns = $FieldResultSetObj->GetNumberOfColumns();
    while ($FieldResultSetObj->MoveNext() == $CQPerlExt::CQ_SUCCESS)
	{
        for ($Counter = 1; $Counter <= $NumColumns; $Counter++)
		{
            if ($FieldResultSetObj->GetColumnLabel($Counter) eq "table_fk") 				{ $TableRef = $FieldResultSetObj->GetColumnValue($Counter); }
            if ($FieldResultSetObj->GetColumnLabel($Counter) eq "default_display_name_1") 	{ $FieldDisplayName = $FieldResultSetObj->GetColumnValue($Counter); }
            if ($FieldResultSetObj->GetColumnLabel($Counter) eq "name") 				  	{ $FieldName = $FieldResultSetObj->GetColumnValue($Counter); }
        }
        $TableNameQry = "Select default_display_name_1 from dbm_table where dbid=$TableRef";
        my $TableResultSetObj = $session->BuildSQLQuery($TableNameQry);
        $TableResultSetObj->Execute();
        if ($TableResultSetObj->MoveNext() == $CQPerlExt::CQ_SUCCESS)
        {
            $TableName = $TableResultSetObj->GetColumnValue(1);
        }
        print "Table : ".$TableName."\tField name : ".$FieldName."\tField Display Name : ".$FieldDisplayName."\n";
	}
}

sub GetFieldInternalNameAndTable {
	my($DisplayName) = "";
	my($RequiredTable) = "";
	($DisplayName, $RequiredTable) = @_;
	my($FieldNameQry) = "";
	my($FieldResultSetObj) = "";
	my($NumColumns) = "";
	my($Counter) = "";
	my($TableRef) = "";
	my($FieldName) = "Error !!";
	my($TableNameQry) = "";
	my($TableResultSetObj) = "";
	my($TableName) = "Error !!";
	my($TableNameTemp) = "";
	my($FieldNameTemp) = "";

	if ($Debug > 5) { print "Display name : ".$DisplayName."\n";}

    $FieldNameQry = "Select name,table_fk,default_display_name_1 from dbm_field where default_display_name_1='$DisplayName'";
	if ($Debug > 5) { print $FieldNameQry."\n";}
	my $FieldResultSetObj = $session->BuildSQLQuery($FieldNameQry);
	$FieldResultSetObj->Execute();
	$NumColumns = $FieldResultSetObj->GetNumberOfColumns();
    while ($FieldResultSetObj->MoveNext() == $CQPerlExt::CQ_SUCCESS)
	{
		if ($Debug > 5) { print $FieldResultSetObj->GetColumnValue(1)."\n";}
		if ($Debug > 5) { print $FieldResultSetObj->GetColumnValue(2)."\n";}
		if ($Debug > 5) { print $FieldResultSetObj->GetColumnValue(3)."\n";}
		if ($DisplayName eq $FieldResultSetObj->GetColumnValue(3)) 
		{
			if ($Debug > 5) { print "Required table found ...\n";}
	        for ($Counter = 1; $Counter <= $NumColumns; $Counter++)
			{
	            if ($FieldResultSetObj->GetColumnLabel($Counter) eq "table_fk") 				{ $TableRef = $FieldResultSetObj->GetColumnValue($Counter); }
	            if ($FieldResultSetObj->GetColumnLabel($Counter) eq "name") 				  	{ $FieldNameTemp = $FieldResultSetObj->GetColumnValue($Counter); }
				if ($Debug > 5) { print $TableRef." , ".$FieldNameTemp."\n";}
	        }
	        $TableNameQry = "Select name from dbm_table where dbid=$TableRef";
	        my $TableResultSetObj = $session->BuildSQLQuery($TableNameQry);
	        $TableResultSetObj->Execute();
	        if ($TableResultSetObj->MoveNext() == $CQPerlExt::CQ_SUCCESS)
	        {
	            $TableNameTemp = $TableResultSetObj->GetColumnValue(1);
	        }
			if ($TableNameTemp eq $RequiredTable)
			{
				$TableName = $TableNameTemp;
				$FieldName = $FieldNameTemp;
			}	
		}
	}
	if ($Debug > 4) { print "Table name : ".$TableName."    Field name : ".$FieldName."\n"; }
	return $TableName.",".$FieldName;
}

sub GetData {
	my ($FieldName, $TableName, $DbIdRef) = @_;
	my ($FieldQryString) = "";
	my ($FieldResultSetObj) = "";
	my ($ReturnVal) = "";
	
	$FieldQryString = "Select $FieldName from $TableName where dbid='$DbIdRef'";
	my $FieldResultSetObj = $session->BuildSQLQuery($FieldQryString);
	$FieldResultSetObj->EnableRecordCount();
	$FieldResultSetObj->Execute();
    if ($FieldResultSetObj->MoveNext() == $CQPerlExt::CQ_SUCCESS)
	{
		$ReturnVal = $FieldResultSetObj->GetColumnValue(1);
	}
	else
	{
		$ReturnVal = "NotFound!!";
	}
	return ($ReturnVal);
}


sub GetDayNumber {
	my ($CurrentDate) = @_;
	my ($CQ_Submit_Date_Table) = "";
	my ($CQ_Submit_Date_Field) = "";
	my ($CQ_Submit_Date_Daynum_Field) = "";

	($CQ_Submit_Date_Table, $CQ_Submit_Date_Field) = split("\,", GetFieldInternalNameAndTable("SubmitDate_name", "SubmitDate"));
	($CQ_Submit_Date_Table, $CQ_Submit_Date_Daynum_Field) = split("\,", GetFieldInternalNameAndTable("SubmitDate_daynum", "SubmitDate"));

	$QryString = "Select ".$CQ_Submit_Date_Daynum_Field." from ".$CQ_Submit_Date_Table." where ".$CQ_Submit_Date_Field."='".$CurrentDate."'";
	my $ResultSetObj = $session->BuildSQLQuery($QryString);
	$ResultSetObj->Execute();
	if ($ResultSetObj->MoveNext() == $CQPerlExt::CQ_SUCCESS)
	{
		return($ResultSetObj->GetColumnValue(1));
	}
	else
	{
		return("Error !!");
	}
}

sub GetReleaseList 
{
	my($DefectSession) = "";

	$DefectSession = CQSession::Build();
	$DefectSession->UserLogon("admin", "", "CLSIC", "CLSIC");
	$qryDef = $DefectSession->BuildQuery("Defect");
	$qryDef->BuildField("Target_Release");

	$resultSet = $DefectSession->BuildResultSet($qryDef);

	$resultSet->Execute();

	@TargetReleases = "";

	while ($resultSet->MoveNext() == $CQPerlExt::CQ_SUCCESS)
	{
		$TargetName = $resultSet->GetColumnValue(1);
		$Found = 0;
		foreach $_ (@TargetReleases)
		{
			if ($_ eq $TargetName) { $Found = 1; }
		}
		if ($Found == 0) { push (@TargetReleases, $TargetName);	}
	}

	print "Releases .... \n";

	foreach $_ (@TargetReleases)
	{
		print $_."\n";
	}

	print $NumRecords."\n";
	CQSession::Unbuild($DefectSession);
}

sub GetReleaseTargetCount
{
	my($Release) = @_;

	$DefectSession = CQSession::Build();
	$DefectSession->UserLogon("admin", "", "CLSIC", "CLSIC");
	$qryDef = $DefectSession->BuildQuery("Defect");
	$qryDef->BuildField("ID");

	push(@Target_ReleaseFilter, $Release);

	my $Filter = $qryDef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);
	$Filter->BuildFilter("Target_Release", $CQPerlExt::CQ_COMP_OP_EQ, \@Target_ReleaseFilter);

	$resultSet = $DefectSession->BuildResultSet($qryDef);
	printf("SQL = %s\n", $resultSet->GetSQL());

	$Num = GetCQQryResultCount($resultSet);
	pop(@Target_ReleaseFilter);
	CQSession::Unbuild($DefectSession);
	return ($Num);
}

sub GetCQQryResultCount 
{
	my ($resultSet) = @_;
	
	$resultSet->EnableRecordCount();
	$resultSet->Execute();

	$ResultSetCount = $resultSet->GetRecordCount();	

	while ($resultSet->MoveNext() == $CQPerlExt::CQ_SUCCESS)
	{
		print  $resultSet->GetColumnValue(1)."\n";		
	}
	return($ResultSetCount);
}


