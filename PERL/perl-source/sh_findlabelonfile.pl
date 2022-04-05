#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_findlabelonfile.pl
#------ Authors Name : Mark Roberts
#------ Date         : 7 May, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      Search for the version of a file that contains a
#                      particular label.
#                      Argument one : The name of the file to search for, or . for
#                                     any file.
#                      Argument two : The path to search.
#                      Argument three : The name of the Label.
#                      Argument three : The name of the file to hold the results.
#                      Argument four : Indication of whether to include the verison
#                                      numbers or not : 0 = no, 1 = yes
#
# Get argument;
#
$SearchFileName = $ARGV[0];
$SearchPath = $ARGV[1];
$LabelName = $ARGV[2];
$ResultFile = $ARGV[3];
$VersionDetails = $ARGV[4];
#
# Check for a \ on the end of the line.
#
$ChopChar = chop($SearchPath);
$_ = $ChopChar;
if (m/\\/)
{
    $SearchPath = $SearchPath."\\";
}
else
{
    $SearchPath = $SearchPath.$ChopChar."\\";
}
# Find command.
$_ = $SearchFileName;
if (m/./)
{
    print "Search of ".$SearchPath." for Label ".$LabelName."\n";
    $Result = "Search of ".$SearchPath." for Label ".$LabelName."\n";
}
else
{
    print "Search of ".$SearchPath.$SearchFileName." for Label ".$LabelName."\n";
    $Result = "Search of ".$SearchPath.$SearchFileName." for Label ".$LabelName."\n";
}
#
if (($VersionDetails cmp "0") == 0)
{
    $FindCommand = "cleartool find ".$SearchPath.$SearchFileName." -nxname -version {lbtype_sub(".$LabelName.")} -print";
}
else
{
    $FindCommand = "cleartool find ".$SearchPath.$SearchFileName." -version {lbtype_sub(".$LabelName.")} -print";
}
print $FindCommand."\n";
$FindResult = `$FindCommand`;
if (length($FindResult) > 0)
{
    $Result = $Result.$FindResult;
}
else
{
    print "Label NOT found \n";
    $Result = $Result."Label NOT found \n";
}
#
$ResultFile = ">".$ResultFile;
#
open(ResultFileHandle, $ResultFile);
print ResultFileHandle $Result;
close(ResultFileHandle);




