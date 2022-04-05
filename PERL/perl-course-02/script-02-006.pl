use ClearCase::CtCmd;

$inst = ClearCase::CtCmd->new();
$vob="g:\\\Data";
($Status, $OwnerInformation, $err)=$inst->exec(desc,-fmt,"%u %Gu",$vob);
die $err if $inst->status();
print "\nObject Owner Information : ".$OwnerInformation."\n";
