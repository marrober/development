use CQPerlExt;
use Win32::OLE;

$Session = CQPerlExt::CQSession_Build();
$Session->UserLogon("admin", "rational", "cqdb", "");

$ProjectVob = "\\project";

$CC = Win32::OLE->new('ClearCase.Application');

$ProjectVOBObject = $CC->VOB("$ProjectVob");

$QueryObj = $Session->BuildQuery("TaskCard");
$QueryObj->BuildField("id");
$ResultSet = $Session->BuildResultSet($QueryObj);

$ResultSet->Execute();

$Status = $ResultSet->MoveNext();

while ($Status == $CQPerlExt::CQ_SUCCESS)
{
    $Status = $ResultSet->MoveNext();

    $EntityObject = $Session->GetEntity("TaskCard", $ResultSet->GetColumnValue(1));

    print "ID : ".$EntityObject->GetFieldValue("id")->GetValue()."\n";
    print "Headline : ".$EntityObject->GetFieldValue("Headline")->GetValue()."\n";

    $Programmer1LogonID = $EntityObject->GetFieldValue("DevPair_1")->GetValue();
    $Programmer1Entity = $Session->GetEntity("users", $Programmer1LogonID);

    $Programmer2LogonID = $EntityObject->GetFieldValue("DevPair_2")->GetValue();
    $Programmer2Entity = $Session->GetEntity("users", $Programmer2LogonID);

    if ($Programmer1LogonID ne $Programmer2LogonID) 
    {
        print "Programmers : ".$Programmer1Entity->GetFieldValue("fullname")->GetValue()." and ";
        print $Programmer2Entity->GetFieldValue("fullname")->GetValue()."\n";
    }
    else
    {
        print "Programmer : ".$Programmer1Entity->GetFieldValue("fullname")->GetValue()."\n";
    }

    $ActivityObject = $ProjectVOBObject->Activity($ResultSet->GetColumnValue(1));

    


    print "---------------------------------------------------------------------\n";
}


exit(0);


