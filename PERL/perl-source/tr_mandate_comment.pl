#------------------------------------------------------------------------------
#------ PERL SCRIPT  : tr_mandate_comment.pl
#------ Authors Name : Mark Roberts
#------ Date         : 6th April, 1999.
#------ Description  : This trigger script validates the length of a comment
#                      for any clearcase event. The ClearCase events must be
#                      explicitly named in the trigger creation commands.
#       
$CommentLength = $ARGV[0];         

if (length($ENV{'CLEARCASE_COMMENT'}) < $CommentLength) 
{
	print "---------------------------------------------------------------------\n";
	print "Error ! - The comment must be at least ".$CommentLength." characters.\n";
	print "The following operation did NOT succeed.\n";
	print "Operation : $ENV{'CLEARCASE_OP_KIND'}\n";
	print "Object    : $ENV{'CLEARCASE_PN'}.\n";
	print "---------------------------------------------------------------------\n";
	exit(-1);
}
else
{
	exit(0);
}

