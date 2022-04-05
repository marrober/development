#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_getlabellist.pl
#------ Authors Name : Mark Roberts
#------ Date         : 3 February, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      produce a list of all labels.
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
# Get the length of the longest Label name.
#
$MaxVobLength = 0;
foreach $Vob (@VobListArray)
{
    if (length($Vob) > $MaxVobLength)
    {
        $MaxVobLength = length($Vob);
    }
    $LabelListCommand = "cleartool lstype -kind lbtype -invob ".$Vob." -s";
    $LabelListResult = `$LabelListCommand`;
    $LabelListSizeSearch = $LabelListSizeSearch.$LabelListResult;
}
#
# Split the Labels into an array.
#
@LabelArray = split(/\n/, $LabelListSizeSearch);
#
$MaxLabelLength = 0;
foreach $Label (@LabelArray)
{
    if (length($Label) > $MaxLabelLength)
    {
        $MaxLabelLength = length($Label);
    }
}
$MaxVobLength = $MaxVobLength + 2;
$MaxLabelLength = $MaxLabelLength + $MaxVobLength + 2;
#
# For each Vob in the list get a list of labels.
#
foreach $Vob (@VobListArray)
{
    print "for vob : ".$Vob."\n";
    $VobText = $Vob;
    $VobText =~ s/\\//;
    $LabelListCommand = "cleartool lstype -kind lbtype -invob ".$Vob." -fmt \"".$VobText."%[$MaxVobLength]t%En%[$MaxLabelLength]t%c\"";
    print $LabelListCommand."\n";
    $LabelListResult = `$LabelListCommand`;
    split(/\n/, $LabelListResult);
    @LabelLineArray = @_;
#
    foreach $LabelLine (@LabelLineArray)
    {
        split(/ /, $LabelLine);
        $LabelLineCopy = $LabelLine;
        for ($i = 1; $i < 5; $i = $i + 1)
        {
            $LabelLineCopy =~ s/  / /g;
        }
        print $LabelLineCopy."\n";
        split(/ /, $LabelLineCopy);
        print @_[1]."\n";
        if (((@_[1] cmp "LATEST") != 0) && ((@_[1] cmp "CHECKEDOUT") != 0))
        {
            print $LabelLine."\n";
            $LabelList = $LabelList.$LabelLine."\n";
        }
    }
}
$ResultFile = ">".$ResultFile;
#
open(ResultFileHandle, $ResultFile);
print ResultFileHandle "Labels\n";
print ResultFileHandle $LabelList;
close(ResultFileHandle);



