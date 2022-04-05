#------------------------------------------------------------------------------
#------ PERL SCRIPT  : tr_log_doc_status.pl
#------ Authors Name : Mark Roberts
#------ Date         : 26th May, 1999.
#------ Description  : This trigger is used with the mkattr command to log 
#                      attribute information to a file.
#

if ($ENV{'CLEARCASE_ATTYPE'} == "DocStatus")
{

	# Get the date and time.

	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);

	# Format the date and time string.

	if ($mday < 10) { $DateAndTime = "0".$mday."/"; }
	else            { $DateAndTime = $mday."/";     }

	if ($mon < 10)  { $DateAndTime = $DateAndTime."0".$mon."/"; }
	else            { $DateAndTime = $DateAndTime.$mon."/";     }

	if ($year == 99) { $DateAndTime = $DateAndTime."19".$year." "; }
	else             { $DateAndTime = $DateAndTime."20".$year." "; }

	if ($hour < 10)  { $DateAndTime = $DateAndTime."0".$hour.":"; }
	else             { $DateAndTime = $DateAndTime.$hour.":";     }

	if ($min < 10)  { $DateAndTime = $DateAndTime."0".$min; }
	else            { $DateAndTime = $DateAndTime.$min;     }

	# Open the log file to write to.

	$LogRecord = $DateAndTime.",".$ENV{'CLEARCASE_XPN'}.",".$ENV{'CLEARCASE_VAL'}.",".$ENV{'CLEARCASE_USER'}.",".$ENV{'CLEARCASE_COMMENT'}."\n";

	$LogFile = ">>"."\\\\nw-mroberts\\cc_stg\\log.txt";

	open FILEHANDLE, $LogFile;

	print FILEHANDLE $LogRecord;

	close FILEHANDLE;	
}
else
{
	print "The attribute is not a type to be recorded.\n";
}
exit(0);

