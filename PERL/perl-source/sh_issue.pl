#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_issue.pl
#------ Authors Name : Mark Roberts
#------ Date         : 20 January, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      add a label called ISSUED to files.
#                      The script is supplied an argument of the file to
#                      be processed.
#
# Variable declaration.
#
$LabelName = "ISSUED";
$AttributeName = "EditAllowed";
#
$EnvTemp = $ENV{'TEMP'};
#
if (length($EnvTemp) == 0)
{
    $EnvTemp = $ENV{'temp'};
}
if (length($EnvTemp) == 0)
{
    $EnvTemp = $ENV{'TMP'};
}
if (length($EnvTemp) == 0)
{
    $EnvTemp = $ENV{'tmp'};
}
if (length($EnvTemp) == 0)
{
#
    print "\n\n ERROR : Could not find one of the following environment variables\n";
    print "        temp, TEMP, tmp, TMP\n";
    exit(0);
}
#
# Get the file to be processed from the command line.
#
$FileToProcess = $ARGV[0];
$ResultFile = $ARGV[1];
#
$IssueSearchCommand = "cleartool find $FileToProcess -directory".
                      " -version {lbtype($LabelName)} -print";
$IssueSearchResult = `$IssueSearchCommand`;
$IssueSearchResult =~ s/"//g;
#
# Check if the file is curently checkedout.
# The command should not be allowed if the file is checkedout.
#
$CheckoutListCommand = "cleartool lsco $FileToProcess";
$CheckoutListResult = `$CheckoutListCommand`;
#
if (length($CheckoutListResult) > 0)
{
#   The file is currently checked out.
#
    $ResultStatus = 0;
}
else
{
#
    if (length($IssueSearchResult) > 0)
    {
#
#       The label is already present on the element. Replace the old position  of the label.
#
        $ReplaceLabelCommand = "cleartool mklabel -replace -nc $LabelName ".$FileToProcess;
#
        $ReplaceLabelCommandResult = `$ReplaceLabelCommand`;
        $ReplaceLabelCommandResult =~ s/\"\.//g;
        $ReplaceLabelCommandResult =~ s/\"//g;
#
        if ($? == 0)
        {
#           Label replacement successful.
#
            $ResultStatus = "1";
        }
        else
        {
#           Label replacement failed.
#
            $ResultStatus = "2";
        }
    }
    else
    {
#
        $AddLabelCommand = "cleartool mklabel -nc $LabelName ".$FileToProcess;
#
        $AddLabelCommandResult = `$AddLabelCommand`;
        $AddLabelCommandResult =~ s/\"\.//g;
        $AddLabelCommandResult =~ s/\"//g;
#
        if ($? == 0)
        {
#           Label addition successful.
#
            $ResultStatus = "3";
        }
        else
        {
#           Label addition failed.
#
            $ResultStatus = "4";
        }
    }
}
#
# Add the EditAllowed attribute to file elements only with a value of "NO".
#
SWITCH:
{
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 013\n"; }
#   If the attribute has been added or replaced successfully then add the attribute.
#
    if ((($ResultStatus cmp "1") == 0) || (($ResultStatus cmp "3") == 0))
    {
#
#       Check if the element is a file or a directory.
#
        $DescribeCommand = "cleartool describe ".$FileToProcess;
        $DescribeResult = `$DescribeCommand`;
#
        $_ = $DescribeResult;
#
#       Search for the string element type: directory
#
        if (!(m/element type: directory/))
        {
#
            $AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                                  " -element {attype($AttributeName)} -print";
            $AttributeSearchResult = `$AttributeSearchCommand`;

            if (length($AttributeSearchResult) > 0)
            {
#               EditAllowed attribute already present on the element. Replace the old value.
#
                $NewAttributeValue = "NO";
                $ChangeAttributeCommand = "cleartool mkattr -replace -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";
#
#               Execute the change attribute command.
#
                `$ChangeAttributeCommand`;
#
            }
            else
            {
#               The attribute is not currently present.
#
                $NewAttributeValue = "NO";
                $ChangeAttributeCommand = "cleartool mkattr -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";

                `$ChangeAttributeCommand`;
#
            }
            last SWITCH;
        }
    }
    $Nothing = 1;
}
#
# Make the ResultFile writeable.
#
$ResultFile = ">".$ResultFile;
open (ResultFileHandle, $ResultFile);
#
# Print the find result.
#
SWITCH:
{
    if (($ResultStatus cmp "0") == 0)
    {
#
        print ResultFileHandle "CHECKEDOUT\n";
        last SWITCH;
    }
    if (($ResultStatus cmp "1") == 0)
    {
#
        print ResultFileHandle "FindResult".$IssueSearchResult;
        print ResultFileHandle "REPLACED".$ReplaceLabelCommandResult;
        last SWITCH;
    }
    if (($ResultStatus cmp "2") == 0)
    {
#
        print ResultFileHandle "REPLACEMENT_FAILED\n";
        last SWITCH;
    }
    if (($ResultStatus cmp "3") == 0)
    {
#
        print ResultFileHandle "ADDED".$AddLabelCommandResult;
        last SWITCH;
    }
    if (($ResultStatus cmp "4") == 0)
    {
#
        print ResultFileHandle "ADDITION_FAILED\n";
        last SWITCH;
    }
    $Nothing = 1;
}
#
close ResultFileHandle;
