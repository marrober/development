# HTML TAGS !!

$StartTime = time;
use CQPerlExt;
use Win32::OLE;

$Session = CQPerlExt::CQSession_Build();
$Session->UserLogon("admin", "", "CLSIC", "2002.05.00");

$ProjectVob = "\\Classics";

$CC = Win32::OLE->new('ClearCase.Application');

$ProjectVOBObject = $CC->VOB("$ProjectVob");

$GetActivityListCmd = "cleartool lsact -s -invob ".$ProjectVOBObject->TagName;
$ActivityInVobList = `$GetActivityListCmd`;
@ActivityArray = split("\n", $ActivityInVobList);

GetChangeSetData("Defect");
GetChangeSetData("UCMUtilityActivity");
GetChangeSetData("EnhancementRequest");
$EndTime = time;
print "Elapsed time : ".($EndTime - $StartTime)."\n";
exit(0);


sub GetChangeSetData
{
    my($RecordType) = @_;

    $QueryObj = $Session->BuildQuery($RecordType);
    $QueryObj->BuildField("id");
    $ResultSet = $Session->BuildResultSet($QueryObj);

    $ResultSet->Execute();

    $Status = $ResultSet->MoveNext();

    while ($Status == $CQPerlExt::CQ_SUCCESS)
    {
        $EntityObject = $Session->GetEntity($RecordType, $ResultSet->GetColumnValue(1));
        $_ = $EntityObject->GetFieldValue("id")->GetValue();
        $Found = FALSE;
        foreach $Activity (@ActivityArray)
        {
            if (m/$Activity/)
            {
                $Found = TRUE;
            }
        }

        if ($Found eq TRUE)
        {
            print "ID : ".$EntityObject->GetFieldValue("id")->GetValue()."\n";
            print "Headline : ".$EntityObject->GetFieldValue("Headline")->GetValue()."\n";

            $LSActCmd = 'cleartool lsact -fmt "%[versions]p" '.$EntityObject->GetFieldValue("id")->GetValue()."@".$ProjectVOBObject->TagName;
            $_ = `$LSActCmd`;
            if (m/activity not found/)
            {
                print "No change set\n";
            }
            else
            {
                @NamesOnly = "";
                pop(@NamesOnly);
                foreach $key (keys %ElementCount)
                {
                    delete $ElementCount{$key};
                }

                @SplitChangeSet = split(" ", $_);

                foreach $ChangeSetItem (@SplitChangeSet)
                {
                    @NameVerSplit = split("@@", $ChangeSetItem);
                    push (@NamesOnly, @NameVerSplit[0]);
                }

                for $Name (@NamesOnly)
                {
                    $Count = 0;
                    for $NamesTwo (@NamesOnly)
                    {
                        if ($Name eq $NamesTwo)
                        {
                            $Count++;
                        }
                    }
                    $ElementCount{$Name} = $Count;
                }
                @Keys = keys %ElementCount;

                print "Total in change set ".($#NamesOnly + 1);
                print "  Unique items ".($#Keys + 1)."\n";

                foreach $ChangeSetItem (sort @SplitChangeSet)
                {
                    print $ChangeSetItem;
                    if ($ElementCount{substr($ChangeSetItem, 0, index($ChangeSetItem, "@"))} > 1)
                    {
                        print " [multiple]\n";
                    }
                    else
                    {
                        print "\n";
                    }
                    # Get the file description for this item.
                    $ItemDescribeCmd = 'cleartool desc -fmt "%c" '.$ChangeSetItem;
                    $ItemDescription = `$ItemDescribeCmd`;
                    if (length($ItemDescription) > 0)
                    {
                        print $ItemDescription."\n";
                    }
                }
            }

            print "---------------------------------------------------------------------\n";
        }
        $Status = $ResultSet->MoveNext();
    }
}

sub ClearToolFn
{
    my ($Cmd) = @_;

    $Cmd = "cleartool

    return(`$Cmd`);
}

