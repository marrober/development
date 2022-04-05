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
		# Get the integration stream.

		my $IntegrationStream = $Project->IntegrationStream();

		my $Streams = Win32::OLE::Enum->new($Project->DevelopmentStreams());

		while (defined(my $Stream = $Streams->Next)) 
		{

			my $IntStreamForDiffBL = "stream:".$IntegrationStream->Name."\@".$PVobTag;
			my $DevStreamForDiffBL = "stream:".$Stream->Name."\@".$PVobTag;
	
			my $DiffBLCmd = "cleartool diffbl -activities ".$IntStreamForDiffBL." ".$DevStreamForDiffBL;

			my $Result = `$DiffBLCmd`;

			# << activity is only in the first baseline/stream
			# >> activity is only in the second baseline/stream
			# <- activity has additional changes in the first baseline/stream that aren't in the second
			# -> activity has additional changes in the second baseline/stream that aren't in the first
	
			# Process the results - the interest here is in the activities marked as >> or ->.

			my @ActivityList = split("\n", $Result);

			foreach my $Activity (@ActivityList)
			{
				my @ActivityDetail = split(" ", $Activity);

				$_ = @ActivityDetail[0];
				
				if (/\>\>/)
				{
                    print OUTFILE $Project->Name."\t".$Stream->Name."\t"."Undel   : ".@ActivityDetail[1]."\n";
				}
				elsif(/-\>/)
				{
                    print OUTFILE $Project->Name."\t".$Stream->Name."\t"."Updated : ".@ActivityDetail[1]."\n";
				}
			}
		}
	}

}
close OUTFILE;

exit(0);

