#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_checkin.pl
#------ Authors Name : Mark Roberts
#------ Date         : 14 April, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      checkin a series of files.
#                      The script is supplied an argument of the name of a file
#                      that contains a list of files to be processed. The second
#                      command line argument is the name of a file to hold
#                      results of the checkout operation. The third command line
#                      argument is the name of a file that holds the comment.
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
$FileListHolderFile = $ARGV[0];
$ResultFile = $ARGV[1];
$CommentFile = $ARGV[2];
#
# Get the comment from the temp file.
#
if (($CommentFile cmp "NONE") == 0)
{
    $Comment = "";
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
    $ProcessingBuffer = "##".$File."\n";
#
#   Depending on the length of the comment select which block of commands
#   to use to checkin the files. If the comment has a length >= 1 then
#   there is a comment to store.
#
    if (length($Comment) >= 1)
    {
        $Command = "cleartool ci -c \"$Comment\" ".$File;
        `$Command`;
        if ($? != 0)
        {
#
#           The checkin failed - this may be due to the file being a text
#           file that has not changed. Cancel the checkout.
#
            $Command = "cleartool unco -rm ".$File;
            `$Command`;
            if ($? != 0)
            {
#
#               The cancel checkout failed. This is due to to the file not being
#               checked out.
#
#               Put an indication of the fault in the $ResultBuffer.
#
                $_ = $ProcessingBuffer;
                s/##/Not checked out : /g;
                $ResultBuffer = $ResultBuffer.$_;
            }
            else
            {
#
#               The checkout was successfuly cancelled.
#
                $_ = $ProcessingBuffer;
                s/##/Checkout cancelled (file not changed) : /g;
                $ResultBuffer = $ResultBuffer.$_;
            }
        }
        else
        {
#
#           The checkin was successful.
#
            $_ = $ProcessingBuffer;
            s/##/Checked in : /g;
            $ResultBuffer = $ResultBuffer.$_;
        }
    }
    else
    {
        $Command = "cleartool ci -nc ".$File;
        `$Command`;
        if ($? != 0)
        {
#
#           The checkin failed - this may be due to the file being a text
#           file that has not changed. Cancel the checkout.
#
            $Command = "cleartool unco -rm ".$File;
            `$Command`;
            if ($? != 0)
            {
#
#               The cancel checkout failed. This is due to to the file not being
#               checked out.
#
#               Put an indication of the fault in the $ResultBuffer.
#
                $_ = $ProcessingBuffer;
                s/##/Not checked out : /g;
                $ResultBuffer = $ResultBuffer.$_;
            }
            else
            {
#
#               The checkout was successfuly cancelled.
#
                $_ = $ProcessingBuffer;
                s/##/Checkout cancelled (file not changed) : /g;
                $ResultBuffer = $ResultBuffer.$_;
            }
        }
        else
        {
#
#           The checkin was successful.
#
            $_ = $ProcessingBuffer;
            s/##/Checked in : /g;
            $ResultBuffer = $ResultBuffer.$_;
        }
    }
}

#
# Open the result file to hold the information.
#
FINISH:
$ResultFile = ">".$ResultFile;
open(ResultFileHandle, $ResultFile);
#
print ResultFileHandle "CHECKIN_COMPLETED\n";
#
if (length($ResultBuffer) > 0)
{
    print ResultFileHandle $ResultBuffer."\n";
}
#
close ResultFileHandle;

