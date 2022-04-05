#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_mkdir.pl
#------ Authors Name : Mark Roberts
#------ Date         : 27 November, 1996.
#------ Description  : This script file is used to create a directory. It checks
#                      that the current directory is checked out first.
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
# Get the file to be processed from the command line. if a command line argument is
# not given then get the name from a prompt.
#
$NewDir = $ARGV[0];
#
    $CurrentDirectoryCheckoutResult = `cleartool lsco -short -directory .`;
#
    if ((substr($CurrentDirectoryCheckoutResult, 0, 1) cmp ".") != 0)
    {
#       The current directory is not checked out.
#
        print "\nThe current directory must be checked out prior to creating a directory.\n\n";
        exit(0);
    }

#
if (length($NewDir) == 0)
{
    $HoldingFile = $EnvTemp."\\hold.tmp";
    `clearprompt text -outfile $HoldingFile -prompt "Enter the name of the new directory."`;
#
# Get the name of the file to be processed.
#
    open(HoldingFileHandle, $HoldingFile);
    read(HoldingFileHandle, $NewDir, 1024);
    close(HoldingFileHandle);
#
# Remove the file that held the comment.
#
    `del $HoldingFile`;
}
if (length($NewDir) == 0)
{
# Print a message then exit.
#
    print "Exit - No directory name entered\n";
    exit(0);
}
else
{
# Create the new directory.
#
    $CreateDirCommand = "cleartool mkdir -nc $NewDir";
    print $CreateDirCommand."\n";
    $CreateDirResult = `$CreateDirCommand`;
    print "\n".$CreateDirResult."\n";
}
#



