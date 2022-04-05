$PVOBTag = "/vobs/Symbian-PVOB";
$VOBStorageLocation = "/opt";
$VIEWStorageLocation = "/opt/views";
$MCLProjectFolder = "MCL_Projects";
$MCLProjectName = "MCL_Project_All";


$ViewTag = "MkComponents";

@ComponentList = qw(app-engines app-framework app-services application-protocols base bluetooth comms-infras connectivity Content-Handling devprov graphics infra-red j2me LBS messaging mm-protocols mtp multimedia nbprotocols networking obex openenv security ser-comms syncml syslibs SystemTest telephony tools usb utils wap-browser wap-stack);

foreach $ComponentName (@ComponentList) {
	$CompVOBTag = "/vobs/".$ComponentName;

	$MkComponentVOBCmd = "cleartool mkvob -tag ".$CompVOBTag." -nc -public -password rational ".$VOBStorageLocation.$CompVOBTag.".vbs";
	$ProtectComponentVOBCmd = "cleartool protectvob -force -add_group cclondon,ccbangl,ccbej ".$VOBStorageLocation.$CompVOBTag.".vbs";
	$MountComponentVOBCmd = "cleartool mount ".$CompVOBTag;
	$MkComponentCmd = "cleartool mkcomp -nc -root ".$CompVOBTag." ". $ComponentName."@".$PVOBTag;

	print `$MkComponentVOBCmd`;
	print `$ProtectComponentVOBCmd`;
	print `$MountComponentVOBCmd`;
	print `$MkComponentCmd`;
}

# Create a folder to store projects in the PVOB.

$MKProjectFolderCmd = "cleartool mkfolder -in RootFolder ".$MCLProjectFolder."@".$PVOBTag;
print `$MKProjectFolderCmd`;

# Create the Project for MCL.

$MkProjectCmd = "cleartool mkproject -nc -in ".$MCLProjectFolder." ".$MCLProjectName."@".$PVOBTag;
print `$MkProjectCmd`;

# Create the integration stream.

$MkIntegrationStreamCmd = "cleartool mkstream -integration -in ".$MCLProjectName." ".$MCLProjectName."_integration@".$PVOBTag;
print `$MkIntegrationStreamCmd`;

# Create an integration view.

$MkIntegrationViewCmd = "cleartool mkview -tag ".$MCLProjectName."_integration_View -stream ".$MCLProjectName."_integration@".$PVOBTag." ".$VIEWStorageLocation."/".$MCLProjectName."_integration_View.vws";
print `$MkIntegrationViewCmd`;

$RebsaeCompleteCmd = "cleartool rebase -view ".$MCLProjectName."_integration_View -complete";

foreach $ComponentName (@ComponentList) {
	$RebaseStartCmd = "cleartool rebase -baseline ".$ComponentName."_INITIAL@".$PVOBTag." -stream ".$MCLProjectName."_integration@".$PVOBTag;	
	print `$RebaseStartCmd`;
	print `$RebsaeCompleteCmd`;
}

