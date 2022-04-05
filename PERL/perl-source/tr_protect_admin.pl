#------------------------------------------------------------------------------
#------ PERL SCRIPT  : tr_protect_admin.pl
#------ Authors Name : Mark Roberts
#------ Date         : 22 January, 1997.
#------ Description  : This script runs as a trigger on any file in the \Admin
#                      VOB to ensure that only the user clear_adm can update
#                      files.
# 
# Variable declaration. 
#
#   If the user is clear_adm then return 0 to allow the command to proceed. 
#
if (($ENV{'CLEARCASE_USER'} cmp "clear_adm") == 0)
{
    exit(0);
}
if (($ENV{'CLEARCASE_USER'} cmp "robertsm") == 0)
{
    exit(0);
}
#
# For any other user display a message informing them that they cannot perform the 
# command.
#
print "\nUser ".$ENV{'CLEARCASE_USER'}." is not allowed to perform the action : '";
print $ENV{CLEARCASE_OP_KIND}."'\n on element '".$ENV{CLEARCASE_PN}."'\n";    
print "Contact ClearCase administration : Mark Roberts, ext 2181 for information.\n\n";
#
#   Exit with return code 1 (non-zero) to ensure that the command is not completed.
#
exit(1);



