#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_del.pl
#------ Authors Name : Mark Roberts
#------ Date         : 28 November, 1996.
#------ Description  : This script removes any view private files recursively. 
# 
# Variable declaration. 
#
$DeletedFileCounter = 0;
#
#Get the script start time, for a report after processing. 
# 
$StartTime = time;
#
# Print sign on information.
#
print "\n\n************************************************************************\n";
print "Recursive delete of all view-private files from current directory down.\n";
#
# Get the list of files to be processed.
#
$FilesToProcessMask = "*.*";
@FileList=`dir /b /s`;
#
# Display a warning prompt.
#
`clearprompt yes_no -type warning -mask yes,no -default no -prompt "This will delete all view-private files, do you wish to continue ?"`;
#
if ($? == 1)
{
    exit(0);
}
#
# Display a message.
# 
print "Deleting files ...... Please wait .......\n";
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
# not have @@ in it, and therefore the file is view-private and needs to be deleted.
#
    if (length($') == 0)
    {
# 
# Delete the file.
#
        print "Deleting file : ".$File."\n";
        $DeleteFile = `del $File`;    
        $DeletedFileCounter = $DeletedFileCounter + 1;  
    }
}
# 
# Print Results.
#
print "Number of view-private files deleted : ".$DeletedFileCounter."\n";
#
# Get the end time for the script and display the elapsed time.
#
$EndTime = time;
print "Elasped time = ". ($EndTime - $StartTime). " seconds.";
