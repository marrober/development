use strict;
use Win32::OLE;

my $PVobTag = $ARGV[0];
my $OutputFile = ">".$ARGV[1];
my $CC = Win32::OLE->new('ClearCase.Application');
# Get a list of all projects in the project VOB.

my $ProjectVobInstance = $CC->ProjectVob($PVobTag);

my $Projects = $ProjectVobInstance->Projects();

my $ProjectsEnum = Win32::OLE::Enum->new($Projects);

print "Number of promotion levels ".$ProjectVobInstance->NumberOfPromotionLevels()."\n";
my $PromotionLevelArray = $ProjectVobInstance->PromotionLevelsStringArray();
my %PromLevels = "";
my $Counter = 0;
print "Promotion level hierarchy : \n";
foreach my $PromotionLevel (@$PromotionLevelArray)
{
    print $PromotionLevel."\n";
    $PromLevels{$PromotionLevel} = $Counter++;
}
############################################################################

open OUTFILE, $OutputFile;

while (defined(my $Project = $ProjectsEnum->Next))
{
	if ($Project->HasStreams() == 1)
	{
        my $RequiredPromLevel = $Project->RequiredPromotionLevel();

		my $IntStream = $Project->IntegrationStream();
        my $FoundationBaselines = $IntStream->FoundationBaselines();

        print "Project : ".$Project->Name()."\n";
        print "Required promotion level for project : ".$RequiredPromLevel."\n";

        for (my $Count = 1; $Count <= $FoundationBaselines->Count(); $Count++)
        {
            print "\tFoundation baselines in project for each component : \n";
            print "\t\tComponent name  : ".$FoundationBaselines->Item($Count)->Component()->Name()."\n";
            print "\t\tBaseline label  : ".GetLabelType($FoundationBaselines->Item($Count)->Name())."  ";
            print $FoundationBaselines->Item($Count)->PromotionLevel()."\n";

            # Get the list of baselines for the component.

            my $LSBLCommand = "cleartool lsbl -comp ".$FoundationBaselines->Item($Count)->Component()->Name()."@".$PVobTag." -fmt \"%Nd#%n\\n\"";

            my $LSBLResult = `$LSBLCommand`;

            my @BLData = split("\n", $LSBLResult);

            my @SortedBLData = sort SortArray @BLData;

            print "\t\tAll baselines for the component\n";

            foreach my $BL (@SortedBLData)
            {
                my @BLParts = split("#", $BL);

                # Get promotion level of baseline.

                my $LabelType = GetLabelType(@BLParts[1]);

                print "\t\t Baseline label : ".$LabelType." ".@BLParts[0]." ";

                my $BaselineObj = $ProjectVobInstance->Baseline("baseline:".@BLParts[1]."@".$PVobTag);
                print $BaselineObj->PromotionLevel."\n";
            }
        }

	    my $StreamDescCmd = "cleartool desc stream:".$IntStream->Name."@".$PVobTag;

	    my $Results = `$StreamDescCmd`;

	    my @ResultStrings = split("\n", $Results);

	    my $InbaselineSection = "no";

	    foreach $_ (@ResultStrings)
	    {
	        if (/foundation baselines:/) { $InbaselineSection = "yes"; next;}
            if (/:/) { $InbaselineSection = "no"; next;}

	        if ($InbaselineSection eq "yes")
	        {
                # Get details of the baseline.

	            my $Baseline = $_;
	            $Baseline =~ s/^[ \t]+//;
	            $Baseline =~ s/[ \t]+$//;
	            $Baseline =~ s/[\(\)]//g;

	            my @BaselineDetails = split(" ", $Baseline);

                my $LabelType = GetLabelType(@BaselineDetails[0]);

	            # Get details of the component.

	            my $Component = substr(@BaselineDetails[1], 0, index(@BaselineDetails[1], "\@"));

	            # Modifiable ??

	            my $Mod = "";

                if (@BaselineDetails[2] eq "modifiable")
                { $Mod = "mod"; }
                else
                {
                    $Mod = "non-mod";

                    # Get the latest baseline at the appropriate promotion level.




                }

#                print $Project->Name."\t";
#                print $Component."\t";
#                print $LabelType."\t";
#                print $Mod."\n";
	        }
	    }
    }
}

close OUTFILE;
exit(0);


############################################################################
sub SortArray
############################################################################
{
    if ($a < $b) { return 1; }
    elsif ($a == $b) { return 0; }
    else { return -1; }
}

############################################################################
sub GetLabelType
############################################################################
{
    my ($BaselineDate) = @_;
    my ($LabelType) = "";

    if (index($BaselineDate, "\.") >= 0)
    {
        $LabelType = substr($BaselineDate, 0, index($BaselineDate, "\."));
    }
    else
    {
        $LabelType = substr($BaselineDate, 0, index($BaselineDate, "\@"));
    }

    return($LabelType);
}
