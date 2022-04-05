use strict;
use Win32::OLE;

my $PVobTag = $ARGV[0];
my $OutputFile = ">".$ARGV[1];

my $CC = Win32::OLE->new('ClearCase.Application');
# Get a list of all projects in the project VOB.

my $ProjectVobInstance = $CC->ProjectVob($PVobTag);

my $Projects = $ProjectVobInstance->Projects();

my $ProjectsEnum = Win32::OLE::Enum->new($Projects);

open OUTFILE, $OutputFile;

while (defined(my $Project = $ProjectsEnum->Next))
{
    my $Streams = $Project->Streams();
    my $StreamsEnum = Win32::OLE::Enum->new($Streams);
    while (defined(my $Stream = $StreamsEnum->Next))
    {
        print OUTFILE $Project->Name."\t";
        print OUTFILE $Stream->Name."\t";

        my $StreamDescCmd = "cleartool desc stream:".$Stream->Name."@".$PVobTag;

        my $Results = `$StreamDescCmd`;

		my @ResultStrings = split("\n", $Results);

        my $InbaselineSection = "no";
        my $FirstPassofBaselineSection = "yes";
        my $StreamType = "";

		foreach $_ (@ResultStrings)
		{
            # Stream identifer search string.
           
            if (/project: /) 
            {
                if (/integration stream/) { $StreamType = "Int"; } else { $StreamType = "Dev"; } 
                print OUTFILE $StreamType."\t";
            }
        
            if (/foundation baselines:/) { $InbaselineSection = "yes"; next;}
            if (/recommended baselines:/) { $InbaselineSection = "no"; next;}

            if ($InbaselineSection eq "yes")
			{
                # Get details of the baseline.

                my $Baseline = $_;
                $Baseline =~ s/^[ \t]+//;
                $Baseline =~ s/[ \t]+$//;
                $Baseline =~ s/[\(\)]//g;

                my @BaselineDetails = split(" ", $Baseline);

                my $LabelType = "";

                if (index(@BaselineDetails[0], "\.") >= 0)
                {
                    $LabelType = substr(@BaselineDetails[0], 0, index(@BaselineDetails[0], "\."));
                }
                else
                {
                    $LabelType = substr(@BaselineDetails[0], 0, index(@BaselineDetails[0], "\@"));
                }

                if ($FirstPassofBaselineSection eq "no")
                {
                    print OUTFILE $Project->Name."\t";
                    print OUTFILE $Stream->Name."\t";
                    print OUTFILE $StreamType."\t";
                }
                
                # Get details of the component.

                my $Component = substr(@BaselineDetails[1], 0, index(@BaselineDetails[1], "\@"));

                # Get all baselines for the component to see if there are any newer baselines to report.

                my $CompBaselinesCmd = "cleartool lsbl -comp ".$Component."@".$PVobTag." -fmt \"\%Nd##\%n\\n\"";

                my $CompResult = `$CompBaselinesCmd`;

                my @CompList = split("\n", $CompResult);

                my $NewerBaseline = "";
                    
                @CompList = sort(@CompList);
                my $FoundLabelType = "no";
                foreach $_ (@CompList)
                {
                    if (/$LabelType/)
                    {
                        $FoundLabelType = "yes"; next;
                    }

                    if ($FoundLabelType eq "yes")
                    {
                        if (!/deliverbl/)
                        {
                            # Get the name of the newer baseline.

                            $NewerBaseline = substr($_, index($_, "##") + 2);
                        }
                    }
                }

                # Modifiable ??

                my $Mod = "";

                if (@BaselineDetails[2] eq "modifiable") { $Mod = "mod"; } else { $Mod = "non-mod"; }
                
                print OUTFILE $Component."\t";
                print OUTFILE $Mod."\t";
                print OUTFILE $LabelType;
                if ($NewerBaseline ne "")
                {
                    print OUTFILE "\t".$NewerBaseline."\n";
                }   
                else
                {
                    print OUTFILE "\n";
                }
        

                $FirstPassofBaselineSection = "no";
            }
		}
    }
}
close OUTFILE;

exit(0);
