#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_lslabel_all.pl
#------ Authors Name : Mark Roberts
#------ Date         : 27 November, 1996.
#------ Description  : This script lists any labels applied to all files.
# 
# Variable declaration. 
#
$LinesToRead == 0;
$Counter = 1;
$LongestFileName = 0;
#
#Get the script start time, for a report after processing. 
# 
$StartTime = time;
#
# Print sign on information.
#
print "\n\n************************************************************************\n";
print "Recursive list labels applied to all files from current directory down.\n";
#
# Get the list of files to process. 
#
@FileList=`dir /b /s`;
#
# Insert . for the current directory to be processed.
#
unshift(FileList, ".\n");
#
# Get the current directory name for use in the report.
$CurrentDirectory = `cd`;
print "Current directory = ".$CurrentDirectory."\n";
#
# Get the number of files to be processed and display this number.
#
$FilesToProcess = $#FileList + 1;
print $FilesToProcess." Files (and directories) to be processed.\n\n";
#
# Message about the current directory.
#
print "Note : . refers to the current directory of ".$CurrentDirectory."\n";
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
# Collect together the full paths to 20 files to be processed on a single
# call to cleartool. 
#
    if ($Counter == 1)
    {   
        $CommandOne = "cleartool describe -fmt %En%[$LongestFileName]Tt%Nl\n ".$File;  
    }
    else
    {
        $CommandOne = $CommandOne." ".$File;
        if ($Counter == 20)
        {
            $Counter = 0;
            #
            $Report = `$CommandOne`;
            print $Report;
            #
        }      
    }
$Counter = $Counter + 1;
}
#
# Process any remaining files (i.e. less than 20).
#
$Report = `$CommandOne`;
print $Report."\n";
#
# Get the end time for the script and display the elapsed time.
#
$EndTime = time;
print "Elasped time = ". ($EndTime - $StartTime). " seconds.";
