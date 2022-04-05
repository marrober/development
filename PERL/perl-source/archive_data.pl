$DirListingCmd = "dir c:\\default_snap\\Data_windows /s/b/a-d";
$DirListing = `$DirListingCmd`;

@DirListingArray = split("\n", $DirListing);

foreach $VOBFile (@DirListingArray)
{
	$FileSystemFile = $VOBFile;
	$FileSystemFile =~ s/c:\\default_snap\\Data_windows/c:\\Data/;

	if (-e $FileSystemFile)
	{
		@VOBFileStats = stat($VOBFile);
		@FSFileStats = stat($FileSystemFile);

		if (@VOBFileStats[9] < @FSFileStats[9])
		{
			print "\nVob file needs to be updated\n";
			$CheckoutCmd = "cleartool co -nc ".$VOBFile;
			print `$CheckoutCmd`;
			$CheckinCmd = "cleartool ci -nc -rm -from ".$FileSystemFile." ".$VOBFile;
			print `$CheckinCmd`;
		}
		else
		{
			print ".";
		}
	}	
}
