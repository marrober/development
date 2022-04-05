#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_getattributelist.pl
#------ Authors Name : Mark Roberts
#------ Date         : 3 February, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      produce a list of all attributes.
#                      Argument one : The name of a temp file that holds the
#                                     list of VOBs to search.
#                      Argument Two : The name of the file to hold the results.
#
# Get argument;
#
$VobListFile = $ARGV[0];
$ResultFile = $ARGV[1];
#
$EnvTemp = $ENV{'TEMP'};
#
if (length($EnvTemp) == 0)
{
    $EnvTemp = $ENV{'temp'};
}
if (length($EnvTemp) == 0)
{
#
    print "\n\n ERROR : Could not find one of the following environment variables\n";
    print "        temp, TEMP\n";
    exit(0);
}
#
# Read VOB list data.
#
open(VobListFileHandle, $VobListFile);
#
read (VobListFileHandle, $VobList, 2048);
close (VobListFileHandle);
#
# Split the Vob list based on #.
#
print $VobList."\n";
@VobListArray = split(/#/,$VobList);
pop @VobListArray;
#
# Get the length of the longest Attribute name.
#
$MaxVobLength = 0;
foreach $Vob (@VobListArray)
{
    if (length($Vob) > $MaxVobLength)
    {
        $MaxVobLength = length($Vob);
    }
    $AttributeListCommand = "cleartool lstype -kind attype -invob ".$Vob." -s";
    $AttributeListResult = `$AttributeListCommand`;
    $AttributeListSizeSearch = $AttributeListSizeSearch.$AttributeListResult;
}
#
# Split the attributes into an array.
#
@AttributeArray = split(/\n/, $AttributeListSizeSearch);
#
$MaxAttributeLength = 0;
foreach $Attribute (@AttributeArray)
{
    if (length($Attribute) > $MaxAttributeLength)
    {
        $MaxAttributeLength = length($Attribute);
    }
}
$MaxVobLength = $MaxVobLength + 2;
$MaxAttributeLength = $MaxAttributeLength + $MaxVobLength + 1;
# For each Vob in the list get a list of attributes.
#
foreach $Vob (@VobListArray)
{
    print "for vob : ".$Vob."\n";
    $VobText = $Vob;
    $VobText =~ s/\\//;
    $AttributeListCommand = "cleartool lstype -kind attype -invob ".$Vob." -fmt \"".$VobText."%[$MaxVobLength]t%En%[$MaxAttributeLength]t%c\"";
    $AttributeListResult = `$AttributeListCommand`;
    print $AttributeListResult."\n";
    split(/\n/, $AttributeListResult);
    @AttributeLineArray = @_;
#
    foreach $AttributeLine (@AttributeLineArray)
    {
        print "* : ".$AttributeLine."\n";
        $AttributeLineCopy = $AttributeLine;
        for ($i = 1; $i < 5; $i = $i + 1)
        {
            $AttributeLineCopy =~ s/  / /g;
        }
        split(/ /, $AttributeLineCopy);
        print @_[1]."\n";
        if (((@_[1] cmp "HlinkFromText") != 0) && ((@_[1] cmp "HlinkToText") != 0))
        {
            # print $AttributeLine."\n";
            $AttributeList = $AttributeList.$AttributeLine."\n";
        }
    }
}
$ResultFile = ">".$ResultFile;
#
open(ResultFileHandle, $ResultFile);
print ResultFileHandle "Attributes\n";
print ResultFileHandle $AttributeList;
close(ResultFileHandle);



