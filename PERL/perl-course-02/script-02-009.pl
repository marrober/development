use ClearCase::CtCmd;

$VobTag = @ARGV[0];
$StartTime = time;
$inst = ClearCase::CtCmd->new();

$ListCommand = "lstype -kind lbtype -s -invob ".$VobTag;
($Status, $LabelList, $err)=$inst->exec($ListCommand);
print $Status."  ".$LabelList."  ".$err."\n";
@LabelArray = split("\n", $LabelList);
$NumberLabels = $#LabelArray;
foreach $LabelToRemove (@LabelArray) {
	if (($LabelToRemove ne "LATEST") && ($LabelToRemove ne "BACKSTOP") && ($LabelToRemove ne "CHECKEDOUT")) {
		$RemovalCommand = "rmtype lbtype:".$LabelToRemove."@".$VobTag;
		($Status, $RMLabelResult, $err)=$inst->exec($RemovalCommand);
	}
}
$EndTime = time;
$TimeTaken = $EndTime - $StartTime;
print "Time taken : ".$TimeTaken." seconds \n";
print $NumberLabels."\n";
