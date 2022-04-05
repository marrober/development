#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_grant_edit.pl
#------ Authors Name : Mark Roberts
#------ Date         : 4 March, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      add an attribute called EditAllowed to a file.
#                      The script is supplied an argument of the file to
#                      be processed.
#
# Variable declaration.
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
# Get the file to be processed from the command line. if a command line argument is
# not given then get the name from a prompt.
#
$FileToProcess = $ARGV[0];
$ResultFile = $ARGV[1];
#
$AttributeName = "EditAllowed";
#
$AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                  " -element {attype($AttributeName)} -print";
$AttributeSearchResult = `$AttributeSearchCommand`;
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
    if (length($AttributeSearchResult) > 0)
    {
#
#       EditAllowed attribute already present on the element. Replace the old value.
#
        $NewAttributeValue = "YES";
        $ChangeAttributeCommand = "cleartool mkattr -replace -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";
#
#       Execute the change attribute command.
#
        `$ChangeAttributeCommand`;
#
        if ($? == 0)
        {
#           The attribute value has been successfully replaced.
#
            $ResultStatus = 1;
        }
        else
        {
#           The attribute change failed.
#
            $ResultStatus = 2;
        }
    }
    else
    {
#
#       The attribute is not currently present.
#
        $NewAttributeValue = "YES";
        $ChangeAttributeCommand = "cleartool mkattr -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";

        `$ChangeAttributeCommand`;
#
        if ($? == 0)
        {
#
#           The attribute value has been successfully added.
#
            $ResultStatus = 3;
        }
        else
        {
#           The attribute addition failed.
#
            $ResultStatus = 4;
        }
    }
}
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
        print ResultFileHandle "CHECKEDOUT\n";
        last SWITCH;
    }
    if (($ResultStatus cmp "1") == 0)
    {
        print ResultFileHandle "SUCCESSFULLY_REPLACED\n";
        last SWITCH;
    }
    if (($ResultStatus cmp "2") == 0)
    {
        print ResultFileHandle "REPLACEMENT_FAILED\n";
        last SWITCH;
    }
    if (($ResultStatus cmp "3") == 0)
    {
        print ResultFileHandle "SUCCESSFULLY_ADDED\n";
        last SWITCH;
    }
    if (($ResultStatus cmp "4") == 0)
    {
        print ResultFileHandle "ADDITION_FAILED\n";
        last SWITCH;
    }
    $Nothing = 1;
}
#
close ResultFileHandle;
