$VobTag = "\\Data";

$FileListCmd = "dir ".$VobTag."\\lost+found /s/b/a-d";
$FileList = `$FileListCmd`;

$DirectoryListCmd = "dir ".$VobTag."\\lost+found /s/b/ad";
$DirectoryList = `$DirectoryListCmd`;

@FileArray = split("\n", $FileList);
print "Files\n";
@NewFileArray = sort { length($a) <=> length($b) } @FileArray;
@FileArray = reverse(@NewFileArray);
foreach $File (@FileArray) {
	print $File."\n";	
	$CtDescResult = `cleartool desc \"$File\"`;
	@splitCTDescResult = split("\n", $CtDescResult);
	if ((substr(@splitCTDescResult[0], 0, length("View private file")) cmp "View private file") == 0) {
		$RemoveCommand = "del \"".$File."\"";
	}
	else {
		$RemoveCommand = "cleartool rmelem -f \"".$File."\"";
	}
	print `$RemoveCommand`;
}

@DirectoryArray = split("\n", $DirectoryList);

print "Directories\n";
@NewDirArray = sort { length($a) <=> length($b) } @DirectoryArray;
@DirectoryArray = reverse(@NewDirArray);
foreach $Directory (@DirectoryArray) {
	print $Directory."\n";
	$CtDescResult = `cleartool desc \"$Directory\"`;
	@splitCTDescResult = split("\n", $CtDescResult);
	if ((substr(@splitCTDescResult[0], 0, length("View private directory")) cmp "View private directory") == 0) {
		$RemoveCommand = "rmdir \"".$Directory."\"";
	}
	else {
		$RemoveCommand = "cleartool rmelem -f \"".$Directory."\"";
	}
	print `$RemoveCommand`;
}
print "\n";
