use ClearCase::CtCmd;
$StartTime = time;

@Var = qw(find \\Data -type f -version version(/main/10) -print);
foreach $V (@Var) { print $V."\n"; }
$inst = ClearCase::CtCmd->new();
($Status, $SearchResult, $err)=$inst->exec(qw(find \\Data -type f -version version(/main/10) -print));
print $Status." : ".$err."\n";
print $SearchResult."\n";

$EndTime = time;
$TimeTaken = $EndTime - $StartTime;
print "Time taken : ".$TimeTaken." seconds \n";

