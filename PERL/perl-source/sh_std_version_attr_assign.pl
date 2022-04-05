#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_std_version_attr_assign.pl
#------ Authors Name : Mark Roberts
#------ Date         : 26th June, 1997.
#------ Description  : This PERL script is called from a batch file created by
#                      a Visual Basic Program. It is passed the name of a file
#                      stored in the users temp directory that contains the
#                      following :
#                      Attribute Name
#                      Attribute type - 1 = string, 2 = Integer
#                      The name of a file that contains a coma separated list of
#                      files to process.
#                      Attribute text.
#
#                      The second command line argument is the name of the temp
#                      file that will hold the results.
#
# Get argument;
#
$ContainerFile = $ARGV[0];
$ResultFile = $ARGV[1];
print "Container file ".$ContainerFile."\nResult file ".$ResultFile."\n";
#
$EnvTemp = $ENV{'TEMP'};
#
if (length($EnvTemp) == 0)
{
    $EnvTemp = $ENV{'temp'};
}
if (length($EnvTemp) == 0)
{
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 001\n"; }
#
    print "\n\n ERROR : Could not find one of the following environment variables\n";
    print "        temp, TEMP\n";
    exit(0);
}
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 002\n"; }
#
# Get the name of the file to be processed.
#
open(ContainerFileHandle, $ContainerFile);
read(ContainerFileHandle, $FileData, 1024);
close(ContainerFileHandle);
#
# Remove the file that held the comment.
#
#`del $ContainerFile`;
#
# Split the data read from the file on \n, based on the description above.
#
split(/[\n]/,$FileData);
$AttributeName = @_[0];
$AttributeType = @_[1];
$FilesToProcess = @_[2];
#
# Get all attribute text.
#
$AttributeTextFile = @_[3];
open (AttributeTextFileHandle, $AttributeTextFile);
while ((read (AttributeTextFileHandle, $LineFromFile, 300)) > 0)
{
    $AttributeText = $AttributeText.$LineFromFile;

}
close (FileListFileHandle);
print length($AttributeText)."\n";
$ReversedText = reverse($AttributeText);
$ReversedText =~ s/\n//;
$AttributeText = reverse($ReversedText);
print length($AttributeText)."\n";
#
print "ATTRIBUTE VALUE : \n".$AttributeText;
#
print $AttributeName."\n".$AttributeType."\n".$FilesToProcess."\n".$AttributeText."\n";
#
# Remove spaces aroud the attribute type digit.
#
$AttributeType =~ s/ //g;
#
# Get the names of files from the holding file.
#
#
open (FileListFileHandle, $FilesToProcess);
while ((read (FileListFileHandle, $LineFromFile, 300)) > 0)
{
    $LineFromFile = $LineEnd.$LineFromFile;
    $LineEnd = "";
    $LineFromFile =~ s/\n//g;
    $_ = $LineFromFile;
    if (m/\;/)
    {
        if ((substr($LineFromFile, length($LineFromFile) - 1, 1) cmp ";") == 0)
        {
            $SemiEnd = 1;
        }
        else
        {
            $SemiEnd = 0;
        }
        @SplitLines = split(/;/g, $LineFromFile);
        for ($i = 0; $i < $#SplitLines; $i++)
        {
            @FilesToProcess[$Counter] = @SplitLines[$i];
            $Counter = $Counter + 1;
        }
        if ($#SplitLines == 0)
        {
            $LineFromFile =~ s/;//g;
            @FilesToProcess[$Counter] = $LineFromFile;
            $Counter = $Counter + 1;
        }
        if ($#SplitLines > 0)
        {
            if ($SemiEnd == 1)
            {
                $LineEnd = @SplitLines[$#SplitLines].";";
            }
            else
            {
                $LineEnd = @SplitLines[$#SplitLines];
            }
        }
    }
}
close (FileListFileHandle);
#
if (length($LineEnd) > 0)
{
    @FilesToProcess[$Counter] = substr($LineEnd, 0, length($LineEnd) - 1);
    $Counter = $Counter + 1;
}
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 003\n"; }
#
# Search for the attribute to see if the action is an update.
#
foreach $File (@FilesToProcess)
{
    print $File."\n";
#
#   Get visible version of file.
#
    $VisibleVersionCommand = "cleartool describe -fmt \"%Xn\" ".$File;
    $VisibleVersion = `$VisibleVersionCommand`;
#
    $AttributeSearchCommand = "cleartool describe -fmt \"%[$AttributeName]a\n\" ".$VisibleVersion;
    $AttributeSearchResult = `$AttributeSearchCommand`;
    print $AttributeSearchResult."\n";
#
    if (length($AttributeSearchResult) > 1)
    {
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 004\n"; }
#
#       The attribute is already present on the element.
#       Get the content of the attribute and append to it the new attribute.
#
        $AttributeSearchResult =~ s/\($AttributeName=\"//;
        $AttributeSearchResult =~ s/\"\)//;
        $AttributeSearchResult =~ s/\n//;

#
#       Get the version of the file.
        $GetVersionCommand = "cleartool describe -fmt \"%[$AttributeName]a\n%Xn\n\" ".$File;
        $GetVersionResult = `$GetVersionCommand`;
#
        split(/\n/,$GetVersionResult);
        $VersionNumber = @_[1];
        split(/@@/,$VersionNumber);
        $VersionNumber = @_[1];
#
        $Result = $Result."Attribute ".$AttributeName." already exists on version ".$VersionNumber." of file ".$File." with a value ".$AttributeSearchResult."\n";
        print $Result."\n";

    }
    else
    {
#       The attribute does not exist at the moment.

        $CreateAttributeCommand = "cleartool mkattr -nc ".$AttributeName.
                                          " \\".'""'.$AttributeText.'"'.
                                          "\\".'" '.$File;
        print $CreateAttributeCommand."\n";
#
        `$CreateAttributeCommand`;
#
#       Search for the attribute to see if the action was completed OK.
#
        $AttributeSearchCommand = "cleartool describe -fmt \"%[$AttributeName]a\" ".$VisibleVersion;
        $AttributeSearchResult = `$AttributeSearchCommand`;
        print "**  ".$AttributeSearchResult."\n**".length($AttributeSearchResult)."\n";
#
        if (length($AttributeSearchResult) > 0)
        {
#           The attribute was applied to the file.
#           Get the version of the file.
            $GetVersionCommand = "cleartool describe -fmt \"%Xn\n\" ".$File;
            $GetVersionResult = `$GetVersionCommand`;
            print $GetVersionCommand."\n".$GetVersionResult."\n";
#
            split(/\n/,$GetVersionResult);
            $VersionNumber = @_[0];
            split(/@@/,$VersionNumber);
            $VersionNumber = @_[1];
#
            $Result = $Result."Attribute ".$AttributeName." applied to version ".$VersionNumber." of file ".$File." with value ".$AttributeText."\n";
            print $Result."\n";
        }
        else
        {
#
#           The attribute addition failed.
#
            $Result = $Result."ATTRIBUTE ADDITION FAILED ON FILE ".$File."\n";
            print $Result."\n";
        }
    }
}
#
# Make the result file writable.
#
$ResultFile = ">".$ResultFile;

open(RecordFileHandle, $ResultFile);
print RecordFileHandle $Result;
close(RecordFileHandle);