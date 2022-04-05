#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_getlockstatus.pl
#------ Authors Name : Mark Roberts
#------ Date         : 20 May, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      get the lock status for a file.
#                      Arguments to the script are as listed below :
#                      Argument 1 - a file containing a semi-colon separated list
#                                   of files to process.
#                      Argument 2 - the name of a file to hold the results.
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
# For each file to be processed lock the file.
#
foreach $File (@FilesToProcess)
{
    $ListLockCommand = "cleartool lslock ".$File;
#
#   Execute the command and record the result.
#
    print $ListLockCommand."\n";
    $CommandResult = `$ListLockCommand`;
    print length($CommandResult)."\n";
    if (length($CommandResult) == 0)
    {
        $Result = $Result.$File." Not locked\n";
    }
    else
    {
        $Result = $Result.$CommandResult;
    }
}
#
# Make the ResultFile writeable.
#
$ResultFile = ">".$ResultFile;
open (ResultFileHandle, $ResultFile);
print ResultFileHandle $Result."\n";
close ResultFileHandle;