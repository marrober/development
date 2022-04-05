#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_issued.pl
#------ Authors Name : Mark Roberts
#------ Date         : 20 January, 1997.
#------ Description  : This script is to add a label called ISSUED to files.
#                      The script can be supplied an argument of the file to
#                      be processed, or the user is prompted for the name of
#                      the file to be processed.
#
# Modification history.
#
# Checkout from \main\1. Mark Roberts 7th March, 1997.
#
# Addition of code to allow the EditAllowed label to be re-set to "NO"
# automatically.
#
# Checkout from \main\2. Mark Roberts 27 May, 1997.
#
# Changes requested following CCUG #3.
#   The EditAllowed attribute should only be added to files and not to directories.
#   The ISSUED label should not be applied to files that are checked out.
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 001\n"; }
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
    `clearprompt file -outfile $HoldingFile -prompt "Select the name of a file to which you wish to add a label."`;
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
if (length($FileToProcess) == 0)
{
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 005\n"; }
#
    print "Exit - No file selected\n";
    exit(0);
}
#
# Check if the file selected is checked out.
#
$CheckCheckoutCommand = "cleartool lsco ".$FileToProcess;
$CheckCheckoutResult = `$CheckCheckoutCommand`;
if (length($CheckCheckoutResult) > 0)
{
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 006\n"; }
    print "The selected file is currently checked out so the label cannot be applied\n\n";
    print $CheckCheckoutResult."\n";
    exit(0);
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 007\n"; }
#
# Get a comment to be placed with the label attachment.
#
$HoldingFile = $EnvTemp."\\hold.tmp";
`clearprompt text -outfile $HoldingFile -prompt "Enter a comment for 'ISSUED' label."`;
#
# Get the data from the file.
#
$LabelAddComment = "";
#
if (-e $HoldingFile)
{
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 008\n"; }
#
    open(HoldingFileHandle, $HoldingFile);
    read(HoldingFileHandle, $LabelAddComment, 1024);
    close(HoldingFileHandle);
#
# Remove the file that held the comment.
#
`del $HoldingFile`;
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 009\n"; }
#
if (length($LabelAddComment) >= 1)
{
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 010\n"; }

    $IssueSearchCommand = "cleartool find $FileToProcess -directory".
                      " -version {lbtype(ISSUED)} -print";
    $IssueSearchResult = `$IssueSearchCommand`;
#
    if (length($IssueSearchResult) > 0)
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 011\n"; }
#
#       ISSUED label already present on the element. Replace the old position
#       of the label.
#
        $AddLabelCommand = "cleartool mklabel -replace -c \\".'""'.$LabelAddComment.'"'."\\".'" '.$LabelName." ".$FileToProcess;
#
        `$AddLabelCommand`;
#
        if ($? == 0)
        {
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 012\n"; }
#
            print "Version label $LabelName added to $FileToProcess\n";
#
            $AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                                      " -element {attype($AttributeName)} -print";
            $AttributeSearchResult = `$AttributeSearchCommand`;

            if (length($AttributeSearchResult) > 0)
            {
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 013\n"; }
#
#               EditAllowed attribute already present on the element.
#
#               Check if the element is a file or a directory.
#
                $DescribeCommand = "cleartool describe ".$FileToProcess;
                $DescribeResult = `$DescribeCommand`;
#
                $_ = $DescribeResult;
#
#               Search for the string element type: directory
#
                if (!(m/element type: directory/))
                {
                    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 014\n"; }
#
#                   The element is a file so replace the old value.
#
                    $NewAttributeValue = "NO";
                    $ChangeAttributeCommand = "cleartool mkattr -replace -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";
#
#                   Execute the change attribute command.
#
                    `$ChangeAttributeCommand`;
#
                    if ($? == 0)
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 015\n"; }
                        print "The EditAllowed attribute has been re-set to 'NO'\n";
                    }
                    else
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 016\n"; }
                        print "WARNING : The EditAllowed attribute could not be re-set to 'NO'\n";
                        print "          This file can still be changed by a user\n";
                    }
#
                }
            }
            else
            {
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 017\n"; }
#
#               Check if the element is a file or a directory.
#
                $DescribeCommand = "cleartool describe ".$FileToProcess;
                $DescribeResult = `$DescribeCommand`;
#
                $_ = $DescribeResult;
#
#               Search for the string element type: directory
#
                if (!(m/element type: directory/))
                {
                    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 018\n"; }
#                   The attribute is not currently present.
#
                    $NewAttributeValue = "NO";
                    $ChangeAttributeCommand = "cleartool mkattr -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";

                    `$ChangeAttributeCommand`;
#
                    if ($? == 0)
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 019\n"; }
                        print "The EditAllowed attribute has been set to 'NO'\n";
                    }
                    else
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 020\n"; }
                        print "WARNING : The EditAllowed attribute could not be added to\n";
                        print "          the file with a value of 'NO'.\n";
                        print "          Investigate the fault.\n";
                    }
                }
            }
        }
        else
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 021\n"; }
#
            `clearprompt proceed -type error -default abort -mask abort -prompt "Unable to add the version label $LabelName to the file $FileToProcess"`;
        }
    }
    else
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 022\n"; }
#
        $AddLabelCommand = "cleartool mklabel -c \\".'""'.$LabelAddComment.'"'."\\".'" '.$LabelName." ".$FileToProcess;
#
        `$AddLabelCommand`;
#
        if ($? == 0)
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 023\n"; }
#
            print "Version label $LabelName added to $FileToProcess\n";

            $AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                                      " -element {attype($AttributeName)} -print";
            $AttributeSearchResult = `$AttributeSearchCommand`;

            if (length($AttributeSearchResult) > 0)
            {
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 024\n"; }
#               Check if the element is a file or a directory.
#
                $DescribeCommand = "cleartool describe ".$FileToProcess;
                $DescribeResult = `$DescribeCommand`;
#
                $_ = $DescribeResult;
#
#               Search for the string element type: directory
#
                if (!(m/element type: directory/))
                {
#
#                   The element is a file so replace the old value.
                    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 025\n"; }
#                   EditAllowed attribute already present on the element. Replace the old value.
#
                    $NewAttributeValue = "NO";
                    $ChangeAttributeCommand = "cleartool mkattr -replace -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";
#
#                   Execute the change attribute command.
#
                    `$ChangeAttributeCommand`;
#
                    if ($? == 0)
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 026\n"; }
                        print "The EditAllowed attribute has been re-set to 'NO'\n";
                    }
                    else
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 027\n"; }
                        print "WARNING : The EditAllowed attribute could not be re-set to 'NO'\n";
                        print "          This file can still be changed by a user\n";
                    }
                }
            }
            else
            {
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 028\n"; }
#               Check if the element is a file or a directory.
#
                $DescribeCommand = "cleartool describe ".$FileToProcess;
                $DescribeResult = `$DescribeCommand`;
#
                $_ = $DescribeResult;
#
#               Search for the string element type: directory
#
                if (!(m/element type: directory/))
                {
#
#                   The element is a file so replace the old value.
                    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 029\n"; }
#                   The attribute is not currently present.
#
                    $NewAttributeValue = "NO";
                    $ChangeAttributeCommand = "cleartool mkattr -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";

                    `$ChangeAttributeCommand`;
#
                    if ($? == 0)
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 030\n"; }
                        print "The EditAllowed attribute has been set to 'NO'\n";
                    }
                    else
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 031\n"; }
                        print "WARNING : The EditAllowed attribute could not be added to\n";
                        print "          the file with a value of 'NO'.\n";
                        print "          Investigate the fault.\n";
                    }
                }
            }
        }
        else
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 032\n"; }

#
            `clearprompt proceed -type error -default abort -mask abort -prompt "Unable to add the version label $LabelName to the file $FileToProcess"`;
        }
    }
}
else
{
#
#   No comment to be included.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 033\n"; }

    $IssueSearchCommand = "cleartool find $FileToProcess -directory".
                      " -version {lbtype(ISSUED)} -print";
    $IssueSearchResult = `$IssueSearchCommand`;
#
    if (length($IssueSearchResult) > 0)
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 034\n"; }
#
#       ISSUED label already present on the element. Replace the old position
#       of the label.
#
        $AddLabelCommand = "cleartool mklabel -replace -nc $LabelName ".$FileToProcess;
#
        `$AddLabelCommand`;
#
        if ($? == 0)
        {
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 035\n"; }
#
            print "Version label $LabelName added to $FileToProcess\n";
#
            $AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                                      " -element {attype($AttributeName)} -print";
            $AttributeSearchResult = `$AttributeSearchCommand`;

            if (length($AttributeSearchResult) > 0)
            {
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 036\n"; }
#               Check if the element is a file or a directory.
#
                $DescribeCommand = "cleartool describe ".$FileToProcess;
                $DescribeResult = `$DescribeCommand`;
#
                $_ = $DescribeResult;
#
#               Search for the string element type: directory
#
                if (!(m/element type: directory/))
                {
#
#                   The element is a file so replace the old value.
                    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 037\n"; }
#                   EditAllowed attribute already present on the element. Replace the old value.
#
                    $NewAttributeValue = "NO";
                    $ChangeAttributeCommand = "cleartool mkattr -replace -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";
#
#                   Execute the change attribute command.
#
                    `$ChangeAttributeCommand`;
#
                    if ($? == 0)
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 038\n"; }
                        print "The EditAllowed attribute has been re-set to 'NO'\n";
                    }
                    else
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 039\n"; }
                        print "WARNING : The EditAllowed attribute could not be re-set to 'NO'\n";
                        print "          This file can still be changed by a user\n";
                    }
                }
            }
            else
            {
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 040\n"; }
#               Check if the element is a file or a directory.
#
                $DescribeCommand = "cleartool describe ".$FileToProcess;
                $DescribeResult = `$DescribeCommand`;
#
                $_ = $DescribeResult;
#
#               Search for the string element type: directory
#
                if (!(m/element type: directory/))
                {
#
#                   The element is a file so replace the old value.
                    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 041\n"; }
#                   The attribute is not currently present.
#
                    $NewAttributeValue = "NO";
                    $ChangeAttributeCommand = "cleartool mkattr -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";

                    `$ChangeAttributeCommand`;
#
                    if ($? == 0)
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 042\n"; }
                        print "The EditAllowed attribute has been set to 'NO'\n";
                    }
                    else
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 043\n"; }
                        print "WARNING : The EditAllowed attribute could not be added to\n";
                        print "          the file with a value of 'NO'.\n";
                        print "          Investigate the fault.\n";
                    }
                }
            }
        }
        else
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 044\n"; }
#
            `clearprompt proceed -type error -default abort -mask abort -prompt "Unable to add the version label $LabelName to the file $FileToProcess"`;
        }
    }
    else
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 045\n"; }
#
        $AddLabelCommand = "cleartool mklabel -nc $LabelName ".$FileToProcess;
#
        `$AddLabelCommand`;
#
        if ($? == 0)
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 046\n"; }
#
            print "Version label $LabelName added to $FileToProcess\n";
#
            $AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                                      " -element {attype($AttributeName)} -print";
            $AttributeSearchResult = `$AttributeSearchCommand`;

            if (length($AttributeSearchResult) > 0)
            {
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 047\n"; }
#               Check if the element is a file or a directory.
#
                $DescribeCommand = "cleartool describe ".$FileToProcess;
                $DescribeResult = `$DescribeCommand`;
#
                $_ = $DescribeResult;
#
#               Search for the string element type: directory
#
                if (!(m/element type: directory/))
                {
#
#                   The element is a file so replace the old value.
                    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 048\n"; }
#                   EditAllowed attribute already present on the element. Replace the old value.
#
                    $NewAttributeValue = "NO";
                    $ChangeAttributeCommand = "cleartool mkattr -replace -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";
#
#                   Execute the change attribute command.
#
                    `$ChangeAttributeCommand`;
#
                    if ($? == 0)
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 049\n"; }
                        print "The EditAllowed attribute has been re-set to 'NO'\n";
                    }
                    else
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 050\n"; }
                        print "WARNING : The EditAllowed attribute could not be re-set to 'NO'\n";
                        print "          This file can still be changed by a user\n";
                    }
                }
            }
            else
            {
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 051\n"; }
#               The attribute is not currently present.
#
#               Check if the element is a file or a directory.
#
                $DescribeCommand = "cleartool describe ".$FileToProcess;
                $DescribeResult = `$DescribeCommand`;
#
                $_ = $DescribeResult;
#
#               Search for the string element type: directory
#
                if (!(m/element type: directory/))
                {
                    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 052\n"; }
#
#                   The element is a file so replace the old value.
                    $NewAttributeValue = "NO";
                    $ChangeAttributeCommand = "cleartool mkattr -nc ".$AttributeName." \\".'"'.$NewAttributeValue."\\".'" '.$FileToProcess."@@";

                    `$ChangeAttributeCommand`;
#
                    if ($? == 0)
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 053\n"; }
                        print "The EditAllowed attribute has been set to 'NO'\n";
                    }
                    else
                    {
                        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 054\n"; }
                        print "WARNING : The EditAllowed attribute could not be added to\n";
                        print "          the file with a value of 'NO'.\n";
                        print "          Investigate the fault.\n";
                    }
                }
            }
        }
        else
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 055\n"; }

#
            `clearprompt proceed -type error -default abort -mask abort -prompt "Unable to add the version label $LabelName to the file $FileToProcess"`;
        }
    }
}
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 056\n"; }