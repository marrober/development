#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_history.pl
#------ Authors Name : Mark Roberts
#------ Date         : 20 May, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      unlock a file.
#                      Arguments to the script are as listed below :
#                      Argument 1 - a file containing a semi-colon separated list
#                                   of files to process.
#                      Argument 2 - the name of a file holding options.
#                      Argument 3 - the name of a file to hold the results.

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
$OptionsFile = $ARGV[1];
$ResultFile = $ARGV[2];
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
    $Comment =~ s/\n//g;
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
# Get the options.
#
open(OptionsFileHandle, $OptionsFile);
read(OptionsFileHandle, $Options, 1024);
close(OptionsFileHandle);
print $Options;
$Options =~ s/\n//g;
# For each file to be processed lock the file.
#
foreach $File (@FilesToProcess)
{
    $Result = $Result."--------------------------------------------------\n";
    $Result = $Result."Element History for : ".$File."\n";
    $Result = $Result."--------------------------------------------------\n";
    $HistoryCommand = "cleartool lshistory".$Options.$File;
#
#   Execute the command and record the result.
#
    $CommandResult = `$HistoryCommand`;
    $Result = $Result.$CommandResult;
}
#
# Make the ResultFile writeable.
#
$ResultFile = ">".$ResultFile;
open (ResultFileHandle, $ResultFile);
print ResultFileHandle $Result."\n";
close ResultFileHandle;