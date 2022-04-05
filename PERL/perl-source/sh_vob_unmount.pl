#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_vob_unmount.pl
#------ Authors Name : Mark Roberts
#------ Date         : 19 February, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      unmount a list of vobs, which are stored in a file which
#                      is passed as an argument to the file.
#                      The second command line argument is the name of the file
#                      to hold information that the mount has been completed.
#
# Get argument;
#
$VOBListFile = $ARGV[0];
$ReportFile = $ARGV[1];
#
$EnvTemp = $ENV{'TEMP'};
#
if (length($EnvTemp) == 0)
{
    $EnvTemp = $ENV{'temp'};
}
if (length($EnvTemp) == 0)
{
#
    print "\n\n ERROR : Could not find one of the following environment variables\n";
    print "        temp, TEMP\n";
    exit(0);
}
if (length($VOBListFile) == 0)
{
    print "\n\n No temporary file specified on the command line.\n";
    exit(0);
}
#
open(VobListFileHandle, $VOBListFile);
read(VobListFileHandle, $VOBListBuffer, 1024);
close(ContainerFileHandle);
#
@SplitLines = split(/\n/g, $VOBListBuffer);
#
$Counter = 0;
#
while (length(@SplitLines[$Counter]) != 0)
{
    print @SplitLines[$Counter]."\n";
    `cleartool umount @SplitLines[$Counter]`;
    $Counter ++;
}
$CompletedFileIndicator = ">".$ReportFile;
open(CompletedFileIndicatorHandle, $CompletedFileIndicator);
print CompletedFileIndicatorHandle "DONE";
close(CompletedFileIndicatorHandle);




