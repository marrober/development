#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_cancelcheckout.pl
#------ Authors Name : Mark Roberts
#------ Date         : 14 April, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      cancel checkout for a series of files.
#                      The script is supplied an argument of the name of a file
#                      that contains a list of files to be processed. The second
#                      command line argument is the name of a file to hold
#                      results of the checkout operation.
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
$FileListHolderFile = $ARGV[0];
$ResultFile = $ARGV[1];
#
# Open the file containing the list of files to be processed and read the contents.
#
$Counter = 0;
#
open (FileListFileHandle, $FileListHolderFile);
while ((read (FileListFileHandle, $LineFromFile, 300)) > 0)
{
    $LineFromFile = $LineEnd.$LineFromFile;
    $LineEnd = "";
    $LineFromFile =~ s/\n//g;
    $_ = $LineFromFile;
    if (m/\;/)
    {
        if ((substr($LineFromFile, length($LineFromFile) - 1, 1) cmp ";") == 0)
        {
            $SemiEnd = 1;
        }
        else
        {
            $SemiEnd = 0;
        }
        @SplitLines = split(/;/g, $LineFromFile);
        for ($i = 0; $i < $#SplitLines; $i++)
        {
            @FilesToProcess[$Counter] = @SplitLines[$i];
            $Counter = $Counter + 1;
        }
        if ($#SplitLines == 0)
        {
            $LineFromFile =~ s/;//g;
            @FilesToProcess[$Counter] = $LineFromFile;
            $Counter = $Counter + 1;
        }
        if ($#SplitLines > 0)
        {
            if ($SemiEnd == 1)
            {
                $LineEnd = @SplitLines[$#SplitLines].";";
            }
            else
            {
                $LineEnd = @SplitLines[$#SplitLines];
            }
        }
    }
}
close (FileListFileHandle);
#
if (length($LineEnd) > 0)
{
    @FilesToProcess[$Counter] = substr($LineEnd, 0, length($LineEnd) - 1);
    $Counter = $Counter + 1;
}
#
$Counter = 1;
#
foreach $File (@FilesToProcess)
{
# Remove the \n from the end of each line as it is processed.
#
    $ProcessingBuffer = $ProcessingBuffer."##".$File."\n";
    print $File."\n";
#
    if ($Counter == 1)
    {
#
#       Prepare the cancel checkout command.
#
        $Command = "cleartool unco -rm ".$File;
        print $Command."\n";
    }
    else
    {
        $Command = $Command." ".$File;
#
#       Collect together the full paths to 20 files to be processed on a single
#       call to cleartool.
#
        if ($Counter == 20)
        {
            `$Command`;
            if ($? != 0)
            {
#
#               Put an indication of the fault in the $ResultBuffer.
#
                $_ = $ProcessingBuffer;
                s/##/Questionable : /g;
                $ResultBuffer = $ResultBuffer.$_;
                $ResultBuffer = $ResultBuffer."\n\nCommand that resulted in error : \n";
                $ResultBuffer = $ResultBuffer.$Command;
                $ResultBuffer = $ResultBuffer."\nStatus of files in this batch : \n";
                $StatusCommand = "cleartool lsco -fmt \"%En checked out from ver %PVn by %u".'\n'."    %c".'\n'."\" ".$FilesOnly;
                $StatusResult = `$StatusCommand`;
                $ResultBuffer = $ResultBuffer.$StatusResult;
            }
            else
            {
                $Counter = 0;
                $Command = "";
#
#               Replace the ## in the $ProcessingBuffer variable with the phrase :
#               checkout cancelled : .
#
                $_ = $ProcessingBuffer;
                s/##/checkout cancelled : /g;
                $ResultBuffer = $ResultBuffer.$_;
                $ProcessingBuffer = "";
            }
        }
    }
    $Counter = $Counter + 1;
}
#
# Process any remaining files (i.e. less than 20).
#
if (length($Command) > 0)
{
    print $Command."\n";
    `$Command`;
    if ($? != 0)
    {
#       Put an indication of the fault in the $ResultBuffer.
#
        $_ = $ProcessingBuffer;
        s/##/Questionable : /g;
        $ResultBuffer = $ResultBuffer.$_;
        $ResultBuffer = $ResultBuffer."\nCommand that resulted in error : \n";
        $ResultBuffer = $ResultBuffer.$Command;
        $ResultBuffer = $ResultBuffer."\nStatus of files in this batch : \n";
        $StatusCommand = "cleartool lsco -fmt \"%En checked out from ver %PVn by %u".'\n'."    %c".'\n'."\" ".$FilesOnly;
        print $StatusCommand."\n";
        $StatusResult = `$StatusCommand`;
        $ResultBuffer = $ResultBuffer.$StatusResult;
    }
    else
    {
#
#       Replace the ## in the $ProcessingBuffer variable with the phrase :
#       checkout cancelled : .
#
        $_ = $ProcessingBuffer;
        s/##/checkout cancelled : /g;
        $ResultBuffer = $ResultBuffer.$_;
    }
}
#
# Open the result file to hold the information.
#
FINISH:
$ResultFile = ">".$ResultFile;
open(ResultFileHandle, $ResultFile);
#
print ResultFileHandle "CHECKOUT_CANCEL_COMPLETED\n";
#
if (length($ResultBuffer) > 0)
{
    print ResultFileHandle $ResultBuffer."\n";
}
#
close ResultFileHandle;


