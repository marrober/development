my @TimeArray = localtime(time);

if (@TimeArray[3] < 10) { $DateTime =  "0".@TimeArray[3]; } else { $DateTime =  @TimeArray[3]; }
if (@TimeArray[4] < 10) { $DateTime .= "0".(@TimeArray[4] + 1); } else { $DateTime .= (@TimeArray[4] + 1); }
$DateTime .= ".";
if (@TimeArray[2] < 10) { $DateTime .= "0".@TimeArray[2]; } else { $DateTime .= @TimeArray[2]; }
if (@TimeArray[1] < 10) { $DateTime .= "0".@TimeArray[1]; } else { $DateTime .= @TimeArray[1]; }

# Get view

$ViewSelectionFilterCmd = "cleartool lsview -s \"ProgPair*_integration*\"";
$ViewList = `$ViewSelectionFilterCmd`;
$ViewList =~ s/\n/,/g;

$TempViewFile = "c:\\temp\\view.txt";
$TempProjectFile = "c:\\temp\\project.txt";
$TempComponentFile = "c:\\temp\\component.txt";

$ViewSelectionCmd = "clearprompt list -outfile ".$TempViewFile." -items ".$ViewList." -prompt \"Select the appropriate integration view.\"";
$ViewSelectionResult = `$ViewSelectionCmd`;

open ViewFileHandle, $TempViewFile;

while (eof(ViewFileHandle) == 0)
 {
     read ViewFileHandle, $DataFromFile, 25;
    $ViewName = join('',$ViewName, $DataFromFile);
}

close ViewFileHandle;
$ViewName =~ s/\n//g;
print $ViewName."\n";

# Get Project

$ProjectListCmd = "cleartool lsproject -s -invob \\project";
$ProjectList = `$ProjectListCmd`;
$ProjectList =~ s/\n/,/g;

$ProjectSelectionCmd = "clearprompt list -outfile ".$TempProjectFile." -items ".$ProjectList." -prompt \"Select the appropriate project.\"";
$ProjectSelectionResult = `$ProjectSelectionCmd`;

open ProjectFileHandle, $TempProjectFile;

while (eof(ProjectFileHandle) == 0)
 {
     read ProjectFileHandle, $DataFromFile, 25;
    $ProjectName = join('',$ProjectName, $DataFromFile);
}

close ProjectFileHandle;
$ProjectName =~ s/\n//g;
print $ProjectName."\n";

# Get Component

$ComponentListCmd = "cleartool lscomp -s -invob \\project";
$ComponentList = `$ComponentListCmd`;
$ComponentList =~ s/\n/,/g;

$ComponentSelectionCmd = "clearprompt list -outfile ".$TempComponentFile." -items ".$ComponentList." -prompt \"Select the appropriate component.\"";
$ComponentSelectionResult = `$ComponentSelectionCmd`;

open ComponentFileHandle, $TempComponentFile;

while (eof(ComponentFileHandle) == 0)
 {
     read ComponentFileHandle, $DataFromFile, 25;
    $ComponentName = join('',$ComponentName, $DataFromFile);
}

close ComponentFileHandle;
$ComponentName =~ s/\n//g;
print $ComponentName."\n";

$Baseline = $ProjectName."_".$DateTime;

print $Baseline."\n";

$MkBlCmd = "cleartool mkbl -nc -view ".$ViewName." -component ".$ComponentName."@\\project -full ".$Baseline;

$MkBlResult = `$MkBlCmd`;
$ResultDisplayCmd = "clearprompt proceed -type \"ok\" -mask \"proceed\" -prompt \"".$MkBlResult."\"";
`$ResultDisplayCmd`;

