$UserName = "admin";
$Password = "rational";

$PerforceCSID = @ARGV[0];

$CQPerlCommand = "cqperl c:\\temp\\cq_perforce.pl ".$UserName." ".$Password." ".$PerforceCSID;

$Result = `$CQPerlCommand`;

print $Result."\n";

$_ = $Result;

if (m/Modify completed successfully/) {
	print "SUCCEEDED\n";
	$ExitCode = 0;
}
else {
	print "FAILED\n";
	$ExitCode = 1;
}
@DateTime = gmtime(time);
$DateAndTime = @DateTime[3]."/".(@DateTime[4] + 1)."/".(@DateTime[5] + 1900)." ".(@DateTime[2] + 1).":".@DateTime[1].":".@DateTime[0];
	
open TEMPFILE, ">c:\\temp\\TEMP-Result.txt";
print TEMPFILE $DateAndTime." ".$PerforceUser." ".$PerforceCSID."\n";
foreach $FileToRecord (@FileList) {
	print TEMPFILE $FileToRecord."\n";
}
close TEMPFILE;

exit($ExitCode);

