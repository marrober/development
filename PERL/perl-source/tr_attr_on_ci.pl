# Trigger creation command :
# cleartool mktrtype -element -all -postop checkin -nc -exec "perl \\view\default\Data\perl-source\tr_copy_on_ci.pl" CopyOnCi

# Get comment.
$CommentPresent = 0;
$ChangeSetNumberPresent = 0;
if (-e "c:\\temp\\AttributeData.txt") {
	print "Data to be added to attributes\n";
	open DataFile, "c:\\temp\\AttributeData.txt";
	while (!(eof(DataFile)))
	{
		read DataFile, $DataFromFileTmp, 25;
		$DataFromFile .= $DataFromFileTmp;
	}
	close DataFile;	
	@SplitData = split("\n", $DataFromFile);
		
	$ChangeSetNumber = shift(@SplitData);
	$UserName = shift(@SplitData);
	$DateTime = shift(@SplitData);
	
	foreach $Line (@SplitData) {
		$Comment .= $Line."\n";
	}
	$Comment = substr($Comment, 0, length($Comment) - 1);
		
	$DataPresent = 1;
}

if ($DataPresent == 1) {
	$ClearCaseXPN = $ENV{CLEARCASE_XPN};
	$CleartoolMkAttrCsCmd = "cleartool mkattr -nc PerforceChangeSet ".$ChangeSetNumber." ".$ClearCaseXPN;
	`$CleartoolMkAttrCsCmd`;
	
	$CleartoolMkAttrUserCmd = "cleartool mkattr -nc PerforceUser \"\\\"".$UserName."\"\\\" ".$ClearCaseXPN;
	`$CleartoolMkAttrUserCmd`;

	$CleartoolMkAttrDateTimeCmd = "cleartool mkattr -nc PerforceDateTime \"\\\"".$DateTime."\"\\\" ".$ClearCaseXPN;
	`$CleartoolMkAttrDateTimeCmd`;

	$CleartoolMkAttrCommentCmd = "cleartool mkattr -nc PerforceComment \"\\\"".$Comment."\"\\\" ".$ClearCaseXPN;
	`$CleartoolMkAttrCommentCmd`;

}	