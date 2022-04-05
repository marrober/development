use CQPerlExt;
use Win32::OLE;

my $PVobTag = $ARGV[0];
my $OutputFile = ">".$ARGV[1];

my $CC = Win32::OLE->new('ClearCase.Application');

# Get a list of all projects in the project VOB.

my $ProjectVobInstance = $CC->ProjectVob($PVobTag);

my $Projects = $ProjectVobInstance->Projects();

my $ProjectsEnum = Win32::OLE::Enum->new($Projects);

open OUTFILE, $OutputFile;

$ProjectList = "";

while (defined(my $Project = $ProjectsEnum->Next))
{
	# Get the Streams.

	if ($Project->HasStreams())
	{
        if (length($ProjectList) == 0)
        {
            $ProjectList = "\"".$Project->Name()."\"";
        }
        else
        {
            $ProjectList .= ",\"".$Project->Name()."\"";
        }
    }
}

$ClearPromptCommand = "clearprompt list -items ".$ProjectList.", -prompt \"Select the project to process\" -outfile c:\\temp\\selected_project_001.txt";

`$ClearPromptCommand`;

$ProjectName = GetFileData("c:\\temp\\selected_project_001.txt");
$Project = $CC->Project($ProjectName."@".$PVobTag);

my $BaselinedActivities = "";

# Get the integration stream.

my $IntegrationStream = $Project->IntegrationStream();

# Get a list of activities in the latest baseline to ignore.

my $LSBLCmd = "cleartool lsbl -fmt \"\%Nd##\%n\\n\" -stream ".$IntegrationStream->Name."@".$PVobTag;

my $LSBLResults = `$LSBLCmd`;

my @LSBLResultStrings = split("\n", $LSBLResults);

if($#LSBLResultStrings > 0)
{
    @LSBLResultStrings = sort(@LSBLResultStrings);
    @LSBLResultStrings = reverse(@LSBLResultStrings);

    $BaselineString = "";

    foreach $Baseline (@LSBLResultStrings)
    {
        print "baseline : ".$Baseline."\n";
        @DateBl = split("##", $Baseline);
        $Date = @DateBl[0];
        $Baseline = @DateBl[1];

        $Day = substr($Date, 6, 2);
        $Month = substr($Date, 4, 2);
        $Year = substr($Date, 0, 4);
        $Hours = substr($Date, 9, 2);
        $Minutes = substr($Date, 11, 2);
        $Seconds = substr($Date, 13, 2);

        $ProcessedDate = $Day."/".$Month."/".$Year." ".$Hours.":".$Minutes.":".$Seconds;

        if (length($BaselineString) == 0)
        {
            $BaselineString = "\"".$Baseline."      ".$ProcessedDate."\"";
        }
        else
        {
            $BaselineString .= ",\"".$Baseline."      ".$ProcessedDate."\"";
        }
    }
    $ClearPromptCommand = "clearprompt list -items ".$BaselineString.", -prompt \"Select the earliest boundary baseline required\" -outfile c:\\temp\\selected_baseline_001.txt";

    `$ClearPromptCommand`;

    $StartBL = GetFileData("c:\\temp\\selected_baseline_001.txt");

    $ClearPromptCommand = "clearprompt list -items ".$BaselineString.", -prompt \"Select the latest boundary baseline required\" -outfile c:\\temp\\selected_baseline_002.txt";

    `$ClearPromptCommand`;

    $EndBL = GetFileData("c:\\temp\\selected_baseline_002.txt");

    print "baselines : ".$StartBL." to ".$EndBL."\n";

    $DiffBlCommand = "cleartool diffbl -activities ".$StartBL."@".$PVobTag." ".$EndBL."@".$PVobTag;

    $DiffBlResult = `$DiffBlCommand`;

    @DiffBlLines = split("\n", $DiffBlResult);

    foreach $DiffBlLine (@DiffBlLines)
    {
        @DiffBlParts = split(" ", $DiffBlLine);

        push(@CQIDList, @DiffBlParts[1]);
    }

    $session = CQSession::Build();
    $session->UserLogon("admin", "", "CLSIC", "");

    foreach $CQID (@CQIDList)
    {
        # Get ClearQuest information for each record.

        $Query = $session->BuildQuery("AllRecords");

        $Query->BuildField("id");
        $Query->BuildField("record_type");

        $FilterDefinition = $Query->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);

        $FilterList1[0] = $CQID;
        $FilterList2[0] = "Defect";
        $FilterList3[0] = "Resolved";

        $FilterDefinition->BuildFilter("id", $CQPerlExt::CQ_COMP_OP_EQ, \@FilterList1);
        $FilterDefinition->BuildFilter("record_type", $CQPerlExt::CQ_COMP_OP_EQ, \@FilterList2);
        $FilterDefinition->BuildFilter("State", $CQPerlExt::CQ_COMP_OP_EQ, \@FilterList3);


        $ResultSet = $session->BuildResultSet($Query);
        $ResultSet->Execute();

        if ($ResultSet->MoveNext eq $CQPerlExt::CQ_SUCCESS)
        {
            print "--".$ResultSet->GetColumnValue(1)." ".$ResultSet->GetColumnValue(2)."\n";

            $EntityObject = $session->GetEntity($ResultSet->GetColumnValue(2), $ResultSet->GetColumnValue(1));

            print OUTFILE $ResultSet->GetColumnValue(2).":".$ResultSet->GetColumnValue(1)." -- ";

            print OUTFILE $EntityObject->GetFieldValue("Headline")->GetValue()."\n";

            $session->EditEntity($EntityObject, "Built");

            $ValidationResult = $EntityObject->Validate();

            if (length($ValidationResult) != 0)
            {
                print $ValidationResult."\n";
            }
            else
            {
                $EntityObject->Commit();
                print "changed state to built\n";
            }
        }
    }
    CQSession::Unbuild($session);
}
close OUTFILE;

exit(0);

############################################################################
sub GetFileData
############################################################################
{
    my($FileName) = @_;

    open FileHandle, $FileName;

    $SelectedBaseline = "";

    while (defined($DataFromFile = <FileHandle>))
    {
        $SelectedBaseline = join('',$SelectedBaseline, $DataFromFile);
    }

    close FileHandle;

    $SelectedBaseline = substr($SelectedBaseline, 0, index($SelectedBaseline, " "));

    return ($SelectedBaseline);
}
