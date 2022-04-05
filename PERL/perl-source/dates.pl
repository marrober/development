my @TimeArray = localtime(time);
$CurrentDate = @TimeArray[3]."/".(@TimeArray[4] + 1)."/".(@TimeArray[5] + 1900);

if (@TimeArray[2] <= 9) { $Time = "0".@TimeArray[2]; }
else                   {  $Time = @TimeArray[2]; }
if (@TimeArray[1] <= 9) { $Time .= ":0".@TimeArray[1]; }
else                   {  $Time .= ":".@TimeArray[1]; }

$CurrentDateTime = $CurrentDate." ".$Time;
print $CurrentDateTime."\n";
