$Snapshot1 = $ARGV[0];
$Stream2 = $ARGV[1];
$Targetlocation = $ARGV[2];
$WorkItemListFile = $ARGV[3];

$PersistentDirectory = "";

$CompareStreamCmd = "lscm compare -C {itemid} snapshot \"".$Snapshot1."\" stream \"".$Stream2."\" -f i -p c";
print $CompareStreamCmd."\n";
$CompareStreamResult = `$CompareStreamCmd`;

@WorkItemsRequired = ReadWorkItemListFile($WorkItemListFile);

foreach $_ (@WorkItemsArray) {
	print $_."\n";
}

@CompareStreamArray = split("\n", $CompareStreamResult);

$ComponentName = "";

foreach $_ (@CompareStreamArray) {
	$_ =~ s/^    //g;
	if (m/^\(/) {
		@ChangeLineParts = split(" ", $_);	
		$ChangeSetID = substr(@ChangeLineParts[0], 1, index(@ChangeLineParts[0], "\)") - 1);
		$WorkItemID = @ChangeLineParts[2];
		$WorkItemID =~ s/://g;
		
		$ChangeRequired = 0;
		foreach $_ (@WorkItemsArray) {
			if ($_ == $WorkItemID) {
				$ChangeRequired = 1;
			}
		} 
		
		if ($ChangeRequired == 1) {
			$GetChangeDetailsCmd = "lscm list changes ".$ChangeSetID;
			$ChangeDetails = `$GetChangeDetailsCmd`;
			print "Processing Change .... ".$ChangeSetID." ... Work Item ".$WorkItemID."\n";"\n";
			# print $ChangeDetails."\n\n";
			@ChangeArray = split("\n", $ChangeDetails);
			$FileChange = 0;
			$WorkItems = 0;
			$#ChangeSetContent = -1;
			$#WorkItemList = -1;
			foreach $_ (@ChangeArray) {
				if ($WorkItems == 1) {
					@WorkItemList[$#WorkItemList + 1] = $_;
				}
				if (m/    Work items:/) {
					$FileChange = 0;
					$WorkItems = 1;
				}
				if ($FileChange == 1) {
					@ChangeSetContent[$#ChangeSetContent + 1] = $_;
				}
				if (m/    Changes:/) {
					$FileChange = 1;
				}	
			}
			print "Associated work items.....\n";
			foreach $_ (@WorkItemList) {
				print $_."\n";
			}
			
			foreach $_ (@ChangeSetContent) {			
				$FileNameWithPath = substr($_, index($_, "\\"));
				$Path = substr($FileNameWithPath, 0, rindex($FileNameWithPath, "\\"));
				$FileName = substr($FileNameWithPath, length($Path));
				$NewPath = $Targetlocation."\\".$ChangeSetID."_".$WorkItemID."\\".$ComponentName.$Path;
			
				# Validate / Create new path.
				CreateRequiredPaths($NewPath);
				$ExtractCommand = "lscm get change -o ".$ChangeSetID." \"".$FileNameWithPath."\" \"".$NewPath.$FileName."\"";
				print `$ExtractCommand`;
			}	
			print "\n";
		}
		else {
			print "Skipping work item ".$WorkItemID."\n";
		}
	}
	elsif (m/^\  Component \(/) {
		@ChangeLineParts = split("\"", $_);	
		$ComponentName = @ChangeLineParts[1];	
		$ComponentName =~ s/\"//g;
	}
}

sub CreateRequiredPaths() {
	my $PathToValidate_Create = $_[0];
	my $LeftPath = "";
	my $DirectoryToCreate = "";
	
	if (length($PathToValidate_Create) == 0) {
		return("Error");
	}
		
	if (-e $PathToValidate_Create) {
		return("");
	}
	else {
		# Validate the directory tree and then create any required directories.
		
		$LeftPath = substr($PathToValidate_Create, 0, rindex($PathToValidate_Create, "\\"));
		$DirectoryToCreate = substr($PathToValidate_Create, length($LeftPath) + 1);
		
		if (!(-e $LeftPath)) {
			CreateRequiredPaths($LeftPath);
		}
		$MkDirCommand = "mkdir \"".$LeftPath."\\".$DirectoryToCreate."\"";
		`$MkDirCommand`."\n";
	}
}

sub ReadWorkItemListFile($WorkItemListFile) {
	open InputFileHandle, $WorkItemListFile;
	while (eof(InputFileHandle) == 0)
	{
		read InputFileHandle, $DataFromFile, 25;
		$WorkItemList = join('',$WorkItemList, $DataFromFile);
	}
	close InputFileHandle;
	
	@WorkItemsArray = split("\n", $WorkItemList);
	
	return(@WorkItemsArray);
}