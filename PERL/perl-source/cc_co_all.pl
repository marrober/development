#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_co_all.pl
#------ Authors Name : Mark Roberts
#------ Date         : 27 November, 1996.
#------ Description  : This script performs a recursive checkout from the
#                      current directory. A comment may be given on the command
#                      line in quotes. If a comment is not provided via the
#                      command line then a clearprompt Window will pop-up giving
#                      the user the oportunity to enter a comment.
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
    print "\n\n ERROR : Could not find one of the following environment variables\n";
    print "        temp, TEMP, tmp, TMP\n";
    exit(0);
}
#
$LinesToRead == 0;
$Counter = 1;
#
#Get the script start time, for a report after processing.
#
$StartTime = time;
#
# Get the command line comment if used.
#
$Comment = $ARGV[0];
#
# If the comment is of zero length then prompt the user for a comment with a
# popup window.
#
if (length($Comment) == 0)
{
# Set the name of the file to hold the window collected comment in the temp
# directory.
#
    $CommentFile = $EnvTemp."\\comment.tmp";
    `clearprompt text -outfile $CommentFile -multi_line -prompt "Enter a checkout comment to be applied to all CHANGED files."`;
#
# Get the result of the last backtick command. If - then the user pressed OK
# to dismiss the dialog box.
#
    if ($? == 0)
    {
#
# Get the comment from the file.
#
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
#
# Remove the file that held the comment.
#
        `del $CommentFile`;
    }
}
#
# Print sign on information.
#
print "\n\n************************************************************************\n";
print " Comment : \n". $Comment ."\n";
print "Recursive checkout of all files from current directory down.\n";
#
# Get the list of files to process.
#
@FileList=`dir /b /s`;
#
# Get the number of files to be processed and display this number.
#
$FilesToProcess = $#FileList + 1;
print $FilesToProcess." Files (and directories) to be processed.\n";
#
foreach $i (@FileList)
{
# Remove the \n from the end of each line as it is processed.
#
    split(/[\n]/,$i);
	$File = @_[0];
#
# depending on the length of the comment select which block of commands
# to use to checkout the files. If the comment has a length >= 1 then
# there is a comment to store.
#
    if (length($Comment) >= 1)
    {
        if ($Counter == 1)
        {
#
# Prepare the checkout command and a command to list the files in their
# new checked out state.
#
            $_ = $File;
            if (/ /)
            {
                $CommandOne = "cleartool co -c \"$Comment\" \"".$File."\"";
                $CommandTwo = "cleartool ls -d \"".$File."\"";

            }
            else
            {
                $CommandOne = "cleartool co -c \"$Comment\" ".$File;
                $CommandTwo = "cleartool ls -d ".$File;

            }
        }
        `$CommandOne`;
        $Report = `$CommandTwo`;
        print $Report;
    }
    else
    {
#
# No comment commands.
#
        $_ = $File;
        if (/ /)
        {
            $CommandOne = "cleartool co -c \"$Comment\" \"".$File."\"";
            $CommandTwo = "cleartool ls -d \"".$File."\"";
        }
        else
        {
            $CommandOne = "cleartool co -c \"$Comment\" ".$File;
            $CommandTwo = "cleartool ls -d ".$File;

        }
        `$CommandOne`;
         $Report = `$CommandTwo`;
         print $Report;
    }
}
#
# Get the end time for the script and display the elapsed time.
#
$EndTime = time;
print "Elasped time = ". ($EndTime - $StartTime). " seconds.";