$buildConfig = $ARGV[0];

$buildCmd = "oc start-build ".$buildConfig;
print $buildCmd;
$buildCmdResult = `$buildCmd`;
print $buildCmdResult;

$buildCmdResult = substr($buildCmdResult, 0, index($buildCmdResult, " "));
print $buildCmdResult;

$buildRunning = true;

while($buildRunning) {
    $getBuildStatusCmd = "oc get ".$buildCmdResult." -o jsonpath='{.status.phase}'";
    $buildStatusCmdResult = `$getBuildStatusCmd`;
    print ".";
    if (index($buildStactusCmdResult, "Complete") != -1) {
        $buildRunning = false;
    } else {
        sleep(3000);
    }
}
print "\n";