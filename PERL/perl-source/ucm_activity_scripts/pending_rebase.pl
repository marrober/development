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

my %RecBsl = "";


while (defined(my $Project = $ProjectsEnum->Next)) 
{
    my $RecBaselines = $Project->RecommendedBaselines();

    my $RecBaselinesEnum = Win32::OLE::Enum->new($RecBaselines);

    while (defined(my $RecBaseline = $RecBaselinesEnum->Next))
    {
#        print "Recommended baseline : ".$RecBaseline->Name."\n";
        $RecBsl{$RecBaseline->Name} = 1;
    }

    my $DevStreams = $Project->DevelopmentStreams();

    my $DevStreamsEnum = Win32::OLE::Enum->new($DevStreams);

    while (defined(my $DevStream = $DevStreamsEnum->Next))
    {   
#        print "Dev stream : ".$DevStream->Name."\n";   
        my $FoundationBaselines = $DevStream->FoundationBaselines();

        my $FoundationBaselinesEnum = Win32::OLE::Enum->new($FoundationBaselines);
        my %RecBslCopy = %RecBsl;
        my %LagComp = "";

        while (defined(my $FoundationBaseline = $FoundationBaselinesEnum->Next))
        {
#            print "Foundation baseline for dev stream: ".$FoundationBaseline->Name."\n";
            my $BaselineDescCmd = "cleartool desc -fmt \"%[component]p\" \"baseline:".$FoundationBaseline->Name."\@".$PVobTag;
            my $Component = `$BaselineDescCmd`;
#            print "Comp desc result : ".$Component."\n";

            if ($RecBslCopy{$FoundationBaseline->Name}) { delete $RecBslCopy{$FoundationBaseline->Name}; } 
            else { $LagComp{$Component} = 1; }
        }

        my $numkeys = 0;
        $numkeys = keys(%LagComp);
#        print $numkeys."\n";
        if ($numkeys > 1) 
        {  
            my $LagList = join(",", keys(%LagComp));
            $LagList =~ s/^\,//;
            print OUTFILE $Project->Name."\t".$DevStream->Name."\t".$LagList. "\n"; 
        }
        else { print OUTFILE $Project->Name."\t".$DevStream->Name."\t"."UP TO DATE\n"; }
    }
}
close OUTFILE;

exit(0);

