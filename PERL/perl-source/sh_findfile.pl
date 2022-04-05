#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_findfile.pl
#------ Authors Name : Mark Roberts
#------ Date         : 18 April, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      Search for a file.
#                      Argument one : The name of the file to search for.
#                      Argument two : The path to search.
#                      Argument Three : The name of the file to hold the results.
#
# Get argument;
#
$SearchFileName = $ARGV[0];
$SearchPath = $ARGV[1];
$ResultFile = $ARGV[2];
#
# Check for a \ on the end of the line.
#
print $SearchPath."\n";
$ChopChar = chop($SearchPath);
$_ = $ChopChar;
if (m/\\/)
{
    $SearchPath = $SearchPath."\\";
}
else
{
    $SearchPath = $SearchPath.$ChopChar."\\";
}
print $SearchPath."\n";
# Search command.
#
$SearchCommand = "dir ".$SearchPath.$SearchFileName." /b /s";
print $SearchCommand."\n";
$SearchResult = `$SearchCommand`;
#
$ResultFile = ">".$ResultFile;
#
open(ResultFileHandle, $ResultFile);
print ResultFileHandle "Search result for ".$SearchFileName." on path ".$SearchPath."\n";
print ResultFileHandle $SearchResult;
close(ResultFileHandle);




