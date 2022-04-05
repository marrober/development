use ClearCase::CtCmd;

($Status, $stdout, $stderr) = ClearCase::CtCmd::exec("ls f:\\Dataaa");

print "Status : ".$Status."\n";
print "Stdout : ".$stdout."\n";
print "StdErr : ".$stderr."\n";

($Status, $stdout, $stderr) = ClearCase::CtCmd::exec("ls f:\\Data");

print "Status : ".$Status."\n";
print "Stdout : ".$stdout."\n";
print "StdErr : ".$stderr."\n";

$inst = ClearCase::CtCmd->new();

$vob="f:\\\Data";

($Status, $OwnerInformation, $err)=$inst->exec(desc,-fmt,"%u %Gu",$vob);

die $err if $inst->status();

print "\nObject Owner Information : ".$OwnerInformation."\n";



