#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_findlabel.pl
#------ Authors Name : Mark Roberts
#------ Date         : 26 January, 1998.
#------ Description  : This script searches the specified path and all
#                      subdirectories (or the current directory if no specific
#                      directory name is given) for files with the label given
#                      on the command line.
#                      A batch file is provided to call this PERL script as
#                      shown below :
#
#                      cc_findlabel {LabelName [Path] | -?}
#
# Modification history.
#
# Checkout from \main\x. <Name-of-person-making-change> <date-of-change.
#
# <Description>
#

print "START\n";
$Name = $ARGV[0];
$Path = $ARGV[1];

print $Name = $ARGV[0];

if ($ARGV[0] eq "-?")
{
	print "\n\nClearCase label search script.\n\n";
	print "Batch file  : \\\\eng-ntserver-6\\atria\\bin\\cc_findlabel.bat\n";
	print "PERL script : \\\\eng-ntserver-6\\atria\\perl-scripts\\cc_findlabel.pl\n";
	print "Arguments : \n";
	print "            1 .... Label name required e.g. A0.1\n";
	print "            2 .... Path name for start of recursive search\n";
	print "                    e.g. u:\\50300PL\\dev\\psl\n";
	print "                    (leave blank for current directory)\n";
	print "            -? ... Displays this help\n";
	print " For information or suggestions for modification contact : \n";
	print " Mark Roberts - Extn. 2181\n";
	exit(0);
}


if (length($Path) == 0)
{
	$Path = ".";
}

$ClearToolFindCommand = "cleartool find ".$Path." -name \\\"".$Name."\\\"";
$ClearToolFindCommand = $ClearToolFindCommand." -exec \"";
$ClearToolFindCommand = $ClearToolFindCommand."cleartool describe -fmt \\\"%Xn%[60]Nt%d\\n\\\"";
$ClearToolFindCommand = $ClearToolFindCommand. " %CLEARCASE_XPN%\"";
print $ClearToolFindCommand;
$ClearToolFindResult = `$ClearToolFindCommand`;

print $ClearToolFindResult."\n";