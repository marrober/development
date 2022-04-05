# Specify the comment minimum for each command.

$CommandsWithComments{"checkout"} = 10;
$CommandsWithComments{"checkin"} = 	20;
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

# Check what command is being executed
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
	}
}
exit(0);