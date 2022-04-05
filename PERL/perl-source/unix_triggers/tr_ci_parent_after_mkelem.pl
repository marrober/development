# ClearCase trigger script to give the user the option to checkin the parent
# directory after creating a new ClearCase element.
# The script will be executed as a post operation trigger on the mkelem 
# cleartool subcommand. It will give the user the option to checkin the parent
# directory automatically. If the user responds 'yes' then the parent directory
# is checked in. If the user responds 'no' then no further action is taken on
# the assumption that the user has more files to make into elements.
# The trigger will NOT operate for the vobadmin user, because this user will
# be invovled in many element creations as part of bulk data import.
#
# Inital author : Mark Roberts, Rational Software.
# Creation date : 10th November, 1999.
# 
`clearprompt yes_no -prompt "Is this the final element creation at this time ($ENV{CLEARCASE_PN})?" -default no -mask yes,no -prefer_gui`;

if ($? == 0)
{
	# The user responded 'yes' so we must now checkin the parent directory.
	# Get the checkin comment data.
	# The comment must be stored in a temporary file so generate a name for
	# the file to be located in the /tmp directory.
	$ID=`id -un`;
	$ID =~ s/\n//;
	$TempFileName = "/tmp/".$ID."_tr_get_comment";
	`rm $TempFileName`;
	`clearprompt text -outfile $TempFileName -multi_line -prompt "Enter a comment for the directory checkin." -prefer_gui`;
	if ($? == 0)
	{
		# The user has entered a comment.
		# Checkin the parent directory.
		`cleartool ci -cfile $TempFileName .`;
		
		if ($? != 0)
		{
			print "The checkin operation failed for the current directory.";
		}
			
	}		
	else
	{
		# Checkin the parent directory without specifying an additional comment.
		`cleartool ci -nc .`;
		
		if ($? != 0)
		{
			print "The checkin operation failed for the current directory.";
		}	
	}	
}	
else	
{
	# The user has more files to add as ClearCase element
}
