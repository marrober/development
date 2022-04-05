$PVOBTag = "/vobs/Symbian-PVOB";
$VOBStorageLocation = "/opt";
$VIEWStorageLocation = "/opt/views";
$ViewTag = "MkComponents";

# Make the PVOB.

$MkPVOBCmd = "cleartool mkvob -tag ".$PVOBTag." -ucmproject -nc -public -password rational ".$VOBStorageLocation.$PVOBTag.".vbs";
$ProtectPVOBCmd = "cleartool protectvob -force -add_group cclondon,ccbangl,ccbej ".$VOBStorageLocation.$PVOBTag.".vbs";

print `$MkPVOBCmd`;
print `$ProtectPVOBCmd`;

# Mount the PVOB.

$MountPVOBCmd = "cleartool mount ".$PVOBTag;
print `$MountPVOBCmd`;

# Make a view from which to create the components.

$MkViewCmd = "cleartool mkview -tag ".$ViewTag." ".$VIEWStorageLocation."/".$ViewTag.".vws";

print `$MkViewCmd`;

