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
    my $IntStream = $Project->IntegrationStream();
    my $StreamDescCmd = "cleartool desc stream:".$IntStream->Name."@".$PVobTag;

    my $Results = `$StreamDescCmd`;

    my @ResultStrings = split("\n", $Results);

    my $InbaselineSection = "no";
 
    foreach $_ (@ResultStrings)
    {       
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

            # Get details of the component.

            my $Component = substr(@BaselineDetails[1], 0, index(@BaselineDetails[1], "\@"));

            # Modifiable ??

            my $Mod = "";

            if (@BaselineDetails[2] eq "modifiable") { $Mod = "mod"; } else { $Mod = "non-mod"; }
            
            
            print OUTFILE $Project->Name."\t";    
            print OUTFILE $Component."\t";
            print OUTFILE $Mod."\n";
        }
    }
}

close OUTFILE;
exit(0);
