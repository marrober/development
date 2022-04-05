#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_dirbasedci.pl
#------ Authors Name : Mark Roberts
#------ Date         : 14 April, 1997.
#------ Description  : This script performs a recursive checkin from the
#                      current directory.
#                      Arguments to the script are :
#                          The name of the directory to be processed.
#                          A setting to indicate that the named directory is also
#                          to be processed. 0 = don't process, 1 = process.
#                          The name of the temp file that holds the comment to be
#                          used in the checkin command, or the word NONE if a
#                          comment is not to be used.
#                          The name of a temp file that is to hold the results of
#                          the operation.
#
# Get variables from command line.
#
$ResultStatus = "0";
#
$ArgumentDirectory = $ARGV[0];
$ProcessArgument = $ARGV[1];
$CommentFile = $ARGV[2];
$ResultFile = $ARGV[3];
print $ArgumentDirectory."\n".$ProcessArgument."\n".$CommentFile."\n".$ResultFile."\n";
#
# Get the comment from the temp file.
#
if (($CommentFile cmp "NONE") == 0)
{
    $Comment = "";
    print "NO COMMENT\n";
}
else
{
    open(CommentFileHandle, $CommentFile);
    while ($LinesToRead == 0)
    {
        if (eof(CommentFileHandle) == 1)
        {
            $LinesToRead = 1;
        }
        else
        {
            read(CommentFileHandle, $CommentBuffer, 1024);
            $Comment = $Comment.$CommentBuffer;
        }
    }
    close(CommentFileHandle);
    print "Length  of comment = : ".length($Comment)."\n";
    print $Comment."\n";
    $Comment =~ s/\n/ /g;
}
#
# Get a list of all checked out elements.
print "checkin checked out elements\n";
#
$CheckedOutElements = `cleartool lsco -r -s $ArgumentDirectory`;
#
# Process each checked out element.
#
if (length($CheckedOutElements) > 0)
{
    split(/[\n]/,$CheckedOutElements);
#
    foreach $Element (@_)
    {
        if (length($Comment) >= 1)
        {
            $Command = "cleartool ci -c \"$Comment\" ".$Element;
            $CheckinResult = `$Command`;
        }
        else
        {
            $CheckinResult = `cleartool ci -nc $Element`;
        }
        $ResultBuffer = $ResultBuffer."Checked in ".$Element."\n";
        print $CheckinResult."\n";
#
#       If the return value from the checkin command indicates that the file
#       revision is the same as the previous version then cancel the checkout.
#
        if ($? == 1)
        {
            print "checkout canceled\n";
            $UnCheckInResult = `cleartool unco -rm $Element`;
            print $UnCheckInResult;
            $ResultBuffer = $ResultBuffer."   Checkout cancelled file ".$Element."\n";
        }
    }
}
#
# Checkin the argument directory if necessary.
#
if (($ProcessArgument cmp "1") == 0)
{
#
#   Checkin the argument directory.
#
    $CheckedOutCheckCommand = "cleartool lsco -d ".$ArgumentDirectory;
    $CheckedOutCheckResult = `$CheckedOutCheckCommand`;
#
    if (length($CheckedOutCheckResult) > 0)
    {
        if (length($Comment) >= 1)
        {
            $Command = "cleartool ci -c \"$Comment\" ".$ArgumentDirectory;
            $CheckinResult = `$Command`;
        }
        else
        {
            $CheckinResult = `cleartool ci -nc $ArgumentDirectory`;
        }
        $ResultBuffer = $ResultBuffer."Checked in ".$ArgumentDirectory."\n";
        print $CheckinResult."\n";
    }
    else
    {
        $ResultBuffer = $ResultBuffer."Directory ".$ArgumentDirectory." is not checked out.\n";
    }
}
#
# Open the result file to hold the information.
#
$ResultFile = ">".$ResultFile;
open(ResultFileHandle, $ResultFile);
#
print ResultFileHandle "CHECKIN_COMPLETED\n";
if (length($ResultBuffer) > 0)
{
    print ResultFileHandle $ResultBuffer."\n";
}
#
close ResultFileHandle;