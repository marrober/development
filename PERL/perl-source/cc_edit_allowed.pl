#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_edit_allowed.pl
#------ Authors Name : Mark Roberts
#------ Date         : 21 January, 1997.
#------ Description  : This script adds the Attribute Edit allowed to the root
#                      of the element. If the attribute is present then the
#                      user is prompted to change it from the current value to
#                      the other alternative. Options are : YES or NO.
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 001\n"; }
#
# Variable declaration.
#
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
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 002\n"; }
#
    print "\n\n ERROR : Could not find one of the following environment variables\n";
    print "        temp, TEMP, tmp, TMP\n";
    exit(0);
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 003\n"; }
#
# Get the file to be processed from the command line. if a command line argument is
# not given then get the name from a prompt.
#
$FileToProcess = $ARGV[0];
#
if (length($FileToProcess) == 0)
{
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 004\n"; }
#
    $HoldingFile = $EnvTemp."\\hold.tmp";
    `clearprompt file -outfile $HoldingFile -prompt "Select the name of a file to have the EditAllowed attribute."`;
#
# Get the name of the file to be processed.
#
    open(HoldingFileHandle, $HoldingFile);
    read(HoldingFileHandle, $FileToProcess, 1024);
    close(HoldingFileHandle);
#
# Remove the file that held the comment.
#
    `del $HoldingFile`;
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 005\n"; }
#
if (length($FileToProcess) == 0)
{
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 006\n"; }
#
    print "Exit - No file selected\n";
    exit(0);
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 007\n"; }
#
# Get a comment to be placed with the attribute attachment.
#
$HoldingFile = $EnvTemp."\\hold.tmp";
`clearprompt text -outfile $HoldingFile -prompt "Enter a comment for the attribute modification."`;
#
# Get the data from the file.
#
$AttributeModComment = "";
#
if (-e $HoldingFile)
{
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 008\n"; }
#
    open(HoldingFileHandle, $HoldingFile);
    read(HoldingFileHandle, $AttributeModComment, 1024);
    close(HoldingFileHandle);
#
# Remove the file that held the comment.
#
`del $HoldingFile`;
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 009\n"; }
#
$AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                  " -element {attype($AttributeName)} -print";
$AttributeSearchResult = `$AttributeSearchCommand`;
#
if (length($AttributeSearchResult) > 0)
{
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 010\n"; }
#
#   The attribute is already present on the element. Give the user the option
#   to change the value of the attribute.
#
#   Get the current value of the attribute.
#
    $AttributeSearchCommand = "cleartool find $FileToProcess"." -directory -element {attr_sub($AttributeName,==,".'\"'."YES".'\"'.")} -print";
    $AttributeSearchResult = `$AttributeSearchCommand`;
#
    if (length($AttributeSearchResult) > 0)
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 011\n"; }
#
#       The attribute is present and is currently set to YES.
#
        `clearprompt yes_no -type ok -mask yes,no -prompt "Currently $AttributeName is set to 'YES'. Change to 'NO' ?"`;

        if ($? == 0)
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 012\n"; }
#
#           User selected yes to change the value.
#
            $NewAttributeValue = "NO";
#
            if (length($AttributeModComment) > 0)
            {
#
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 013\n"; }
#
#               A comment is to be added with the command.

                $ChangeAttributeCommand = "cleartool mkattr -replace -c \\".'""'.$AttributeModComment."\\".'"" '.$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";

            }
            else
            {
#
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 014\n"; }
#
#               A comment is not to be added with the command.

                $ChangeAttributeCommand = "cleartool mkattr -replace -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";
            }
#
#           Execute the change attribute command.
#
            `$ChangeAttributeCommand`;
#
            if ($? == 0)
            {
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 015\n"; }
#
                print "Attribute $AttributeName change to '$NewAttributeValue' for $FileToProcess\n";
            }
            else
            {
#
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 016\n"; }
#
                `clearprompt proceed -type error -default abort -mask abort -prompt "Unable to change attribute $AttributeName on $FileToProcess"`;
            }
        }
    }
    else
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 017\n"; }
#
#       The attribute is present and is currently set to NO.
#
        `clearprompt yes_no -type ok -mask yes,no -prompt "Currently $AttributeName is set to 'NO'. Change to 'YES' ?"`;
#
        if ($? == 0)
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 018\n"; }
#
#           User selected yes to change the value.
#
            $NewAttributeValue = "YES";
#
            if (length($AttributeModComment) > 0)
            {
#
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 019\n"; }
#
#               A comment is to be added with the command.
#
                $ChangeAttributeCommand = "cleartool mkattr -replace -c \\".'""'.$AttributeModComment."\\".'"" '.$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";
            }
            else
            {
#
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 020\n"; }
#
#               A comment is not to be added with the command.
#
                $ChangeAttributeCommand = "cleartool mkattr -replace -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";
            }
#
#           Execute the change attribute command.
#
            `$ChangeAttributeCommand`;
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 021\n"; }
#
            if ($? == 0)
            {
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 022\n"; }
#
                print "Attribute $AttributeName change to '$NewAttributeValue' for $FileToProcess\n";
            }
            else
            {
#
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 023\n"; }

#
                `clearprompt proceed -type error -default abort -mask abort -prompt "Unable to change attribute $AttributeName on $FileToProcess"`;
            }
        }
    }
}
else
{
#
#   Attribute is not present.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 024\n"; }
#
#   The attribute is not present. Ask if the user want to create it set to YES.
#
    `clearprompt yes_no -type ok -mask yes,no -prompt "Create the Edit Allowed attribute set to 'YES' ?"`;

    if ($? == 0)
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 025\n"; }
#
#       User selected yes to to create the attribute set to YES.
#
        $NewAttributeValue = "YES";
    }
    else
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 026\n"; }
#
#       User selected no to to create the attribute set to NO.
#
        $NewAttributeValue = "NO";
    }

    if (length($AttributeModComment) > 0)
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 027\n"; }
#
#       A comment is to be added with the command.
#
        $ChangeAttributeCommand = "cleartool mkattr -c \\".'""'.$AttributeModComment."\\".'"" '.$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";

    }
    else
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 028\n"; }
#
#       A comment is not to be added with the command.
#
        $ChangeAttributeCommand = "cleartool mkattr -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";
    }
#
#   Execute the  attribute creation command.
#
    `$ChangeAttributeCommand`;
#
    if ($? == 0)
    {
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 029\n"; }
#
        print "Attribute $AttributeName created with a value of '$NewAttributeValue' for $FileToProcess\n";
    }
    else
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 030\n"; }
#
        `clearprompt proceed -type error -default abort -mask abort -prompt "Unable to create attribute $AttributeName on $FileToProcess"`;
    }
}

