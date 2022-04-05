use ClearCase::CtCmd;

$StartTime = time;

($Status, $stdout, $stderr) = ClearCase::CtCmd::exec("ls -vob_only -r -s g:\\Data");

@ElementArray = split("\n", $stdout);

foreach $Element (@ElementArray)
{
	($Status, $stdout, $stderr) = ClearCase::CtCmd::exec(desc,-fmt,"%En %u %Gu",$Element);
	push (@ResultArray, $stdout);
}

foreach $Result (@ResultArray) { print $Result."\n"; }
print $#ElementArray."\n";
$EndTime = time;

print $EndTime - $StartTime."\n";



