#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_findattronfile.pl
#------ Authors Name : Mark Roberts
#------ Date         : 7 May, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      Search for the version of a file that contains a
#                      particular attribute. The value of the attribute is
#                      returned, in addition to the version of the file that
#                      has the atttribute attached.
#                      Argument one : The name of the file to search for, or . for
#                                     any file.
#                      Argument two : The path to search.
#                      Argument Three : The name of the attribute.
#                      Argument Three : The name of the file to hold the results.
#
# Get argument;
#
$SearchFileName = $ARGV[0];
$SearchPath = $ARGV[1];
$AttributeName = $ARGV[2];
$ResultFile = $ARGV[3];
#
# Check for a \ on the end of the line.
#
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
# Find command.
$_ = $SearchFileName;
if (m/./)
{
    print "Search of ".$SearchPath." for Attribute ".$AttributeName."\n";
    $Result = "Search of ".$SearchPath." for Attribute ".$AttributeName."\n";
}
else
{
    print "Search of ".$SearchPath.$SearchFileName." for Attribute ".$AttributeName."\n";
    $Result = "Search of ".$SearchPath.$SearchFileName." for Attribute ".$AttributeName."\n";
}
#
$FindCommand = "cleartool find ".$SearchPath.$SearchFileName." -nxname -element {attype_sub(".$AttributeName.")} -print";
$FindResult = `$FindCommand`;
if (length($FindResult) > 0)
{
    @FileList = split(/\n/, $FindResult);
    foreach $File (@FileList)
    {
        print $File;
        $Result = $Result.$File;
        $FindVersionAttrCommand = "cleartool find ".$File." -version {attype_sub(".$AttributeName.")} -print";
        #print $FindVersionAttrCommand."\n";
        $FindVersionAttrResult = `$FindVersionAttrCommand`;
        #print $FindVersionAttrResult."\n";
        if (length($FindVersionAttrResult) > 0)
        {
            print "\n";
            $Result = $Result."\n";
#
#           The attribute exists on one or more versions of the file.
#
            @VersionList = split(/\n/, $FindVersionAttrResult);
            foreach $Version (@VersionList)
            {
                split(/@@/, $Version);
                $VersionDetail = @_[1];
                $DescribeCommand = "cleartool describe -fmt \"%[$AttributeName]a\" ".$Version;
                $DescribeResult = `$DescribeCommand`;
                $DescribeResult =~ s/\"//g;
                $DescribeResult =~ s/\(//g;
                $DescribeResult =~ s/\)//g;
                split(/\=/, $DescribeResult);
                print "  Version : ".$VersionDetail." - ".@_[1]."\n";
                $Result = $Result."  Version : ".$VersionDetail." - ".@_[1]."\n";
            }
        }
        else
        {
#           The attribute exists on the element.
#
            $DescribeCommand = "cleartool describe -fmt \"%[$AttributeName]a\" ".$File."@@";
            $DescribeResult = `$DescribeCommand`;
            $DescribeResult =~ s/\"//g;
            $DescribeResult =~ s/\(//g;
            $DescribeResult =~ s/\)//g;
            split(/\=/, $DescribeResult);
            print " Element attribute, value - ".@_[1]."\n";
            $Result = $Result." Element attribute, value - ".@_[1]."\n";
        }
    }
}
else
{
    print "Attribute NOT found \n";
    $Result = $Result."Attribute NOT found \n";
}
#
$ResultFile = ">".$ResultFile;
#
open(ResultFileHandle, $ResultFile);
print ResultFileHandle $Result;
close(ResultFileHandle);




