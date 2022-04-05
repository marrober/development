#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_attr_assign.pl
#------ Authors Name : Mark Roberts
#------ Date         : 3 February, 1997.
#------ Description  : This PERL script is called from a batch file created by
#                      a Visual Basic Program. It is passed the name of a file
#                      stored in the users temp directory that contains the
#                      following :
#                      Attribute Name
#                      Attribute type - 1 = string, 2 = Integer
#                      True / False flag - for auto replace or not.
#                      File To process
#                      Attribute text.
#
#                      The second command line argument is the name of the temp
#                      file that will hold the results.
#
# Get argument;
#
$ContainerFile = $ARGV[0];
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
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 001\n"; }
#
    print "\n\n ERROR : Could not find one of the following environment variables\n";
    print "        temp, TEMP\n";
    exit(0);
}
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 002\n"; }
#
# Create the name of the record file.
#
$RecordFile = ">".$ResultFile;
print $RecordFile;
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
    $ReplaceAuto =   @_[2];
    $FileToProcess = @_[3];
    $AttributeText = @_[4];
#
# Remove spaces arroud the attribute type digit.
#
$AttributeType =~ s/ //g;
#
#
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 003\n"; }
#
# Search for the attribute to see if the action is an update.
#
$AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                  " -element {attype($AttributeName)} -print";
$AttributeSearchResult = `$AttributeSearchCommand`;
#
if (length($AttributeSearchResult) > 0)
{
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 004\n"; }
#
#   The attribute is already present on the element.
#   If the $ReplaceAuto variable is set to TRUE then the attribute can be replaced
#   without asking the user for confirmation. Otherwise a prompt must be displayed.
#
    if (($ReplaceAuto cmp "True") == 0)
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 005\n"; }
#
        if (($AttributeType cmp "1") == 0)
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 006\n"; }
#
#           The attribute type is string.
#
            $CreateAttributeCommand = "cleartool mkattr -replace -nc ".$AttributeName.
                                      " \\".'""'.$AttributeText.'"'.
                                      "\\".'" '.$FileToProcess."@@";
            `$CreateAttributeCommand`;
#
#           Search for the attribute to see if the action was completed OK.
#
            $AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                                  " -element {attr_sub($AttributeName,==,".
                                  '"\\"'.$AttributeText.'\\""'.")} -print";
            $AttributeSearchResult = `$AttributeSearchCommand`;
        }
        else
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 007\n"; }
#
#           The attribute is type integer.
#
            $CreateAttributeCommand = "cleartool mkattr -replace -nc ".$AttributeName.
                                      " ".$AttributeText.
                                      " ".$FileToProcess."@@";
            `$CreateAttributeCommand`;
#
#           Search for the attribute to see if the action was completed OK.
#
            $AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                                  " -element {attr_sub($AttributeName,==,".
                                  $AttributeText.")} -print";
            $AttributeSearchResult = `$AttributeSearchCommand`;
        }
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 008\n"; }
#
        if (length($AttributeSearchResult) > 0)
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 009\n"; }
#
#           Write a record of the successful attribute change to the record file.
#
            open(RecordFileHandle, $RecordFile);
            print RecordFileHandle "OK";
            close(RecordFileHandle);
        }
        else
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 010\n"; }
#
#           Write a record of the successful attribute change to the record file.
#
            open(RecordFileHandle, $RecordFile);
            print RecordFileHandle "FAILED";
            close(RecordFileHandle);
        }
    }
    else
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 011\n"; }
#
#       Ask the user if they wish to replace the attribute.
#
        `clearprompt yes_no -type ok -mask yes,no -prompt "Replace the current setting for $AttributeName ?"`;
#
        if ($? == 0)
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 012\n"; }
#
#           The user pressed YES so replace the attribute.
#
            if (($AttributeType cmp "1") == 0)
            {
#
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 013\n"; }
#
#               The attribute type is string.
#
                $CreateAttributeCommand = "cleartool mkattr -replace -nc ".$AttributeName.
                                      " \\".'""'.$AttributeText.'"'.
                                      "\\".'" '.$FileToProcess."@@";
                `$CreateAttributeCommand`;
#
#               Search for the attribute to see if the action was completed OK.
#
                $AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                                  " -element {attr_sub($AttributeName,==,".
                                  '"\\"'.$AttributeText.'\\""'.")} -print";
                $AttributeSearchResult = `$AttributeSearchCommand`;
            }
            else
            {
#
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 014\n"; }
#
#               The attribute is type integer.
#
                $CreateAttributeCommand = "cleartool mkattr -replace -nc ".$AttributeName.
                                      " ".$AttributeText.
                                      " ".$FileToProcess."@@";
                `$CreateAttributeCommand`;
#
#              Search for the attribute to see if the action was completed OK.
#
                $AttributeSearchCommand = "cleartool find $FileToProcess -directory".
                                  " -element {attr_sub($AttributeName,==,".
                                  $AttributeText.")} -print";
                $AttributeSearchResult = `$AttributeSearchCommand`;
            }
#
            if (length($AttributeSearchResult) > 0)
            {
#
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 015\n"; }
#
#               Write a record of the successful attribute change to the record file.
#
                open(RecordFileHandle, $RecordFile);
                print RecordFileHandle "OK";
                close(RecordFileHandle);
                print "\nSatisfactorily completed\n";
            }
            else
            {
#
                if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 016\n"; }
#
#               Write a record of the successful attribute change to the record file.
#
                open(RecordFileHandle, $RecordFile);
                print RecordFileHandle "FAILED";
                close(RecordFileHandle);
            }
        }
        else
        {
#
            if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 017\n"; }
#
#           Skipped by user response.
#
           open(RecordFileHandle, $RecordFile);
           print RecordFileHandle "SKIPPED";
           close(RecordFileHandle);
        }
    }
}
else
{
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 018\n"; }
#
#   Create the new attribute.
#
    if (($AttributeType cmp "1") == 0)
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 019\n"; }
#
#       The attribute type is string.
#
        $CreateAttributeCommand = "cleartool mkattr -nc ".$AttributeName." \\".'""'.
                              $AttributeText.'"'."\\".'" '.$FileToProcess."@@";
        $CreateAttributeResult = `$CreateAttributeCommand`;
#
#       Search for the attribute to see if the action was completed OK.
#
        $AttributeSearchCommand = "cleartool find $FileToProcess -directory ".
                              "-element {attr_sub($AttributeName,==,".
                              '"\\"'.$AttributeText.'\\""'.")} -print";
        $AttributeSearchResult = `$AttributeSearchCommand`;
    }
    else
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 020\n"; }
#
#       The attribute is type integer.
#
       $CreateAttributeCommand = "cleartool mkattr -nc ".$AttributeName." ".
                              $AttributeText." ".$FileToProcess."@@";
        $CreateAttributeResult = `$CreateAttributeCommand`;
#
#       Search for the attribute to see if the action was completed OK.
#
        $AttributeSearchCommand = "cleartool find $FileToProcess -directory ".
                              "-element {attr_sub($AttributeName,==,".
                              $AttributeText.")} -print";
        $AttributeSearchResult = `$AttributeSearchCommand`;
    }
#
    if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 021\n"; }
#
    if (length($AttributeSearchResult) > 0)
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 022\n"; }
#
#       Write a record of the successful attribute change to the record file.
#
        open(RecordFileHandle, $RecordFile);
        print RecordFileHandle "OK";
        close(RecordFileHandle);
    }
    else
    {
#
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 023\n"; }
#
#       Write a record of the successful attribute change to the record file.
#
        open(RecordFileHandle, $RecordFile);
        print RecordFileHandle "FAILED";
        close(RecordFileHandle);
    }
}
if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 024\n"; }

