#------------------------------------------------------------------------------
#------ PERL SCRIPT  : tr_mod_elem_issued.pl
#------ Authors Name : Mark Roberts
#------ Date         : 3 January, 1997.
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
# Checkout from \main\1. Mark Roberts 20th February, 1997.
#
# Addition of a second label to operate the protection scheme called PROTECTED.
# This will be used in the same manner as ISSUED but it ensures that PROTECTED
# source code and test data do not show up in the ISSUED view.
#
# checkout from \main\2. Mark Roberts 28th February, 1997.
#
# Addition of user ID TAYALM for librarian privilege on VOBs 50225 and 50227.
#
# checkout from \main\3. Mark Roberts 22 April, 1997.
#
# Addition of user ID PIPERD for librarian privilege on VOB 50320.
#
# checkout from \main\4. Mark Roberts 11 August, 1997.
#
# Change of user ID PIPERD to AVRILJ for librarian privilege on VOB 50320.
#
# checkout from \main\5. Mark Roberts 14 August, 1997.
#
# Change to allow only user robertsm to operate on the test VOB.
#
# Checkout from \main\6. Brendan Smith 7 May 1998.
#
# Change of user id from avrilj to hayesa for librarian privilege on VOB 50320.
#
# Checkout from \main\7. Mark Roberts 11th May, 1998.
#
# Addition of more VOBs to be controlled by Adrian Daniels and Peter Smith.
# Removal of the name Mark Roberts from the error reports.
#
# Checkout from \main\8. Mark Roberts 22nd May, 1998.
#
# Addition of Mark Roberts to the \50222 VOB.
#
# Checkout from \main\9. Mark Roberts 22nd June, 1998.
#
# Granted Mark Roberts same permission as Adrian Daniels for Adrians Holiday only.
#
# Checkout from \main\10. Brendan Smith 5th October, 1998.
#
# Addition of Martin jones to the \Kitz200 VOB.
#
# Checkout from \main\11. Mark Roberts 12th October, 1998.
#
# Added Alan Trow to the VOB's 50300, 50301, 50304, 50305.
#
# Checkout from \main\12. Brendan Smith 13th October, 1998.
#
# Altered kitz200 vob to 50248 for Martin Jones, added Gary Howell to Devtools vob.
#
# Checkout from \main\13. Brendan Smith 27th October, 1998.
#
# Corrected script so that create branch operations are allowed (with editAllowed set to YES).
#
# Checkout from \main\14. Brendan Smith 20th November, 1998.
#
# Added M Jones as librarian of 50249 vob (modbus-kbus bridge).
#
#
#
#
if (($ENV{'CLEARCASE_USER'} cmp "clear_adm") == 0)
{
#   User clear_adm can change any element in any VOB as administrator.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 001\n"; }

    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "clear_adm") == 0) &&
    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\Admin") == 0))
{
#   User clear_adm can change any element in any VOB as administrator.
#   Any clear_adm is the only user who can change any element in the \Admin VOB.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 002\n"; }
    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "smithp") == 0) &&
                   ((($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300CD") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300PL") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300PLT") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300PR") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300PRT") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50301") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50301B") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50304") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50304B") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50304CD") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50305") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50305B") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50304") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50306") == 0)))
{
#   User smithp has full control over elements in the following VOBS:
#   See the list above.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 003\n"; }
    exit(0);
}
if (((($ENV{'CLEARCASE_USER'} cmp "danielsa") == 0) || (($ENV{'CLEARCASE_USER'} cmp "robertsm") == 0)) &&
                   ((($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300CD") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300PL") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300PLT") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300PR") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300PRT") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50301") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50301B") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50304") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50304B") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50304CD") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50305") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50305B") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50304") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50306") == 0))){
#   User danielsa has full control over elements in the following VOBS:
#   See the list above.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 004\n"; }
    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "lingp") == 0) &&
    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\60008") == 0))
{
#   User lingp has full control over elements in the following VOBS: 60008.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 005\n"; }
    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "howellg") == 0) &&
                   ((($ENV{'CLEARCASE_VOB_PN'} cmp "\\60008") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\Devtools") == 0)))
{
#   User howellg has full control over elements in the following VOBS: 60008 & Devtools.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 006\n"; }
    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "hooler") == 0) &&
    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\60008") == 0))
{
#   User hooler has full control over elements in the following VOBS: 60008.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 007\n"; }
    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "saltd") == 0) &&
    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50222") == 0))
{
#   User saltd has full control over elements in the following VOBS: 50222.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 008\n"; }
    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "jonesms") == 0) &&
    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50186") == 0))
{
#   User jonesms has full control over elements in the following VOBS: 50186.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 009\n"; }
    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "jonesms") == 0) &&
                   ((($ENV{'CLEARCASE_VOB_PN'} cmp "\\50176") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50248") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50249") == 0)))
{
#   User jonesms has full control over elements in the following VOBS: 50176; 50248; 50249
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 010\n"; }
    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "tayalm") == 0) &&
    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50225") == 0))
{
#   User tayalm has full control over elements in the following VOBS: 50225.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 011\n"; }
    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "tayalm") == 0) &&
    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50227") == 0))
{
#   User tayalm has full control over elements in the following VOBS: 50227.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 012\n"; }
    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "hayesa") == 0) &&
                ((($ENV{'CLEARCASE_VOB_PN'} cmp "\\50320") == 0) ||
                 (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50208") == 0)))
{
#   User hayesa has full control over elements in the following VOBS: 50320; 50208
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 013\n"; }
    exit(0);
}
#
if ((($ENV{'CLEARCASE_USER'} cmp "robertsm") == 0) &&
    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\Test") == 0))
{
#   User robertsm has full control over elements in the following VOBS: Test.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 014\n"; }
    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "banhamd") == 0) &&
    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50233") == 0))
{
#   User banhamd has full control over elements in the following VOBS: 50233.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 015\n"; }
    exit(0);
}
if ((($ENV{'CLEARCASE_USER'} cmp "robertsm") == 0) &&
    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50222") == 0))
{
#   User robertsm has full control over elements in the following VOBS: 50222.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 016\n"; }
    exit(0);
}


if ((($ENV{'CLEARCASE_USER'} cmp "trowa") == 0) &&
                   ((($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50301") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50304") == 0) ||
                    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50305") == 0)))
{
#   User trowa has full control over elements in the following VOBS:
#   See the list above.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 017\n"; }
    exit(0);
}

if ((($ENV{'CLEARCASE_USER'} cmp "willingm") == 0) &&
    ((($ENV{'CLEARCASE_VOB_PN'} cmp "\\50301B") == 0) ||
     (($ENV{'CLEARCASE_VOB_PN'} cmp "\\50300PR") == 0)))
{
#   User willingm has full control over elements in the following VOBS: 50301B and 50300PR.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 018\n"; }
    exit(0);
}

if ((($ENV{'CLEARCASE_USER'} cmp "edwardsb") == 0) &&
    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\TechMan") == 0))
{
#   User edwardsb has full control over elements in the directory 55001 in
#   the VOB TechMan.

    $_ = $ENV{'CLEARCASE_PN'};

    if(m/\\TechMan\\55001/)
    {
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 019\n"; }
        exit(0);
    }
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 020\n"; }
}

if ((($ENV{'CLEARCASE_USER'} cmp "LiH") == 0) &&
    (($ENV{'CLEARCASE_VOB_PN'} cmp "\\TechMan") == 0))
{
#   User lih has full control over elements in the directory 55006 in
#   the VOB TechMan.

    $_ = $ENV{'CLEARCASE_PN'};

    if(m/\\TechMan\\55006/)
    {
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 021\n"; }
        exit(0);
    }
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 022\n"; }
}



##############################################################################
#
# End of VOB - user specific section.
#
##############################################################################
#
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 023\n"; }
#
# If the script reaches this point then the user is not a Project Librarian.
# Only Project Librarians can add the label ISSUED to an element.
#
if ((($ENV{'CLEARCASE_OP_KIND'} cmp "mklabel") == 0) &&
    (($ENV{'CLEARCASE_LBTYPE'} cmp "ISSUED") == 0))
{
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 024\n"; }
#
    print "\n Label type '".$ENV{'CLEARCASE_LBTYPE'}."' is protected.\n";
    print " You cannot add it to an element, or delete it from an element\n";
    print "Contact your Project Librarian for more information\n";
    exit(-1);
}
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 025\n"; }
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
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 026\n"; }
#
if ((length($IssueSearchResult1) > 0) || (length($IssueSearchResult2) > 0))
{
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 027\n"; }
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
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 028\n"; }
#
#       If the attribute is not present then do not allow the command to proceed.
#
        print " Attribute 'EditAllowed' NOT found : \n";
        print "\n You cannot perform the operation ".
              $ENV{'CLEARCASE_OP_KIND'}."\n";
        print " On element ".$ENV{'CLEARCASE_PN'}."\n";
        print "Contact your Project Librarian for more information\n";
#
        exit(-1);
    }
    else
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 029\n"; }
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
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 030\n"; }
#
#           The file has the attribute EditAllowed set to 'YES'
#           The action can therefore go ahead provided that it is a checkout or branch creation.
#
            if ((($ENV{'CLEARCASE_OP_KIND'} cmp "checkout") == 0) ||
                (($ENV{'CLEARCASE_OP_KIND'} cmp "checkin") == 0) ||
                (($ENV{'CLEARCASE_OP_KIND'} cmp "uncheckout") == 0))
            {
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 031\n"; }
				exit(0);
			}
			else
			{
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 032\n"; }
                if ((($ENV{'CLEARCASE_OP_KIND'} cmp "mkbranch") == 0) && (length($IssueSearchResult2) > 0))
				{
                    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 033\n"; }
					exit(0);
				}
				else
				{
                    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 034\n"; }
#
#   	            The action is not a checkout so an error message is displayed.
#
        	        print "\n You cannot perform the operation ".
            	          $ENV{'CLEARCASE_OP_KIND'}."\n";
                	print " On element ".$ENV{'CLEARCASE_PN'}."\n";
	                print "Contact your Project Librarian for more information\n";
#
    	            exit(-1);
    	     	}
            }
        }
        else
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 035\n"; }
#
#           The attribute is present on the file, but the search for the value
#           of 'YES' failed. This implies that the file has not been released
#           by the libarian for edit.
#
            print " Attribute 'EditAllowed' is set to 'NO' : \n";
            print "\n You cannot perform the operation ".$ENV{'CLEARCASE_OP_KIND'}."\n";
            print " On element ".$ENV{'CLEARCASE_PN'}."\n";
            print "Contact your Project Librarian for more information\n";
            exit(-1);
       }
    }
}
else
{
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 036\n"; }
#
#   The element does not have the ISSUED label attached to it. Any operation
#   can therefore be performed on the element.
#
    exit(0);
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 037\n"; }
