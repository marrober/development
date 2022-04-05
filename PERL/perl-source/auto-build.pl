$TaskCardDefectIdentifier = $ARGV[0];

if ($TaskCardDefectIdentifier eq "TaskCard")
{
	$TaskCardID = $ARGV[1];
	print "Processing a task card ....\n";
	print "Task Card ID : ".$TaskCardID."\n";
	$LabelName = "TASKCARD_".$TaskCardID."_";
}
else
{
	$CQRef = $ARGV[1];
	print "Processing a defect ....\n";
	print "ClearQuest Reference : ".$CQRef."\n";
	$LabelName = "DEFECT_".$CQRef."_";
}

$CSTempFile = ">c:\\temp\\cs.txt";
$BuildResultTempFile = ">c:\\temp\\br.txt";

$VobName = "\\development";

$MountCmd = "cleartool mount ".$VobName;
`$MountCmd`;

my @TimeArray = localtime(time);

if (@TimeArray[3] < 10) { $DateTime =  "0".@TimeArray[3]; } else { $DateTime =  @TimeArray[3]; }
if (@TimeArray[4] < 10) { $DateTime .= "0".(@TimeArray[4] + 1); } else { $DateTime .= (@TimeArray[4] + 1); }
$DateTime .= ".";
if (@TimeArray[2] < 10) { $DateTime .= "0".@TimeArray[2]; } else { $DateTime .= @TimeArray[2]; }
if (@TimeArray[1] < 10) { $DateTime .= "0".@TimeArray[1]; } else { $DateTime .= @TimeArray[1]; }

# Format baseline name

$LabelName .= $DateTime;

print "Label to be generated ...".$LabelName."\n";

# create the label type within the VOB.

$MklbtypeCmd = "cleartool mklbtype -nc ".$LabelName."@".$VobName;
$MklbtypeResult = `$MklbtypeCmd`;
print $MklbtypeResult."\n";

$StartViewCmd = "cleartool startview integration_latest";
$StartViewResult = `$StartViewCmd`;
print $StartViewResult."\n";

# Attach the label to the objects in the VOB.

$MklbCmd = "cleartool mklabel -recurse -nc ".$LabelName." m:\\integration_latest".$VobName;
print $MklbCmd."\n";
$MklbResult = `$MklbCmd`;
print $MklbResult."\n";

# Attach the LabelStatus attribute to the label type 

print "Attach attribute 'LabelStatus' with an initial value of 'Initial'...\n";

$MkattrCmd = "cleartool mkattr -nc LabelStatus \\\"Initial\\\" lbtype:".$LabelName."@".$VobName;
$MkattrResult = `$MkattrCmd`;
print $MkattrResult."\n";

print "Get the latest baseline label for the library components ...\n";
$LibraryLabelsCmd = "cleartool lstype -kind lbtype -fmt \"%Nd,%n\\n\" -invob \\library";
$LibraryLabels = `$LibraryLabelsCmd`;

@LabelArray = split("\n", $LibraryLabels);
foreach $Label (@LabelArray)
{
	@LabelDateName = split(",", $Label);
	$LibraryHash{@LabelDateName[0]} = @LabelDateName[1];
}

foreach $key (sort keys %LibraryHash)
{
	push(@SortedLibraryLabels, $LibraryHash{$key});
}

$LatestLibraryLabel = pop(@SortedLibraryLabels);

print "Library label to use ... ".$LatestLibraryLabel."\n";

$NewConfigSpec = "element /development/... ".$LabelName."\n";
$NewConfigSpec .= "element /library/... ".$LatestLibraryLabel."\n";

open CSFile, $CSTempFile;
print CSFile $NewConfigSpec;
close CSFile;

$Setauto_buildCSCmd = "cleartool setcs -tag auto_build c:\\temp\\cs.txt";
$Setauto_buildCSResult = `$Setauto_buildCSCmd`;
print $Setauto_buildCSResult."\n"; 

# Start the auto_build view

$StartViewCmd = "cleartool startview auto_build";
$StartViewResult = `$StartViewCmd`;
print $StartViewResult."\n";

#  Ant build command
$AntBuildClean = "cmd /c m:\\auto_build\\development\\script\\build-clean.cmd";
print $AntBuildClean."\n";
$BuildResult = `$AntBuildClean`;
print "------------------------------------------------------------------\n";

@BuildResultLines = split("\n", $BuildResult);

$BuildStatus = "FAILURE";

foreach $_ (@BuildResultLines)
{
	if (m/BUILD SUCCESSFUL/)
	{
		$BuildStatus = "SUCCESS";
	}
	if (m/Total time:/)
	{
		$BuildTime = substr($_, index($_, ":") + 1);	
	}
}

if ($BuildStatus eq "SUCCESS")
{
	$MkattrCmd = "cleartool mkattr -nc -replace LabelStatus \\\"Config-Pass\\\" lbtype:".$LabelName."@".$VobName;
	print $MkattrCmd."\n";
	$MkattrResult = `$MkattrCmd`;
	print $MkattrResult."\n";

	# Generate configuration record information for the final output files.
	#

	$CRFile = "c:\\temp\\Integration.ear.cr";

	$IntegCRCmd = "cleartool catcr m:\\auto_build\\development\\dist\\Integration.ear >".$CRFile;
	`$IntegCRCmd`;
}
else
{
	$MkattrCmd = "cleartool mkattr -nc -replace LabelStatus \\\"Config-Fail\\\" lbtype:".$LabelName."@".$VobName;
	print $MkattrCmd."\n";
	$MkattrResult = `$MkattrCmd`;
	print $MkattrResult."\n";
}

print $BuildTime."\n";
print "------".$BuildStatus."\n";

open BRFile, $BuildResultTempFile;
print BRFile $BuildResult;
close BRFile;

# Generate log record

$BuildResultTempFile =~ s/>//g;

$ResultLogCmd = "cqperl \\\\red_pdc\\data\\scripts\\generate_build_log.pl ".$LabelName." ".$BuildStatus." ".$BuildResultTempFile." ".$CRFile;
print $ResultLogCmd."\n";
`$ResultLogCmd`;

exit(0);

