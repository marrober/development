#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_dirbasedco.pl
#------ Authors Name : Mark Roberts
#------ Date         : 21 April, 1997.
#------ Description  : This script performs a recursive checkout from the
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
# Get a list of all files and directories to process.
#
print "1\n";
$FilesAndDirectoriesListCommand = "dir ".$ArgumentDirectory." /s/b";
print $FilesAndDirectoriesListCommand."\n";
@FilesAndDirectoriesList = `$FilesAndDirectoriesListCommand`;
#
foreach $Element (@FilesAndDirectoriesList)
{
    print $Element;
    $Element =~ s/\n//;
    if (length($Comment) >= 1)
    {
        $Command = "cleartool co -c \"$Comment\" ".$Element;
        $CheckOutResult = `$Command`;
    }
    else
    {
        $CheckOutResult = `cleartool co -nc $Element`;
    }
    print $CheckOutResult;
#
    if ($? == 1)
    {
        print "Unable to checkout ".$Element."\n";
        $ResultBuffer = $ResultBuffer."ERROR : Unable to checkout ".$Element."\n";
    }
    else
    {
        $ResultBuffer = $ResultBuffer.$CheckOutResult;
    }
}
#
# Checkout the argument directory if necessary.
#
if (($ProcessArgument cmp "1") == 0)
{
#
#   Checkout the argument directory.
#
#
    if (length($Comment) >= 1)
    {
        $Command = "cleartool co -c \"$Comment\" ".$ArgumentDirectory;
        $CheckOutResult = `$Command`;
    }
    else
    {
        $CheckOutResult = `cleartool co -nc $ArgumentDirectory`;
    }
    if ($? == 1)
    {
        print "Unable to checkout ".$Element."\n";
        $ResultBuffer = $ResultBuffer."ERROR : Unable to checkout ".$Element."\n";
    }
    else
    {
        $ResultBuffer = $ResultBuffer.$CheckOutResult;
    }
}
#
# Open the result file to hold the information.
#
$ResultFile = ">".$ResultFile;
open(ResultFileHandle, $ResultFile);
#
print ResultFileHandle "CHECKOUT_COMPLETED\n";
if (length($ResultBuffer) > 0)
{
    print ResultFileHandle $ResultBuffer."\n";
}
#
close ResultFileHandle;