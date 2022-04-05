print "-----------------------------------------------------------------------\n";
print " Keep only the last three versions of a versioned derived object\n\n";
$VersionString = $ENV{'CLEARCASE_ID_STR'};
@SplitVersionString = split(/\\/, $VersionString);

print "Element ".$ENV{'CLEARCASE_PN'}." has ".@SplitVersionString[$#SplitVersionString]. " versions\n";

$Partial = "@@/";

for ($SectionCounter = 1; $SectionCounter < $#SplitVersionString; $SectionCounter++) {
	$Partial = $Partial.@SplitVersionString[$SectionCounter]."/";
}

if (@SplitVersionString[$#SplitVersionString] > 3) {
	$RmDataCommand = "cleartool rmver -force -data ".$ENV{'CLEARCASE_PN'}.$Partial.(@SplitVersionString[$#SplitVersionString] - 3);
	print "Removing the data from version ".$Partial.(@SplitVersionString[$#SplitVersionString] - 3)."\n";
	print $RmDataCommand."\n";
	`$RmDataCommand`;
}
