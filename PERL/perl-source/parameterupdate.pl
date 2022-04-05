$InputFile = @ARGV[0];
$OutputFile = ">".@ARGV[1];
$L1T = @ARGV[2];
$L1N = @ARGV[3];
$L2T = @ARGV[4];
$L2N = @ARGV[5];
$ML2 = @ARGV[6];
$L2L = @ARGV[7];
$L2R = @ARGV[8];
$L3T = @ARGV[9];
$L3N = @ARGV[10];
$OBT = @ARGV[11];
$NeV = @ARGV[12];

$RequiredLevel = 3;

if ($L3T eq "-Blank-")
{
    $RequiredLevel = 2;
}
if ($L2T eq "-Blank-")
{
    $RequiredLevel = 1;
}

if (index($L1T, "\[") >= 0) {	$L1T =~ s/\[/\\\[/; }
if (index($L1T, "\]") >= 0) {	$L1T =~ s/\]/\\\]/; }
if (index($L2T, "\[") >= 0) {	$L2T =~ s/\[/\\\[/; }
if (index($L2T, "\]") >= 0) {	$L2T =~ s/\]/\\\]/; }
if (index($L3T, "\[") >= 0) {	$L3T =~ s/\[/\\\[/; }
if (index($L3T, "\]") >= 0) {	$L3T =~ s/\]/\\\]/; }

print $RequiredLevel."\n";

print $InputFile." ".$OutputFile." ".$L1T.":".$L1N." ".$L2T.":".$L2N." ".$L3T.":".$L3N." :: ".$OBT." = ".$NeV."\n";

$LogFile = ">c:\\temp\\log.txt";
open LOG, $LogFile;
print LOG $InputFile." ".$OutputFile." ".$L1T.":".$L1N." ".$L2T.":".$L2N." ".$L3T.":".$L3N." :: ".$OBT." = ".$NeV."\n";
close LOG;

open INPUT, $InputFile;
while(read(INPUT, $Buffer, 16384))
{
    $InputData .= $Buffer;
}
close INPUT;

@InputDataArray = split("\n", $InputData);

$L1TitlePassed = 0;
$L2TitlePassed = 0;
$L3TitlePassed = 0;
$L1NamePassed = 0;
$L2NamePassed = 0;
$L3NamePassed = 0;
$Tab = chr(9);

foreach $Line (@InputDataArray)
{
    $_ = $Line;
    print $_."\n";
    if (m/$L1T/)
    {
        $L1TitlePassed = 1;
    }
    if (m/^\[End\]/)
    {
        $L1TitlePassed = 0;
    }
    if (m/$L2T/)
    {
        $L2TitlePassed = 1;
    }
    if (m/^$Tab\[End\]/)
    {
        $L2TitlePassed = 0;
    }
    if (m/$L3T/)
    {
        $L3TitlePassed = 1;
    }
    if (m/^$Tab$Tab\[End\]/)
    {
        $L3TitlePassed = 0;
    }

    if ((m/$L1N/) && (m/Name = /))
    {
        $L1NamePassed = 1;
    }
    if (m/^\[End\]/)
    {
        $L1NamePassed = 0;
    }
    if ((m/$L2N/) && (m/Name = /))
    {
        $L2NamePassed = 1;
    }
    if (m/^$Tab\[End\]/)
    {
        $L2NamePassed = 0;
    }
    if (($L2L ne "-Blank-") && (m/$L2L/))
    {
        if (($L2R ne "-Blank-") && (m/$L2R/))
        {
            $L2NamePassed = 1;
        }
    }
    if ((m/$L3N/) && (m/Name = /))
    {
        $L3NamePassed = 1;
    }
    if (m/^$Tab$Tab\[End\]/)
    {
        $L3NamePassed = 0;
    }

    $ReplaceCandidate = 0;

    if (($RequiredLevel == 1) && ($L1TitlePassed == 1) && ($L1NamePassed == 1))
    {
        $ReplaceCandidate = 1;
    }
    if (($RequiredLevel == 2) && ($L1TitlePassed == 1) && ($L1NamePassed == 1) && ($L2TitlePassed == 1) && ($L2NamePassed == 1))
    {
        $ReplaceCandidate = 1;
    }
    if ($ML2 eq "1")
    {
        if (($RequiredLevel == 3) && ($L1TitlePassed == 1) && ($L1NamePassed == 1) && ($L2TitlePassed == 1)  && ($L2NamePassed == 1) && ($L3TitlePassed == 1) && ($L3NamePassed == 1))
        {
            $ReplaceCandidate = 1;
        }
    }
    else
    {
        if (($RequiredLevel == 3) && ($L1TitlePassed == 1) && ($L1NamePassed == 1) && ($L2TitlePassed == 1) && ($L3TitlePassed == 1) && ($L3NamePassed == 1))
        {
            $ReplaceCandidate = 1;
        }
    }

    if ($ReplaceCandidate == 1)
    {
        @LineParts = split("=", $_);
        $_ = @LineParts[0];
        $_ =~ s/(^$Tab{0,3}| )//g;

        if ((m/$OBT/) && (length($OBT) == length($_)))
        {
            $NewLine = @LineParts[0]."= ".$NeV."\n";
			print "NL : ".$NewLine."\n";
            $NewText .= $NewLine;

            if ($L2L ne "-Blank-")
            {
                $L2NamePassed = 0;
            }
        }
        else
        {
            $NewText .= $Line."\n";
        }
    }
	else
	{
    	$NewText .= $Line."\n";
	}

    print $L1TitlePassed."  ".$L1NamePassed." ".$L2TitlePassed."  ".$L2NamePassed." ".$L3TitlePassed."  ".$L3NamePassed."  ".$ReplaceCandidate."\n";
}

open OF, $OutputFile;
print OF $NewText;
close OF;

exit(0);






