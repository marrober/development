$CurrentActivity = $ENV{'CLEARCASE_ACTIVITY'};
$CurrentStream = `cleartool lsstream -s`;
$EPN = $ENV{'CLEARCASE_XPN'};
$PN = $ENV{'CLEARCASE_PN'};
$PN = substr($PN, index($PN, $ENV{'CLEARCASE_VOB_PN'}));
$EPN = substr($EPN, index($EPN, $ENV{'CLEARCASE_VOB_PN'}));
$ViewTag = $ENV{'CLEARCASE_VIEW_TAG'};
$CheckoutAllowed = 0;

$CurrentActivity = substr($CurrentActivity, 0, index($CurrentActivity, "@"));

$DependencyCheckingRequiredCmd = "cleartool desc -fmt %NS[DependencyCheckRequired]a stream:".$CurrentStream;
$DependencyCheckingRequired = `$DependencyCheckingRequiredCmd`;
$DependencyCheckingRequired =~ s/\"//g;

if ($DependencyCheckingRequired eq "YES") {
	print "Dependency checking required on this stream\n";
	$ActivitiesInStream = `cleartool lsact -s`;

	$DeliveredActivitiesCmd = "cleartool desc -fmt %NS[DeliveredActivities]a stream:".$CurrentStream;
	$DeliveredActivities = `$DeliveredActivitiesCmd`;
	$DeliveredActivities =~ s/\"//g;
	@ActivitiesInStreamList = split("\n", $ActivitiesInStream);
	@DeliveredActivitiesList = split("\,", $DeliveredActivities);
	
	foreach $ActivityInStream (@ActivitiesInStreamList) {
		$Found = 0;
		foreach $DeliveredActivity (@DeliveredActivitiesList) {
			if ($ActivityInStream eq $DeliveredActivity) {
				$Found = 1;
			}
		}
		if ($Found == 0) {
			push(@UndeliveredActivityList, $ActivityInStream);
		}
		$Found = 0;
	}
	
	foreach $UndeliveredActivity (@UndeliveredActivityList) {
		if ($UndeliveredActivity ne $CurrentActivity) {
			$ChangeSetCmd = "cleartool lsact -fmt \"%[versions]p\" ".$UndeliveredActivity;
			$ChangeSet = `$ChangeSetCmd`;
			$_ = $ENV{'OS'};
			if (m/Windows/) {
				@ElementArray = split(/ \\/, $ChangeSet);
				foreach $Element (@ElementArray) {
					if (substr($Element, 0, 1) ne "\\") {
						$Element = "\\".$Element;
					}
					$Elements{$Element} = $UndeliveredActivity;
				}		
			}
			else {
				@ElementArray = split(/ \//, $ChangeSet);
				foreach $Element (@ElementArray) {
					if (substr($Element, 0, 1) ne "\/") {
						$Element = "\/".$Element;
					}
					# Remove the view tag from the file name.
					if (index($Element, $ViewTag) >= 0) {
						$Element = substr($Element, index($Element, $ViewTag) + length($ViewTag));
					}
					$Elements{$Element} = $UndeliveredActivity;
				}				
			}				
		}			
	}
	$ElementInAChangeSet = 0;
	foreach $key (keys %Elements) {
		($ElementName, $BranchVersion) = split("@@", $key);
		if ($ElementName eq $PN) {
			$ElementInAChangeSet = 1;
			$ActivityToReport = $Elements{$key};
		}		
	}
	if ($ElementInAChangeSet == 1) {
		$ClearPromptCmd = "clearprompt yes_no -prompt \"warning: File already checked out to an ";
		$ClearPromptCmd .= "undelivered activity (".$ActivityToReport."). Select 'yes' to continue ";
		$ClearPromptCmd .= "checkout, or 'no' to cancel\"  -prefer_gui -type \"warning\"";
		$ClearPromptCmd .= " -default \"no\" -mask \"yes\"";
		
		`$ClearPromptCmd`;
		$CheckoutAllowed = $?;
		if ($CheckoutAllowed != 0) {
			$CheckoutAllowed = 1;
		}
	}
}
exit ($CheckoutAllowed);

