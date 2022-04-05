$BranchList = `cleartool lstype -kind brtype -short`;

@BranchArray = split("\n", $BranchList);

foreach $Branch (@BranchArray)
{
	$_ = $Branch;

	if(!/main/)
	{
		print "BRANCH .... : ".$Branch."\n";
		$FileList = `cleartool find . -nxname -element brtype($Branch) -print`;

		print $FileList."\n";
	}
}
