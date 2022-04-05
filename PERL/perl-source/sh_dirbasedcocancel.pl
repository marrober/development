#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_dirbasedcocancel.pl
#------ Authors Name : Mark Roberts
#------ Date         : 23 April, 1997.
#------ Description  : This script performs a recursive checkout cancel from the
#                      current directory.
#                      Arguments to the script are :
#                          The name of the directory to be processed.
#                          A setting to indicate that the named directory is also
#                          to be processed. 0 = don't process, 1 = process.
#                          The name of a temp file that is to hold the results of
#                          the operation.
#
# Get variables from command line.
#
$ResultStatus = "0";
#
$ArgumentDirectory = $ARGV[0];
$ProcessArgument = $ARGV[1];
$ResultFile = $ARGV[2];
print $ArgumentDirectory."\n".$ProcessArgument."\n".$ResultFile."\n";
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
        $Command = "cleartool unco -rm ".$Element;
        $CancelResult = `$Command`;
#
        $ResultBuffer = $ResultBuffer.$CancelResult;
        print $CancelResult."\n";
#
    }
}
#
# Cancel the checkout for the argument directory if necessary.
#
if (($ProcessArgument cmp "1") == 0)
{
#
#   Checkin the argument directory.
#
    $Command = "cleartool unco -rm ".$ArgumentDirectory;
    $CancelResult = `$Command`;
#
    $ResultBuffer = $ResultBuffer.$CancelResult;
    print $CancelResult."\n";
}
#
# Open the result file to hold the information.
#
$ResultFile = ">".$ResultFile;
open(ResultFileHandle, $ResultFile);
#
print ResultFileHandle "CHECKOUT_CANCEL_COMPLETED\n";
if (length($ResultBuffer) > 0)
{
    print ResultFileHandle $ResultBuffer."\n";
}
#
close ResultFileHandle;