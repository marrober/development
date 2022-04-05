use Win32::OLE;

$cc = Win32::OLE->new('ClearCase.Application') or die "Could not create Application object\n";

# Get the name of the file.
#
$EndBranch = $ARGV[0];
$StartBranch = $ARGV[1];
$ReviewBatchFile = $ARGV[2];

if (length($StartBranch) == 0)
{
	print "Default start branch of main taken\n";
	$StartBranch = "\\main";
}
else
{
	if (substr($StartBranch, 0, 1) ne "\\")
	{
		$StartBranch = "\\".$StartBranch;
	}
}

print "Start branch : ".$StartBranch."\n";
print "End branch : ".$EndBranch."\n---------------------------------------------------\n";


$FindCommand = "cleartool find . -version {version(...\\".$EndBranch."\\LATEST)} -print";
$FoundFiles = `$FindCommand`;

@FoundFilesArray = split("\n", $FoundFiles);

if (length($ReviewBatchFile) > 0)
{
	$ReviewBatchFile = ">".$ReviewBatchFile;

	open BATCH, $ReviewBatchFile;
}

foreach $File (@FoundFilesArray)
{
	@NameVer = split("@@", $File);

	$FileNameOnly = @NameVer[0];

	$VersionFound = @NameVer[1];

	$VersionInformation = @NameVer[1];

	$FinalBranch = substr($VersionInformation, 0, rindex($VersionInformation, "\\"));

	$FinalBranch = substr($FinalBranch, rindex($FinalBranch, "\\"));

	while (($FinalBranch ne $StartBranch))
	{
		$Version = $cc->Version($FileNameOnly."@@".$VersionInformation);

		$VersionNumber = $Version->Branch->BranchPointVersion->VersionNumber;

		$VersionInformation = substr($VersionInformation, 0, rindex($VersionInformation, "\\"));
		$VersionInformation = substr($VersionInformation, 0, rindex($VersionInformation, "\\"));
		$VersionInformation .= "\\".$VersionNumber;

		$FinalBranch = substr($VersionInformation, 0, rindex($VersionInformation, "\\"));

		$FinalBranch = substr($FinalBranch, rindex($FinalBranch, "\\"));
			
		if (($FinalBranch eq $StartBranch) && ($FinalBranch ne "\\main") && ($VersionNumber == 0))
		{
			$StartBranch = substr($VersionInformation, 0, index($VersionInformation, $FinalBranch));
		}
	} ;

	if ($VersionInformation eq "\\main\\0")
	{
		$VersionInformationReport = "new";
	}
	else
	{
		$VersionInformationReport = $VersionInformation;
	}


	if ((length($ReviewBatchFile) > 0) && ($VersionInformation ne "\\main\\0"))
	{
		print BATCH "cleartool diff -g ".$FileNameOnly."@@".$VersionInformation." ".$FileNameOnly."@@".$VersionFound."\n";
	}

	print $FileNameOnly.",".$VersionInformationReport.",".$VersionFound."\n";

}

if (length($ReviewBatchFile) > 0)
{
	close BATCH;
}




