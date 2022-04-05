#------------------------------------------------------------------------------
#------ PERL SCRIPT  : tr_comment_length.pl
#------ Authors Name : Mark Roberts
#------ Date         : 6th April, 1999.
#------ Description  : This trigger script validates the length of a comment
#                      for any clearcase event. The trigger associated with this
#                      script can be placed on every element in the VOB using
#                      the -element -all option. This is because the script will
#                      allow any commands that are not listed below. 
#
$CommandsWithComments{"checkout"} = 10;
$CommandsWithComments{"checkin"} = 20;
$CommandsWithComments{"reserve"} = 10;
$CommandsWithComments{"unreserve"} = 10;
$CommandsWithComments{"chevent"} = 10;
$CommandsWithComments{"chtype"} = 30;
$CommandsWithComments{"lock"} = 30;
$CommandsWithComments{"unlock"} = 30;
$CommandsWithComments{"rmbranch"} = 30;
$CommandsWithComments{"mkelem"} = 20;
$CommandsWithComments{"rmelem"} = 20;
$CommandsWithComments{"rmver"} = 20;
$CommandsWithComments{"mkattr"} = 10;
$CommandsWithComments{"rmattr"} = 20;
$CommandsWithComments{"mkhlink"} = 10;
$CommandsWithComments{"rmhlink"} = 20;
$CommandsWithComments{"mklabel"} = 10;
$CommandsWithComments{"rmlabel"} = 20;
$CommandsWithComments{"mktrigger"} = 30;
$CommandsWithComments{"rmtrigger"} = 30;

# Check what the command is...
#

foreach $key (keys (%CommandsWithComments))
{
	if ((($ENV{'CLEARCASE_OP_KIND'} cmp $key) == 0) && (length($ENV{'CLEARCASE_OP_KIND'}) == length($key)))
	{
		if (length($ENV{'CLEARCASE_COMMENT'}) < $CommandsWithComments{$key}) 
		{
			print "---------------------------------------------------------------------\n";
			print "Error ! - The comment must be at least ".$CommandsWithComments{$key}." characters.\n";
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
	}
}
exit(0);
