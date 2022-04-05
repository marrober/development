# ClearCase trigger script to stop all ClearCase activity in the VOB
# where it is applied. This trigger script is intended to be applied as 
# an all element trigger to the admin vob and the tools VOBs to ensure
# that only a user who is designated as the 'bypass' user with -nusers
# when the trigger is created, can actually perform any command.
#
# Inital author : Mark Roberts, Rational Software.
# Creation date : 10th November, 1999.
# 
	print("You do not have access to perform the command $ENV{CLEARCASE_OP_KIND} on the element $ENV{CLEARCASE_PN}\n");
	exit(-1);		
#
# End of script.	