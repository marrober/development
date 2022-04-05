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
	# The file is a document.

	$MakeAttributeCommand = "cleartool mkattr -default DocStatus ".$ENV{'CLEARCASE_PN'};

	`$MakeAttributeCommand`;
}

