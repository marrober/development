	print "-----------------------------------------------------------------------\n\n";
	print "User information \n";
	print "-----------------------------------------------------------------------\n";
	print "User name : ".$ENV{'CLEARCASE_USER'}."\n";
	print "\n";
	
	print "Object information \n";
	print "-----------------------------------------------------------------------\n";
	print "Name of element  : ".$ENV{'CLEARCASE_PN'}."\n";
	print "Element type     : ".$ENV{'CLEARCASE_ELTYPE'}."\n";
	print "Version - ID     : ".$ENV{'CLEARCASE_ID_STR'}."\n";
	print "Kind of object   : ".$ENV{'CLEARCASE_MTYPE'}."\n";
	print "Branch type      : ".$ENV{'CLEARCASE_BRTYPE'}."\n";
	print "Old name         : ".$ENV{'CLEARCASE_PN2'}."\n";
	print "Ext. name symbol : ".$ENV{'CLEARCASE_XN_SFX'}."\n";
	print "VOB ext. name    : ".$ENV{'CLEARCASE_XPN'}."\n";
	print "\n";
	
	print "Operation information \n";
	print "-----------------------------------------------------------------------\n";
	print "ClearCase operation       : ".$ENV{'CLEARCASE_OP_KIND'}."\n";
	print "Coment                    : ".$ENV{'CLEARCASE_COMMENT'}."\n";
	print "Pathname of ci -from file : ".$ENV{'CLEARCASE_CI_FPN'}."\n";
	print "Parent operation kind     : ".$ENV{'CLEARCASE_POP_KIND'}."\n";
	print "Parent Process-ID         : ".$ENV{'CLEARCASE_PPID'}."\n";
	print "\n";

	print "Additional information (may be blank - depends on op kind) \n";
	print "-----------------------------------------------------------------------\n";
	print "View tag : ".$ENV{'CLEARCASE_VIEW_TAG'}."\n";
	print "VOB tag  : ".$ENV{'CLEARCASE_VOB_PN'}."\n";

	print "Attribute type  : ".$ENV{'CLEARCASE_ATTYPE'}."\n";
	print "Attribute value : ".$ENV{'CLEARCASE_VAL'}."\n";
	print "Value type      : ".$ENV{'CLEARCASE_VTYPE'}."\n";
	
	print "ClearCase label type             : ".$ENV{'CLEARCASE_LBTYPE'}."\n";
	print "New name of renamed type object  : ".$ENV{'CLEARCASE_NEW_TYPE'}."\n";
	print "Reserved checkout ? (1=yes/0=no) : ".$ENV{'CLEARCASE_RESERVED'}."\n";
	print "Text of new VOB symbolic link    : ".$ENV{'CLEARCASE_SLNKTXT'}."\n";
	print "Trigger type                     : ".$ENV{'CLEARCASE_TRTYPE'}."\n";
	print "\n";	

	print "Hyperlink information \n";
	print "-----------------------------------------------------------------------\n";
	print "Hyperlink type                         : ".$ENV{'CLEARCASE_HLTYPE'}."\n";
	print "IS this a h-link 'from object'         : ".$ENV{'CLEARCASE_IS_FROM'}."\n";
	print "Text of h-link 'from' object           : ".$ENV{'CLEARCASE_FTEXT'}."\n";
	print "Pathname VOB for h-link 'from' object  : ".$ENV{'CLEARCASE_FVOB_PN'}."\n";
	print "VOB ext. name for h-link 'from' object : ".$ENV{'CLEARCASE_FXPN'}."\n";
	print "Text of h-link 'to' object             : ".$ENV{'CLEARCASE_TTEXT'}."\n";
	print "Pathname VOB for h-link 'to' object    : ".$ENV{'CLEARCASE_TVOB_PN'}."\n";
	print "VOB ext. name for h-link 'to' object   : ".$ENV{'CLEARCASE_TXPN'}."\n";
	
	print "-------------------------------END-------------------------------------\n";