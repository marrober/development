$VOB_List = `cleartool lsvob -s`;
@VOB_Array = split ("\n", $VOB_List);

$DiskSpaceTotal = 0;

foreach $VOB (@VOB_Array) {
	
	$SpaceResult_Text = `cleartool space -vob $VOB`;
	@SpaceResult_Array = split("\n", $SpaceResult_Text);
	
	foreach $_ (@SpaceResult_Array) {
		if (m/VOB database/) {
			while (m/  /) {
				$_ =~ s/  / /g;
				$_ =~ s/^ //;
				$VOB_DB_DiskSpace = substr($_, 0, index($_, " "));
			}
			print "VOB ".$VOB." : ".$VOB_DB_DiskSpace." Mb\n";
			$DiskSpaceTotal += $VOB_DB_DiskSpace;
		}
	}
}
print "Total VOB database size is : ".$DiskSpaceTotal."Mb\n";
$RAMReq = $DiskSpaceTotal / 2;
print "RAM Requirement on the server to cache the VOB databases correctly is at least ".$RAMReq." Mb\n";
print "This figure needs to increase to enable the operating system and ClearCase processes to run.\n";
print "It is intended to be a guide to enable administrators to evaluate the required amount of RAM\n";