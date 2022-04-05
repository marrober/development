#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_chmd_exe.pl
#------ Authors Name : Mark Roberts
#------ Date         : 23 January, 1997.
#------ Description  : This script changes the protection attribute of all .exe 
#                      files to r-x for the group.
# 
$StartTime = time;
$FilesCounter = 0;
#
# Print sign on information.
#
print "\n\n************************************************************************\n";
print "Change protection of .exe, .dll, .com, .bat files so that they will execute\n"; 
print "from within a VOB.\n";
#
# Get the list of files to process. 
#
@FileList=`dir *.exe /b /s`;
@FileList2=`dir *.dll /b /s`;
@FileList3=`dir *.com /b /s`;
@FileList4=`dir *.bat /b /s`;
@FileList = (@FileList,@FileList2, @FileList3, @FileList4);
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
#
# Execute the command to change the protection of the files.
#
        $ProtectCommandResult = `cleartool protect -chmod g+x $File`; 
        print $ProtectCommandResult; 
        $FilesCounter = $FilesCounter + 1;
#   
}
#
# Print a report on the number of files changed. 
#
print "Protection changed on : ". $FilesCounter. " files\n";
#
# Get the end time for the script and display the elapsed time.
#
$EndTime = time;
print "Elasped time = ". ($EndTime - $StartTime). " seconds.\n";
