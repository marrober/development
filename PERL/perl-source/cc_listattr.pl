#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_listattr.pl
#------ Authors Name : Mark Roberts
#------ Date         : 27 November, 1996.
#------ Description  : This script simply lists the VOB names and descriptions.
#
# Variable declaration.
#
#Get the script start time, for a report after processing.
#
$StartTime = time;
#
# Print sign on information.
#
print "\nList all attributes applied to all files\n";
#
# Get the list of files to process.
#
@FileList=`dir /b /s`;
#
# Get the number of files to be processed and display this number.
#
$FilesToProcess = $#FileList + 1;
#
print $FilesToProcess." Files (and directories) to be processed.\n\n";
#
# Use the ClearTool describe command to list the attribute information.
#
foreach $i (@FileList)
{
# Remove the \n from the end of each line as it is processed.
#
    split(/[\n]/,$i);
	$File = @_[0];
    if (length($File) > $LongestFileName)
    {
        $LongestFileName = length($File);
    }
}
#
$LongestFileName = $LongestFileName + 2;
if ($LongestFileName > 60)
{
    $LongestFileName = 60;
}
#
foreach $i (@FileList)
{
# Remove the \n from the end of each line as it is processed.
#
	split(/[\n]/,$i);
	$File = @_[0];
#
    $DescribeCommand = "cleartool describe -fmt \"%En\\n  %N[Author]a\\n  %N[DocTitle]a\\n\" ".$File."@@";
    $DescribeResult = `$DescribeCommand`;
    $DescribeResult =~ s/Author=\"/Author         : /g;
    $DescribeResult =~ s/DocTitle=\"/Document Title : /g;
    $DescribeResult =~ s/\"//g;

    if (length($DescribeResult) > (length($File) + 7))
    {
        print $DescribeResult;
    }
    else
    {
        print $File."\n";
    }
}
#
# Get the end time for the script and display the elapsed time.
#
$EndTime = time;
print "Elasped time = ". ($EndTime - $StartTime). " seconds.\n";

