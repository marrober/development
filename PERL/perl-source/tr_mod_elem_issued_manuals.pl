#------------------------------------------------------------------------------
#------ PERL SCRIPT  : tr_mod_elem_issued_manuals.pl
#------ Authors Name : Mark Roberts
#------ Date         : September 4, 1997.
#------ Description  : This trigger checks that the item is available for
#                      change prior to allowing the checkout to proceed.
#                      The rules are :
#                          If the current version has the ISSUED label or the
#                          PROTECTED label then only allow the checkout if the
#                          element attribute EditAllowed has the value YES.
#                          If the element attribute EditAllowed is not present
#                          or it is present, but it is set to NO then do not
#                          allow the checkout.
# Modification history.
#
#
if (($ENV{'CLEARCASE_USER'} cmp "clear_adm") == 0)
{
#   User clear_adm can change any element in any VOB as administrator.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 001\n"; }

    exit(0);
}
if (($ENV{'CLEARCASE_USER'} cmp "smithp") == 0)
{
	$_ = $ENV{'CLEARCASE_PN'};
	if ((m/\\Manuals\\50300/) ||
		(m/\\Manuals\\50301/) ||
		(m/\\Manuals\\50304/) ||
		(m/\\Manuals\\50305/))
	{
#   	User smithp has full control over elements in the following directories of
#  		the manuals vob:
#   	50300, 50301, 50304, 50305.
#
    	if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 003\n"; }
	    exit(0);
	}
}
if (($ENV{'CLEARCASE_USER'} cmp "danielsa") == 0)
{
	$_ = $ENV{'CLEARCASE_PN'};
	if ((m/\\Manuals\\50300/) ||
		(m/\\Manuals\\50301/) ||
		(m/\\Manuals\\50304/) ||
		(m/\\Manuals\\50305/))
	{
#   	User danielsa has full control over elements in the following directories of
#		the manuals vob:
#   	50300, 50301, 50304, 50305.
#
    	if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 003\n"; }
    	exit(0);
	}
}
if (($ENV{'CLEARCASE_USER'} cmp "lingp") == 0)
{
	$_ = $ENV{'CLEARCASE_PN'};
	if (m/\\Manuals\\60008/)
	{
#   	User linp has full control over elements in the following directories of
#		the manauls vob: 60008.
#
    	if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 004\n"; }
    	exit(0);
	}
}
if (($ENV{'CLEARCASE_USER'} cmp "howellg") == 0)
{
	$_ = $ENV{'CLEARCASE_PN'};
	if (m/\\Manuals\\60008/)
	{
#   	User howellg has full control over elements in the following directories of
#		the manauls vob: 60008.
#
    	if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 004\n"; }
    	exit(0);
	}
}
if (($ENV{'CLEARCASE_USER'} cmp "hooler") == 0)
{
	$_ = $ENV{'CLEARCASE_PN'};
	if (m/\\Manuals\\60008/)
	{
#   	User hooler has full control over elements in the following directories of
#		the manauls vob: 60008.
#
    	if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 004\n"; }
    	exit(0);
	}
}
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 014\n"; }
#
# If the script reaches this point then the user is not a Project Librarian.
# Only Project Librarians can add the label ISSUED to an element.
#
if ((($ENV{'CLEARCASE_OP_KIND'} cmp "mklabel") == 0) &&
    (($ENV{'CLEARCASE_LBTYPE'} cmp "ISSUED") == 0))
{
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 015\n"; }
#
    print "\n Label type '".$ENV{'CLEARCASE_LBTYPE'}."' is protected.\n";
    print " You cannot add it to an element, or delete it from an element\n";
    print "Contact your Project Librarian or Mark Roberts ".
              "(ext:2181) for more information\n";
    exit(-1);
}
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 016\n"; }
#
# Locate the version of the element that has the ISSUED label attached.
#
$IssueSearchCommand1 = "cleartool find ".$ENV{'CLEARCASE_PN'}.
                      " -directory -version {lbtype(ISSUED)} -print";
$IssueSearchResult1 = `$IssueSearchCommand1`;
$IssueSearchCommand2 = "cleartool find ".$ENV{'CLEARCASE_PN'}.
                      " -directory -version {lbtype(PROTECTED)} -print";
$IssueSearchResult2 = `$IssueSearchCommand2`;
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 017\n"; }
#
if ((length($IssueSearchResult1) > 0) || (length($IssueSearchResult2) > 0))
{
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 018\n"; }
#
#   The element has the label ISSUED marked against a version.
#
#   Look for the attribute EditAllowed.
#
    $AttributeSearchCommand = "cleartool find ".$ENV{'CLEARCASE_PN'}.
                              " -directory -element {attype(EditAllowed)} -print";
    $AttributeSearchResult = `$AttributeSearchCommand`;
#
    if (length($AttributeSearchResult) == 0)
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 019\n"; }
#
#       If the attribute is not present then do not allow the command to proceed.
#
        print " Attribute 'EditAllowed' NOT found : \n";
        print "\n You cannot perform the operation ".
              $ENV{'CLEARCASE_OP_KIND'}."\n";
        print " On element ".$ENV{'CLEARCASE_PN'}."\n";
        print "Contact your Project Librarian or Mark Roberts ".
              "(ext:2181) for more information\n";
#
        exit(-1);
    }
    else
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 020\n"; }
#
#       Get the attribute value.
#
        $AttributeSearchCommand = "cleartool find ".$ENV{'CLEARCASE_PN'}.
                                  "@@ -directory -element {attr_sub(EditAllowed,==,".
                                  '\"'."YES".'\"'.")} -print";
        $AttributeSearchResult = `$AttributeSearchCommand`;
#
        if (length($AttributeSearchResult) > 0)
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 021\n"; }
#
#           The file has the attribute EditAllowed set to 'YES'
#           The action can therefore go ahead provided that it is a checkout only.
#
            if ((($ENV{'CLEARCASE_OP_KIND'} cmp "checkout") == 0) ||
                (($ENV{'CLEARCASE_OP_KIND'} cmp "checkin") == 0) ||
                (($ENV{'CLEARCASE_OP_KIND'} cmp "uncheckout") == 0))
            {
#
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 022\n"; }
#
#               The action is a checkout, checkin or uncheckout.
#
                exit(0);
            }
            else
            {
#
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 023\n"; }
#
#               The action is not a checkout so an error message is displayed.
#
                print "\n You cannot perform the operation ".
                      $ENV{'CLEARCASE_OP_KIND'}."\n";
                print " On element ".$ENV{'CLEARCASE_PN'}."\n";
                print "Contact your Project Librarian or Mark Roberts ".
                      "(ext:2181) for more information\n";
#
                exit(-1);
            }
        }
        else
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 024\n"; }
#
#           The attribute is present on the file, but the search for the value
#           of 'YES' failed. This implies that the file has not been released
#           by the libarian for edit.
#
            print " Attribute 'EditAllowed' is set to 'NO' : \n";
            print "\n You cannot perform the operation ".$ENV{'CLEARCASE_OP_KIND'}."\n";
            print " On element ".$ENV{'CLEARCASE_PN'}."\n";
            print "Contact your Project Librarian or Mark Roberts ".
                  "(ext:2181) for more information\n";
            exit(-1);
       }
    }
}
else
{
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 025\n"; }
#
#   The element does not have the ISSUED label attached to it. Any operation
#   can therefore be performed on the element.
#
    exit(0);
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 026\n"; }
