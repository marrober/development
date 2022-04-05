#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_deletedo.pl
#------ Authors Name : Mark Roberts
#------ Date         : 28 January, 1998.
#------ Description  : This script searches the current directory for derived
#                      objects and removes them.
#
$ClearToolLSDOCommand = "cleartool lsdo -me -s";

@ClearToolLSDOResult = `$ClearToolLSDOCommand`;
$RMDOCommand = "cleartool rmdo";

foreach $i (@ClearToolLSDOResult)
{
# Remove the \n from the end of each line as it is processed.
#
	split(/[\n]/,$i);
    $File = @_[0];

    $RMDOCommand = $RMDOCommand." ".$File;
}
print $RMDOCommand."\n";
`$RMDOCommand`;