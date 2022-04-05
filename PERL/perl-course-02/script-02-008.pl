use ClearCase::CtCmd;

$VobTag = @ARGV[0];
for ($MasterCounter = 1; $MasterCounter <=10; $MasterCounter++) {
	$StartTime = time;
	
	$inst = ClearCase::CtCmd->new();
	for ($Counter = 1;$Counter <= ($MasterCounter * 1000);$Counter++) {
		$LabelName = "LABEL_CTCMD".sprintf("%02d%05d", $MasterCounter, $Counter);
		($Status, $MkLabelResult, $err)=$inst->exec(mklbtype,-nc,$LabelName."@".$VobTag);
	}
	
	$EndTime = time;
	$TimeTaken = $EndTime - $StartTime;
	print "Labels : ".($MasterCounter * 1000)."  : Time taken : ".$TimeTaken." seconds \n";
}
