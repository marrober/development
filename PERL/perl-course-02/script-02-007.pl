$VobTag = @ARGV[0];

for ($MasterCounter = 1; $MasterCounter <=10; $MasterCounter++) {
	$StartTime = time;
	for ($Counter = 1;$Counter <= ($MasterCounter * 1000);$Counter++) {
		$LabelName = "LABEL_STD".sprintf("%02d%05d", $MasterCounter, $Counter);
		$cleartool_MkLbTypeCmd = "cleartool mklbtype -nc $LabelName@".$VobTag;
		`$cleartool_MkLbTypeCmd`;
	}
	
	$EndTime = time;
	$TimeTaken = $EndTime - $StartTime;
	print "Labels : ".($MasterCounter * 1000)." : Time taken : ".$TimeTaken." seconds \n";
}
