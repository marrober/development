#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_issue_letter.pl
#------ Authors Name : Mark Roberts
#------ Date         : 29 January, 1997.
#------ Description  : This script adds the Attribute IssueLetter to the current
#                      version of the file.
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
    `clearprompt file -outfile $HoldingFile -prompt "Select the name of a file to have the IssueLetter attribute."`;
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
$AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                  " -version {attype($AttributeName)} -print";
$AttributeSearchResult = `$AttributeSearchCommand`;
#
$ProceedPrompt = 0;
#
if (length($AttributeSearchResult) > 0)
{
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 008\n"; }
#
    @AttributedFileList = split(/[\n]/,$AttributeSearchResult);
#
    foreach $i (@AttributedFileList)
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 009\n"; }
#
#       Remove the \n from the end of each line as it is processed.
#
    	split(/[\n]/,$i);
    	$File = @_[0];
#
#       Display information on the current issue letter attributes applied to the file.
#
        $DescribeResult = `cleartool describe -fmt "%En#%Sn%S[IssueLetter]a" $File`;
        $DescribeResult =~ s/\(\"/ issue : /g;
        $DescribeResult =~ s/\"\)//g;
        $DescribeResult =~ s/#/ version /g;

        print $DescribeResult."\n";
#
    }
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 010\n"; }
#
    `clearprompt proceed -type ok -default abort -prompt "See command window - proceed to add new issue letter ?`;
    $ProceedPrompt = $?;
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 011\n"; }
#
if ($ProceedPrompt == 0)
{
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 012\n"; }
#
#   Get the new issue letter.
#
    $HoldingFile = $EnvTemp."\\hold.tmp";
    `clearprompt text -outfile $HoldingFile -prompt "Enter the new issue letter [A-Z]."`;
#
#   Get the data from the file.
#
    $AttributeModComment = "";
#
    if (-e $HoldingFile)
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 013\n"; }
#
        open(HoldingFileHandle, $HoldingFile);
        read(HoldingFileHandle, $IssueLetter, 1024);
        close(HoldingFileHandle);
#
#       Remove the file that held the comment.
#
        `del $HoldingFile`;
    }
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 014\n"; }
#
#   Display information on the new issue letter attribute to be applied to the file.
#
    $DescribeResult = `cleartool describe -fmt "%Sn#%En" $FileToProcess`;
    $DescribeResult =~ s/&/Attribute $IssueLetter will be applied to version /g;
    $DescribeResult =~ s/#/ of file /g;
#
#   Add the new attribute.
#
    $IssueLetterAttributeCommand = "cleartool mkattr $AttributeName \\".'""'.$IssueLetter.'"'."\\".'" '.$FileToProcess;
    `$IssueLetterAttributeCommand`;
#
    if ($? != 0)
    {
#
#       If the result of the last backtick command is non-zero then display an
#       error message.
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 015\n"; }
#
#       The command completed with error.
#
        print "ERROR - The command to add the attribute failed. This may be due to\n";
        print "        the fact that the attribute already exists on the latest version\n";
        print "        of the file, or the file may be protected.\n";
        print "        Contact your project librarian or Mark Roberts (ext: 2181)\n";
        `clearprompt proceed -type error -default abort -mask abort -prompt "Error - see command window for more information"`;
    }
    else
    {
    print "Issue letter $IssueLetter added to ".$DescribeResult."\n";
    }
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 016\n"; }
#
}
else
{
#
#   The user does not want to proceed to add a new label.
#
    exit(0);
}
