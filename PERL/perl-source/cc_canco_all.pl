#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_canco_all.pl
#------ Authors Name : Mark Roberts
#------ Date         : 27 November, 1996.
#------ Description  : This script performs a recursive cancel checkout from  
#                      the current directory. A comment is not recorded.
# 
# Variable declaration. 
$Counter = 1;
#
#Get the script start time, for a report after processing. 
# 
$StartTime = time;
#
# Print sign on information.
#
print "\n\n************************************************************************\n";
print "Recursive cancel checkout of all files from current directory down.\n";
#
# Get the list of files to process. 
#
@FileList=`dir /b /s`;
#
# Get the number of files to be processed and display this number.
#
$FilesToProcess = $#FileList + 1;
#
print $FilesToProcess." Files (and directories) to be processed.\n";
#
foreach $i (@FileList)
{
# Remove the \n from the end of each line as it is processed.
#
	split(/[\n]/,$i);
	$File = @_[0];
    print $File."\n";
    if ($Counter == 1)
    {   
#
# Prepare the cancel checkout.
#
        $Command = "cleartool unco -rm ".$File;  
    }
    else
    {
        $Command = $Command." ".$File;
#
# Collect together the full paths to 20 files to be processed on a single
# call to cleartool. 
#
        if ($Counter == 20)
        {
            `$Command`;
            $Counter = 0;
        }           
    }
    $Counter++;  
}
#
# Process any remaining file.
#
`$Command`;
#
# Get the end time for the script and display the elapsed time.
#
$EndTime = time;
print "Elasped time = ". ($EndTime - $StartTime). " seconds.";
