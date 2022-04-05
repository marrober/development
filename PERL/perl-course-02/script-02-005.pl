use ClearCase::CtCmd;

($Status, $stdout, $stderr) = ClearCase::CtCmd::exec("ls g:\\Dataaa");

print "Status : ".$Status."\n";
print "Stdout : ".$stdout."\n";
print "StdErr : ".$stderr."\n";

($Status, $stdout, $stderr) = ClearCase::CtCmd::exec("ls g:\\Data");

print "Status : ".$Status."\n";
print "Stdout : ".$stdout."\n";
print "StdErr : ".$stderr."\n";