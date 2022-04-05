$newDate=`date +'%s'`;
$newDate=substr($newDate, 0, length($newDate)-1);
print $newDate;


$TestCmd = 'oc patch deployment/taxi --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"'.$newDate.'\"}}}}}"';
print $TestCmd."\n";
$TestCmdResult = `$TestCmd`;
print $TestCmdResult;