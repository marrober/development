#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_list_current_doc_issue.pl
#------ Authors Name : Mark Roberts
#------ Date         : 29 January, 1997.
#------ Description  : This script lists the value of the attribute of type
#                      IssueLetter on the latest version of a file visible
#                      within the view.
#
# Print sign on information.
#
print "\n\n************************************************************************\n";
print "List the attribute of type IssueLetter assigned to the currently issued\n";
print "version of the selected file.\n";
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 001\n"; }
#
# Variable declaration.
#
$AttributeName = "IssueLetter";
#
$EnvTemp = $ENV{'TEMP'};
#
if (length($EnvTemp) == 0)
{
    $EnvTemp = $ENV{'temp'};
}
if (length($EnvTemp) == 0)
{
    $EnvTemp = $ENV{'TMP'};
}
if (length($EnvTemp) == 0)
{
    $EnvTemp = $ENV{'tmp'};
}
if (length($EnvTemp) == 0)
{
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 002\n"; }
#
    print "\n\n ERROR : Could not find one of the following environment variables\n";
    print "        temp, TEMP, tmp, TMP\n";
    exit(0);
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 003\n"; }
#
# Get the file to be processed from the command line. if a command line argument is
# not given then get the name from a prompt.
#
$FileToProcess = $ARGV[0];
#
if (length($FileToProcess) == 0)
{
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 004\n"; }
#
    $HoldingFile = $EnvTemp."\\hold.tmp";
    `clearprompt file -outfile $HoldingFile -prompt "Select the name of a file to list the IssueLetter attribute."`;
#
# Get the name of the file to be processed.
#
    open(HoldingFileHandle, $HoldingFile);
    read(HoldingFileHandle, $FileToProcess, 1024);
    close(HoldingFileHandle);
#
# Remove the file that held the comment.
#
    `del $HoldingFile`;
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 005\n"; }
#
if (length($FileToProcess) == 0)
{
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 006\n"; }
#
    print "Exit - No file selected\n";
    exit(0);
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 007\n"; }
#
# Search for all version of the file that have the label IssueLetter.
#
$SearchCommand = "cleartool find $FileToProcess -directory -version {attype(IssueLetter)&&lbtype(ISSUED)} -print";
#
$SearchResult = `$SearchCommand`;
#
if (length($SearchResult) > 0)
{
#
#   If there are any results from the search command display them.
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 008\n"; }
#
#   Remove the \n from the end of each line as it is processed.
#
    split(/[\n]/,$SearchResult);
    $File = @_[0];
#
#   Display information on the current issue letter attributes applied to the file.
#
    $DescribeResult = `cleartool describe -fmt "%En%S[IssueLetter]a" $File`;
    $DescribeResult =~ s/\(\"/ issue : /g;
    $DescribeResult =~ s/\"\)//g;

    print $DescribeResult."\n";
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 009\n"; }