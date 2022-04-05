$CurrentActivity = $ENV{'CLEARCASE_ACTIVITY'};
$CurrentStream = $ENV{'CLEARCASE_SRC_STREAM'};
$DeliveredActivitiesCmd = "cleartool desc -fmt %NS[DeliveredActivities]a stream:".$CurrentStream;
$DeliveredActivities = `$DeliveredActivitiesCmd`;

$CurrentActivity = substr($CurrentActivity, 0, index($CurrentActivity, "@"));

$ChildActivitiesCmd = "cleartool lsact -contrib ".$CurrentActivity;
$ChildActivities = `$ChildActivitiesCmd`;
$ChildActivities =~ s/\"//g;
@ChildActivitiesArray = split("\n", $ChildActivities);

if (length($DeliveredActivities) > 0) {
	$DeliveredActivities =~ s/\"//g;
	@DeliveredActivitiesArray = split("\,", $DeliveredActivities);
	$ActivityRecorded = 0;
	$ActivitiesToRecord = 0;
	$ChildToRecord = "";
	foreach $ChildActivity (@ChildActivitiesArray) {
		foreach $DelActivity (@DeliveredActivitiesArray) {
			if ($ChildActivity eq $DelActivity) {
				$ActivityRecorded = 1;
			}
		}
		if ($ActivityRecorded == 0) {
			if (length($ChildToRecord) > 0) {
				$ChildToRecord .= ",".$ChildActivity;
			}
			else {
				$ChildToRecord = $ChildActivity;
			}
			$ActivitiesRecorded++;
		}
		$ActivityRecorded = 0;
	}
	if ($ActivityRecorded == 0) {
		$MkAttrCmd = "cleartool mkattr -replace DeliveredActivities \\\"".$DeliveredActivities;
		$MkAttrCmd .= ",".$ChildToRecord."\\\" stream:".$CurrentStream;
	}
}
else {
	$ChildToRecord = "";
	foreach $ChildActivity (@ChildActivitiesArray) {
		if (length($ChildToRecord) > 0) {
			$ChildToRecord .= ",".$ChildActivity;
		}
		else {
			$ChildToRecord = $ChildActivity;
		}	
	}	
	$MkAttrCmd = "cleartool mkattr DeliveredActivities \\\"".$ChildToRecord."\\\" stream:".$CurrentStream;
}
`$MkAttrCmd`;