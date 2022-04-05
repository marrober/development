use ClearCase::CtCmd;

$StartTime = time;

$stdout = `cleartool ls -vob_only -r -s g:\\Data`;
@ElementArray = split("\n", $stdout);

foreach $Element (@ElementArray)
{
	$stdout = `cleartool desc -fmt \"%En %u %Gu\" $Element`;
	push (@ResultArray, $stdout);
}

# foreach $Result (@ResultArray) { print $Result."\n"; }
print $#ElementArray."\n";
$EndTime = time;

print $EndTime - $StartTime."\n";



