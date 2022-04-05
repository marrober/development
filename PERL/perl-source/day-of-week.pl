my @TimeArray = localtime(time);
$CurrentDate = @TimeArray[3]."/".(@TimeArray[4] + 1)."/".(@TimeArray[5] + 1900);
$DayDate = @TimeArray[3];
$MonthDate = @TimeArray[4] + 1;
$YearDate = @TimeArray[5] + 1900;

if (@TimeArray[2] <= 9) { $Time = "0".@TimeArray[2]; }
else                   {  $Time = @TimeArray[2]; }
if (@TimeArray[1] <= 9) { $Time .= ":0".@TimeArray[1]; }
else                   {  $Time .= ":".@TimeArray[1]; }

$CurrentDateTime = $CurrentDate." ".$Time;

$DayDate = 24;
$MonthDate = 4;
$YearDate = 2005;
print $DayDate." :: ".$MonthDate." :: ".$YearDate."\n";

$CenturyFactor = 6;

if ((int($YearDate / 4) * 4) == $YearDate) {
	$MonthOffset{1} = 6;
	$MonthOffset{2} = 2;
} else {
	$MonthOffset{1} = 0;
	$MonthOffset{2} = 3;
}
$MonthOffset{3} = 3;
$MonthOffset{4} = 6;
$MonthOffset{5} = 1;
$MonthOffset{6} = 4;
$MonthOffset{7} = 6;
$MonthOffset{8} = 2;
$MonthOffset{9} = 5;
$MonthOffset{10} = 0;
$MonthOffset{11} = 3;
$MonthOffset{12} = 5;

$TwoDigitYear = $YearDate - 2000;
$YearFactor = int($TwoDigitYear / 4);
$MonthFactor = $MonthOffset{$MonthDate};
$SumOfFactors = $CenturyFactor + $TwoDigitYear + $YearFactor + $MonthFactor + $DayDate;
$DayOffset = $SumOfFactors - (int($SumOfFactors / 7) * 7);

$DayOfWeek{0} = "Sunday";
$DayOfWeek{1} = "Monday";  
$DayOfWeek{2} = "Tuesday";  
$DayOfWeek{3} = "Wednesday"; 
$DayOfWeek{4} = "Thursday";
$DayOfWeek{5} = "Friday";
$DayOfWeek{6} = "Saturday"; 

$DayOfWeekString = $DayOfWeek{$DayOffset};

print $DayOfWeekString."\n";
