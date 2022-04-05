#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_add.pl
#------ Authors Name : Mark Roberts
#------ Date         : 27 November, 1996.
#------ Description  : This script adds files, recursively,  that are in 
#                      view-private-storage to the VOB as VOB objects. 
# 
# Variable declaration. 
#
$AddedFileCounter = 0;
#
#Get the script start time, for a report after processing. 
# 
$StartTime = time;
#
# Print sign on information.
#
print "\n\n*************************************************************************\n";
print "Recursive addition of all view-private files from current directory down.\n";
#
# Get the list of files to be processed.
#
$FilesToProcessMask = "*.*";
@FileList=`dir /b /s`;
#
# Display a message.
# 
print "Adding files ...... Please wait .......\n";
#
foreach $i (@FileList)
{
# Remove the \n from the end of each line as it is processed.
#
	$new = split(/[\n]/,$i);
	$File = @_[0];
# 
# Execute the cleartool subcommand 'ls' to list each file in the directory.
# A file that is already in clearcase will have @@\main\x after the name, or 
# some other clearcase identifier. 
#
    $LsResult = `cleartool ls -s $File`;
#
# Set the result to the deault search input.
#
    $_ = $LsResult;
#
# Search for @@, the result will be stored in $'
# 
    /@@/;
# 
# If the length of the search result is 0 then the describe command result did
# not have @@ in it, and therefore the file is view-private and needs to be added.
#
    if (length($') == 0)
    {
# 
# Make the new element and store the result.
#
        $MKelementResult = `cleartool mkelem -nc -ci $File`;
        print $MKelementResult;   
        $AddedFileCounter = $AddedFileCounter + 1;     
    }
}
# 
# Print Results.
#
print "Number of view-private files added : ".$AddedFileCounter."\n";
#
#
$EndTime = time;
print "Elasped time = ". ($EndTime - $StartTime). " seconds.";
