#------------------------------------------------------------------------------
#------ PERL SCRIPT  : tr_add_doc_status.pl
#------ Authors Name : Mark Roberts
#------ Date         : 26th May, 1999.
#------ Description  : This trigger is used with the checkin command to 
#                      add the attribute 'DocStatus' to all new versions of
#                      files with the 'doc' extension.
#

$ReversedName = reverse($ENV{'CLEARCASE_PN'});

@SplitRevName = split(/\./, $ReversedName);

$_ = reverse($SplitRevName[0]);

if(m/doc/i)
{
	# The file is a document. Check if it is approved.

	$FindCommand = "Cleartool find ".$ENV{'CLEARCASE_PN'}." -cview -version {attr_sub(DocStatus,==,\\\"Approved\\\")} -print";

	$FindResult = `$FindCommand`;

	print $FindResult."\n";

	if (length($FindResult) > 0)
	{
		# Disallow the checkout.
		print "You are not allowed to checkout a file that is 'Approved'.\n";
		exit(-1);
	}
	else
	{
		exit(0);
	}
}

