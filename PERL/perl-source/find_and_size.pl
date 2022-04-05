use Time::Local;

$StartDate = @ARGV[0];
$StartTime = @ARGV[1];
$EndDate =   @ARGV[2];
$EndTime =   @ARGV[3];
$Interval =  @ARGV[4];

push(@Months, "Jan");
push(@Months, "Feb");
push(@Months, "Mar");
push(@Months, "Apr");
push(@Months, "May");
push(@Months, "Jun");
push(@Months, "Jul");
push(@Months, "Aug");
push(@Months, "Sep");
push(@Months, "Oct");
push(@Months, "Nov");
push(@Months, "Dec");


@StartDate = split("\/", $StartDate);
@StartTime = split(":", $StartTime);

$StartTime = timegm(00, @StartTime[1], @StartTime[0], @StartDate[0], (@StartDate[1]-1), @StartDate[2]);

@EndDate = split("\/", $EndDate);
@EndTime = split(":", $EndTime);

$EndTime = timegm(00, @EndTime[1], @EndTime[0], @EndDate[0], (@EndDate[1]-1), @EndDate[2]);

$TotalSize = 0;
$TotalVersionCounter = 0;	

for ($SearchStartTime = $StartTime; $SearchStartTime < $EndTime; $SearchStartTime += ($Interval * 60))
{
	$Size = 0;
	$VersionCounter = 0;	

	($SSec, $SMin, $SHour, $SMDay, $SMon, $SYear, $SWDay, $SYDay, $SDS) = gmtime($SearchStartTime);

	$SMDay = LeadingZero($SMDay);
	$SMon = LeadingZero($SMon+1);
	$SYear = $SYear + 1900;
	$SHour = LeadingZero($SHour);
	$SMin = LeadingZero($SMin);
	

	print $SMDay."/".$SMon."/".$SYear." ".$SHour.":".$SMin.",";


	$SearchEndTime = $SearchStartTime + ($Interval * 60);

	($ESec, $EMin, $EHour, $EMDay, $EMon, $EYear, $EWDay, $EYDay, $EDS) = gmtime($SearchEndTime);

	$EMDay = LeadingZero($EMDay);
	$EMon = LeadingZero($EMon+1);
	$EYear = $EYear + 1900;
	$EHour = LeadingZero($EHour);
	$EMin = LeadingZero($EMin);

	print $EMDay."/".$EMon."/".$EYear." ".$EHour.":".$EMin."," ;

	$CTFindCmd = "cleartool find . -all -version \"{created_since(".$SMDay."-";
	$CTFindCmd .= @Months[$SMon-1]."-".$SYear.".".$SHour.":".$SMin.":00) && (!created_since(";
	$CTFindCmd .= $EMDay."-".@Months[$SMon-1]."-".$EYear.".".$EHour.":".$EMin.":00))}\" -print";

	$Result = `$CTFindCmd`;

	@SplitResults = split("\n", $Result);

	foreach $Line (@SplitResults)
	{
		$VersionID = substr($Line, rindex("\\", $Line));

		if (($VersionID cmp "0") != 0) 
		{
			# print $Line."\n";		
			$DirCmd = "dir /-C \"".$Line."\"";

			$DirResult = `$DirCmd`;

			# print $DirResult."\n";

			@ResultLines = split("\n", $DirResult);

			foreach $_ (@ResultLines)
			{
				if ((m/bytes/) && (!/bytes free/) && (/1 File/))
				{
					1 while (s/  / /g);
					@SplitSizeLine = split(" ", $_);
					$Size += @SplitSizeLine[2]."\n";
					$VersionCounter++;
				}
			}
		}
	}
	print $Size.",".$VersionCounter."\n";
	$TotalVersionCounter += $VersionCounter;
	$TotalSize += $Size;
	$IntervalCounter++;

}

$AverageVersionCreated = sprintf("%.2f", $TotalSize / $TotalVersionCounter);
$AveragePerInterval = sprintf("%.2f", $TotalSize / $IntervalCounter);
$AverageVersionsPerInterval = sprintf("%.2f", $TotalVersionCounter / $IntervalCounter);

print "Average version size : ".$AverageVersionCreated."\n";
print "Average volume per Interval : ".$AveragePerInterval."\n";
print "Average number of versions per Interval : ".$AverageVersionsPerInterval."\n";



exit(0);


sub LeadingZero()
{
	my($Val) = @_;

	if ($Val < 10) 
	{
		$ReturnVal = "0".$Val;
	} 
	else 
	{ 
		$ReturnVal  = $Val; 
	}
	$Val = "";
	return($ReturnVal);
}

