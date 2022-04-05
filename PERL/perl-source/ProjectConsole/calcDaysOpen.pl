use PjCLib;
use Win32::OLE;
require CQPerlExt;

$Debug = 0;

$CurrentDate = getCurrentDate();

$session = logon();
print "logged in ...\n";

Main();
exit;

sub Main {

    PjCLib->initializePjCLibrary($session, PjCLib->BOOLEAN_TRUE);
	print "Collect data ...\n";

	($CQ_measure_Tab, $CQ_measure_Field) = split("\,", GetFieldInternalNameAndTable("defect_count", "defect"));

	($Defect_Id_fk_Tab, $Defect_Id_fk_Field) = split("\,", GetFieldInternalNameAndTable("id_fk", "defect"));
	($Defect_Id_Tab, $Defect_Id_Field) = split("\,", GetFieldInternalNameAndTable("id", "id_dim"));
	($Defect_Headline_fk_Tab, $Defect_Headline_fk_Field) = split("\,", GetFieldInternalNameAndTable("headline_fk", "defect"));
	($Defect_Headline_Tab, $Defect_Headline_Field) = split("\,", GetFieldInternalNameAndTable("headline", "headline_dim"));
	($Defect_ActualStart_fk_Tab, $Defect_ActualStart_fk_Field) = split("\,", GetFieldInternalNameAndTable("ActualStart_fk", "defect"));
	($Defect_ActualStart_Tab, $Defect_ActualStart_Field) = split("\,", GetFieldInternalNameAndTable("ActualStart_name", "ActualStart"));
	($Defect_ActualFinish_fk_Tab, $Defect_ActualFinish_fk_Field) = split("\,", GetFieldInternalNameAndTable("ActualFinish_fk", "defect"));
	($Defect_ActualFinish_Tab, $Defect_ActualFinish_Field) = split("\,", GetFieldInternalNameAndTable("ActualFinish_name", "ActualFinish"));

	($Defect_ElapseTime_fk_Tab, $Defect_ElapseTime_fk_Field) = split("\,", GetFieldInternalNameAndTable("elapsetime_fk", "defect"));
	($Defect_ElapseTime_Tab, $Defect_ElapseTime_Field) = split("\,", GetFieldInternalNameAndTable("ElapseTime", "ElapseTime_Dim"));

	$DayNumber = GetDayNumber($CurrentDate);

    $QryString = "Select * from $CQ_measure_Tab";
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
            if (lc($ResultSetObj->GetColumnLabel($Counter)) eq lc($Defect_Id_fk_Field))
            {
				$Id = GetData($Defect_Id_Field, $Defect_Id_Tab, $ResultSetObj->GetColumnValue($Counter));
			}
            if (lc($ResultSetObj->GetColumnLabel($Counter)) eq lc($Defect_Headline_fk_Field))
            {
				$Headline = GetData($Defect_Headline_Field, $Defect_Headline_Tab, $ResultSetObj->GetColumnValue($Counter));
			}
            if (lc($ResultSetObj->GetColumnLabel($Counter)) eq lc($Defect_ActualStart_fk_Field))
            {
				$ActualStart = GetData($Defect_ActualStart_Field, $Defect_ActualStart_Tab, $ResultSetObj->GetColumnValue($Counter));
			}
            if (lc($ResultSetObj->GetColumnLabel($Counter)) eq lc($Defect_ActualFinish_fk_Field))
            {
				$ActualFinish = GetData($Defect_ActualFinish_Field, $Defect_ActualFinish_Tab, $ResultSetObj->GetColumnValue($Counter));
			}

		}
		
		$DayDiff = GetDayNumber($ActualFinish) - GetDayNumber($ActualStart);
		print $Id." .... ".$Headline." .... ".$ActualStart." .... ".$ActualFinish."  ".$DayDiff."\n";

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
            if ($FieldResultSetObj->GetColumnLabel($Counter) eq "default_display_name_1") 	{	$FieldDisplayName = $FieldResultSetObj->GetColumnValue($Counter); }
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
	if ($Debug > 5) { print "Table name : ".$TableName."    Field name : ".$FieldName."\n"; }
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
