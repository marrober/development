my @TimeArray = localtime(time);

$StartDate = "2007-11-21 00:00:00";
$EndDate = "2008-01-01 00:00:00";

$CurrentDate = (@TimeArray[5] + 1900)."-".sprintf("%02d", @TimeArray[4] + 1)."-".sprintf("%02d", @TimeArray[3]);

$Time = sprintf("%02d", @TimeArray[2]).":".sprintf("%02d", @TimeArray[1]).":".sprintf("%02d", @TimeArray[0]);

$CurrentDate = $CurrentDate." ".$Time;
print "Current time : ".$CurrentDate."\n";
print "Start time   : ".$StartDate."\n";
print "End time     : ".$EndDate."\n";

$StartDate = substr($StartDate, 0, index($StartDate, " "));
$EndDate = substr($EndDate, 0, index($EndDate, " "));
$CurrentDate = substr($CurrentDate, 0, index($CurrentDate, " "));

@StartDate = split("-", $StartDate);
@EndDate = split("-", $EndDate);
@CurrentDate = split("-", $CurrentDate);

$DatesWithinRange = 0;

$StartDateOK = 0;
if (@CurrentDate[0] > $StartDate[0]) {
	$StartDateOK = 1;
} elsif ((@CurrentDate[0] == $StartDate[0]) && (@CurrentDate[1] > $StartDate[1])) {
	$StartDateOK = 1;
} elsif ((@CurrentDate[0] == $StartDate[0]) && (@CurrentDate[1] == $StartDate[1]) && (@CurrentDate[2] >= $StartDate[2])) {
	$StartDateOK = 1; 
}

$EndDateOK = 0;
if (@CurrentDate[0] < $EndDate[0]) {
	$EndDateOK = 1;
} elsif ((@CurrentDate[0] == $EndDate[0]) && (@CurrentDate[1] < $EndDate[1])) {
	$EndDateOK = 1;
} elsif ((@CurrentDate[0] == $EndDate[0]) && (@CurrentDate[1] == $EndDate[1]) && (@CurrentDate[2] <= $EndDate[2])) {
	$EndDateOK = 1; 
}

if (($StartDateOK + $EndDateOK) == 2) {
	print "Date OK\n";
} else {
	print "Date Failed\n";
}

