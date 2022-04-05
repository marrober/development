#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_list_vobs.pl
#------ Authors Name : Mark Roberts
#------ Date         : 3 February, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      produce a standard VOB listing. The information produced
#                      by the command is stored in a file which is passed as an
#                      argument to the file.
#
# Get argument;
#
$ContainerFile = $ARGV[0];
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
if (length($ContainerFile) == 0)
{
    print "\n\n No temporary file specified on the command line.\n";
    exit(0);
}
#
# Conver the container file name to write format.
#
$ContainerFile = ">".$ContainerFile;
#
# Generate the VOB listing command.
#
$VOBListCommand = "cleartool lsvob";
#
# Execute the VOB listing command.
#
$VOBListResult = `$VOBListCommand`;
#
# VOBS that are not currently mounted are listed with two blank spaces to the
# left of the name. These are replaced by a single '#' character to indicate
# to the calling Visual Basic program that the VOBS are not mounted. This
# action results in the full name of each VOB being as shown below :
# #\\eng-ntserver-6\VOBS\ADMIN\Admin.vbs public.
#
$VOBListResult =~ s/  \\/#\\/g;
#
# VOBS that are mounted at the time that the command is executed are displayed
# with a '* ' pair of characters to the left of the name. This is replaced by a
# single '*' character to indicate to the calling Visual Basic program that the
# VOB is mounted.
#
$VOBListResult =~ s/\* \\/\*\\/g;
#
# The information in the report is then split into an array based on carriage
# return characters.
#
@SplitLines = split(/\n/g, $VOBListResult);
#
$Counter = 0;
#
# At this point mounted VOBS are listed like :
#           *\Test              #\\eng-ntserver-6\VOBS\TEST\Test.vbs public
# and unmounted VOBS are listed like :
#           #\Admin             #\\eng-ntserver-6\VOBS\ADMIN\Admin.vbs public
#
#
# Write result to the temporary file.
#
open(ContainerFileHandle, $ContainerFile);
#
while (length(@SplitLines[$Counter]) != 0)
{
#
# The lines of VOB data are split based on the VOB name and location separator
# which is #\\. This results in a number of columns, but the only one of
# interest is the leftmost column. All blank spaces in the leftmost column
# are then removed and the VOB name and its mount status (# or *) is written
# to the file.
#
    @SplitColumns = split(/#\\\\/g, @SplitLines[$Counter]);
    @SplitColumns[0] =~ s/ //g;
    print(ContainerFileHandle @SplitColumns[0]."\n");
    $Counter ++;
}
close(ContainerFileHandle);




