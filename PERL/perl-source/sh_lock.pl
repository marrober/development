#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_lock.pl
#------ Authors Name : Mark Roberts
#------ Date         : 19 May, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      lock a file.
#                      Arguments to the script are as listed below :
#                      Argument 1 - a file containing a semi-colon separated list
#                                   of files to process.
#                      Argument 2 - the name of a file to hold the results.
#                      Argument 3 - the name of a file to hold the comment or
#                                   NONE if a comment was not supplied.
#                      Argument 4 - the name of a file to hold the users who are
#                                   allowed to unlock the file or NONE if no
#                                   users are to be specified.
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
$UserListFile = $ARGV[3];
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
# Get the names of the unlock users.
#
if (($UserListFile cmp "NONE") == 0)
{
    $UnlockUsers = "";
}
else
{
    open(UserListFileHandle, $UserListFile);
    read(UserListFileHandle, $UnlockUsers, 1024);
    close(UserListFileHandle);
}
$UnlockUsers =~ s/\n//g;


# For each file to be processed lock the file.
#
foreach $File (@FilesToProcess)
{
    if (length($UnlockUsers) > 0)
    {
        if (length($Comment) > 0)
        {
#
#           Comment - YES, unlock users - YES
#
            $LockCommand = "cleartool lock -nusers ".$UnlockUsers." -c \"".$Comment."\" ".$File;
        }
        else
        {
#
#           Comment - NO, unlock users - YES
#
            $LockCommand = "cleartool lock -nusers ".$UnlockUsers." -nc ".$File;
        }
    }
    else
    {
        if (length($Comment) > 0)
        {
#
#           Comment - YES, unlock users - NO
#
            $LockCommand = "cleartool lock -c \"".$Comment."\" ".$File;
        }
        else
        {
#
#           Comment - NO, unlock users - NO
#
            $LockCommand = "cleartool lock -nc ".$File;
        }
    }
#
#   Execute the command and record the result.
#
    print $LockCommand."\n";
    $CommandResult = `$LockCommand`;
    $Result = $Result.$CommandResult;
}
#
# Make the ResultFile writeable.
#
$ResultFile = ">".$ResultFile;
open (ResultFileHandle, $ResultFile);
print ResultFileHandle $Result."\n";
close ResultFileHandle;