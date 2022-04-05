
$LabelList = `cleartool lstype -kind lbtype -s`;

@SplitLabelList = split("\n", $LabelList);

foreach $_ (@SplitLabelList)
{
	if (!(m/CHECKEDOUT/) && !(m/LATEST/))
	{
		print "Label,".$_.",";
		$DescCommand = "cleartool desc -fmt \"%Sd\" lbtype:".$_;
		print `$DescCommand`.",";
		$FindCommand = "cleartool find . -version \"lbtype(".$_.")\" -print";
		$LabelOnVersions = `$FindCommand`;
		@SplitVersionResult = split("\n", $LabelOnVersions);
		print $#SplitVersionResult + 1;
		print "\n";
		# print $LabelOnVersions."\n";
	}
}

$BranchList = `cleartool lstype -kind brtype -s`;

@SplitBranchList = split("\n", $BranchList);

foreach $_ (@SplitBranchList)
{
	print "Branch,".$_.",";
	$DescCommand = "cleartool desc -fmt \"%Sd\" brtype:".$_;
	print `$DescCommand`.",";
	$FindCommand = "cleartool find . -branch \"brtype(".$_.")\" -print";
	$BranchOnVersions = `$FindCommand`;
	@SplitVersionResult = split("\n", $BranchOnVersions);
	print $#SplitVersionResult + 1;
	print "\n";
	# print $BranchOnVersions."\n";
}

# History information.

$HistoryCommand = "cleartool lshistory -all -minor -eventid -since 01-Jan-1999 -fmt \"%e:%Sd~~\n\" .";

$HistoryResult = `$HistoryCommand`;

$HistoryResult =~ s/\n//g;
$HistoryResult =~ s/~~/\n/g;
$HistoryResult =~ s/event //g;

@SplitHistory = split("\n", $HistoryResult);

@SplitHistory = sort(@SplitHistory);

$LastDate = "";

foreach $SplitLine (@SplitHistory)
{
	@SplitParts = split(/:/g, $SplitLine);

	if ($LastDate != @SplitParts[2]) 
	{
		if (length($LastDate) != 0) 
		{			
			$Events = @SplitParts[0] - $EventBase;
			$TotalEvents += $Events;
			$EventBase = @SplitParts[0];
			print $LastDate." ,".($Events + 1)."\n";
		}
		else
		{
			$EventBase = @SplitParts[0];
		}
		$LastDate = @SplitParts[2];
	}
}

$Events = @SplitParts[0] - $EventBase;
$EventBase = @SplitParts[0];
print $LastDate." ,".($Events + 1)."\n";
$TotalEvents += $Events + 1;

print "Total number of events : ".$TotalEvents."\n";
