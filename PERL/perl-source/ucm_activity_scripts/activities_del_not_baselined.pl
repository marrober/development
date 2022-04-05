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

while (defined(my $Project = $ProjectsEnum->Next)) { 
	# Get the Streams.

	if ($Project->HasStreams())
	{
        my $BaselinedActivities = "";

		# Get the integration stream.

		my $IntegrationStream = $Project->IntegrationStream();

        # Get a list of activities in the latest baseline to ignore.

        my $LSBLCmd = "cleartool lsbl -long -stream ".$IntegrationStream->Name."@".$PVobTag;

        my $LSBLResults = `$LSBLCmd`;
        
        my @LSBLResultStrings = split("\n", $LSBLResults);
    
        my $inblcs = "no";
        foreach $_ (@LSBLResultStrings)
        {
            if (/change sets:/)     { $inblcs = "yes"; next; }
            if (/promotion level:/) { $inblcs = "no"; next; }
            if ("$inblcs" eq "yes") 
            {
                my $act = $_;
                $act =~ s/^[ \t]+//;
                $act =~ s/[ \t]+$//;
                $BaselinedActivities .= substr($act, 0, index($act, "\@"))." ";
            }
        }        

        my $DescStreamCmd = "cleartool desc -l stream:".$IntegrationStream->Name."@".$PVobTag;

		my $Results = `$DescStreamCmd`;

		my @ResultStrings = split("\n", $Results);

		my $InactivitySection = "no";
		foreach $_ (@ResultStrings)
		{
			if (/foundation baselines:/) { $InactivitySection = "no"; next;}
			if (/contains activities:/) { $InactivitySection = "yes"; next;}

			if ($InactivitySection eq "yes")
			{
				# Get details of the activity.

				my $Activity = $_;
				$Activity =~ s/^[ \t]+//;
				$Activity =~ s/[ \t]+$//;
                $Activity = substr($Activity, 0, index($Activity, "\@"));
                $_ = $BaselinedActivities;
                if (/$Activity/) { ; }
                else 
                { 
                    my $ActivityObj = $ProjectVobInstance->Activity($Activity);

                    my @ActivityInformation = split(" ", $ActivityObj->Headline());

                    print OUTFILE $Project->Name."\t".@ActivityInformation[1]."\t"." ".$ActivityObj->ClearQuestRecordID()." on ";

                    print OUTFILE @ActivityInformation[3]." ".@ActivityInformation[4]."\n";
                }
			}
		}
	}
}
close OUTFILE;

exit(0);

