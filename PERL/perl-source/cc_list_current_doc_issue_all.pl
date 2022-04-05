#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_list_current_doc_issue_all.pl
#------ Authors Name : Mark Roberts
#------ Date         : 29 January, 1997.
#------ Description  : This script lists the value of the attribute of type 
#                      IssueLetter on the latest version of a all files visible
#                      within the view (recursive from current directory).
# 
# Print sign on information.
#
print "\n\n************************************************************************\n";
print "List the attribute of type IssueLetter assigned to the currently issued\n";
print "version of all files from the current directory recursively.\n";
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
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 005\n"; }
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 007\n"; }
#
# Search for all version of the all files that have the label IssueLetter.
#
$SearchCommand = "cleartool find . -version {attype(IssueLetter)&&lbtype(ISSUED)} -print";
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
#   Split the search result on carriage return characters.
#
    @SearchResultList = split(/[\n]/,$SearchResult);
#
    foreach $i (@SearchResultList)
    {
#
#       For each version of the file that has the label display the value of the
#       issue letter.
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
        $DescribeResult = `cleartool describe -fmt "%En  %S[IssueLetter]a" $File`;
        $DescribeResult =~ s/\(\"//g;
        $DescribeResult =~ s/\"\)//g;
#
        print $DescribeResult."\n";
#
    }
#
}
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 010\n"; }

