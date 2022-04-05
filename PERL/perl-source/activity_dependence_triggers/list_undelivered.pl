$NoCSFlag = 0;
$CommaSeparated = 0;
foreach $_ (@ARGV) {
	if (m/-nocs/) {
		$NoCSFlag = 1;
	}
	if (m/-comma/) {
		$CommaSeparated = 1;
		$NoCSFlag = 1;
	}
}

$CurrentStream = `cleartool lsstream -s`;
$ActivitiesInStream = `cleartool lsact -fmt \"%n : %NS[headline]p\\n\"`;

$DeliveredActivitiesCmd = "cleartool desc -fmt %NS[DeliveredActivities]a stream:".$CurrentStream;
$DeliveredActivities = `$DeliveredActivitiesCmd`;
$DeliveredActivities =~ s/\"//g;
@ActivitiesInStreamList = split("\n", $ActivitiesInStream);
@DeliveredActivitiesList = split("\,", $DeliveredActivities);

foreach $ActivityInStream (@ActivitiesInStreamList) {
	$Found = 0;
	$ActivityID = substr($ActivityInStream, 0, index($ActivityInStream, " : "));
	foreach $DeliveredActivity (@DeliveredActivitiesList) {
		if ($ActivityID eq $DeliveredActivity) {
			$Found = 1;
		}
	}
	if ($Found == 0) {
		push(@UndeliveredActivityList, $ActivityInStream);
	}
	$Found = 0;
}

foreach $UndeliveredActivity (@UndeliveredActivityList) {
	$ActivityID = substr($UndeliveredActivity, 0, index($UndeliveredActivity, " : "));
	$ActivityTitle = substr($UndeliveredActivity, index($UndeliveredActivity, " : ") + 3);
	if ($ActivityID ne $CurrentActivity) {
		if ($CommaSeparated == 1) {
			print $ActivityID.",";
		}
		else {
			print "Undelivered activity : ".$ActivityID." : ".$ActivityTitle."\n";
		}
		if ($NoCSFlag == 0) {
			$ChangeSetCmd = "cleartool lsact -fmt \"%[versions]p\" ".$ActivityID;
			$ChangeSet = `$ChangeSetCmd`;
			$_ = $ENV{'OS'};
			if (m/Windows/) {
				@ElementArray = split(/ \\/, $ChangeSet);
				foreach $Element (@ElementArray) {
					if (substr($Element, 0, 1) ne "\\") {
						$Element = "\\".$Element;
					}				
					print "\t\t".$Element."\n";
				}
			}
			else {
				@ElementArray = split(/ \//, $ChangeSet);
				foreach $Element (@ElementArray) {
					if (substr($Element, 0, 1) ne "\/") {
						$Element = "\/".$Element;
					}				
					print "\t\t".$Element."\n";
				}
			}	
		}		
	}			
}
if ($CommaSeparated == 1) {
	print "\n";
}
