#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_describe_doc_details.pl
#------ Authors Name : Mark Roberts
#------ Date         : 21 May, 1997.
#------ Description  : Shell PERL script called from a Visual Basic program to
#                      describe specific details of a file.
#                      Arguments to the script are as listed below :
#                      Argument 1 - a file containing a semi-colon separated list
#                                   of files to process.
#                      Argument 2 - option 0 = no labels on versions
#                                   option 1 = include labels on versions
#                      Argument 3 - option 0 = latest version only
#                                   option 1 = include old versions - major event only
#                                   option 2 = include old versions - all event
#                      Argument 4 - option 0 = no lock status
#                                   option 1 = include lock status
#                      Argument 5 - option 0 = no version information
#                                   option 1 = include version information
#                      Argument 6 - the name of a file to hold the results.
#
# Variable declaration.
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
#
    print "\n\n ERROR : Could not find one of the following environment variables\n";
    print "        temp, TEMP, tmp, TMP\n";
    exit(0);
}
#
# Get the file to be processed from the command line. if a command line argument is
# not given then get the name from a prompt.
#
$FileListHolderFile = $ARGV[0];
$LabelStatus = $ARGV[1];
$VersionsToReport = $ARGV[2];
$LockStatusToReport = $ARGV[3];
$IncludeVersionNumbers = $ARGV[4];
$ResultFile = $ARGV[5];
#
# Open the file containing the list of files to be processed and read the contents.
#
$Counter = 0;
#
open (FileListFileHandle, $FileListHolderFile);
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
            print $LineFromFile."\n";
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
# Set the result title.
#
$Result = "Filename,Doc No., Doc Name,Issue,Author,Date,Labels,Version No.,Locked by,Lock Date\n";
# For each file to be processed lock the file.
#
foreach $File (@FilesToProcess)
{
    $_ = $File;
    if (m/lost\+found/)
    {
#       Skip any element in lost+found.
#
    }
    else
    {
#
#   Describe command for element.
#
    $DescribeCommand = "cleartool describe -fmt \"%[DocNum]a\\n%[DocName]a\\n\" ".$File."@@";
#
    $CommandResult = `$DescribeCommand`;
    print $File."\n".$CommandResult."\n";
    split(/\n/,$CommandResult);
    $DocNum = @_[0];
    $DocNum =~ s/\(DocNum=\"//;
    $DocNum =~ s/\"\)//;
    $DocName = @_[1];
    $DocName =~ s/\(DocName=\"//;
    $DocName =~ s/\"\)//;
#
#   Get lock status if required.
#
    if (($LockStatusToReport cmp "1") == 0)
    {
#
#       Lock status is required.
#
        $LockStatusCommand = "cleartool lslock -fmt \"%u\\n%Sd\\n\" ".$File;
        $LockResult = `$LockStatusCommand`;
#
        if (length($LockResult) > 0)
        {
#
#           The file is locked - record the result.
#
            split(/\n/,$LockResult);
            $lockPerson = @_[0];
            $LockDate = @_[1];
            $LockData = ",".$lockPerson.",".$LockDate;
        }
        else
        {
            $LockData = ",NOT LOCKED,";
        }
    }
#
#   Describe command for version.
#   If each version is to be reported get the version information.
#
    if (($VersionsToReport cmp "1") == 0)
    {
#
#       Major event version only.
#
        $GetMajorEventCommand = "cleartool lsvtree -s ".$File;
        $MajorEvents = `$GetMajorEventCommand`;
#
        split(/\n/, $MajorEvents);
        @FileVersions = @_;
    }
    elsif (($VersionsToReport cmp "2") == 0)
    {
#
#       All event version.
#
        $GetAllEventCommand = "cleartool lsvtree -all -s ".$File;
        $AllEvents = `$GetAllEventCommand`;
#
        split(/\n/, $AllEvents);
        @FileVersions = @_;
    }
    else
    {
        $GetStdFileNameCommand = "cleartool ls -s ".$File;
        $StdFileName = `$GetStdFileNameCommand`;
        @FileVersions[0] = $StdFileName;
    }
#
    foreach $VersionFile (@FileVersions)
    {
        $VersionFile =~ s/\n//g;
        split(/@@/,$VersionFile);
        $FileName = @_[0];
        $VersionDetail = @_[1];
        split (/\\/,$VersionDetail);
        $Number = @_;
#
#       Get the final part of the version name and split it into an array. Then check each
#       character to see if it is a number or a character. If a character is encountered then
#       the part is a branch name and should not be processed.
#
        $FinalPart = @_[$Number - 1];
#
        split(/ */,$FinalPart);
        $NotNumeric = "0";
        foreach $Character (@_)
        {
            print "** ".$Character."  ".length($character)."\n";
            if ((($Character cmp "0") != 0) && (($Character cmp "1") != 0) && (($Character cmp "2") != 0) && (($Character cmp "3") != 0) && (($Character cmp "4") != 0) && (($Character cmp "5") != 0) && (($Character cmp "6") != 0) && (($Character cmp "7") != 0) && (($Character cmp "8") != 0) && (($Character cmp "9") != 0))
            {
#
#               not numeric.
#
                print "failed\n";
                $NotNumeric = "1";
            }
        }


        if (($NotNumeric cmp "0") == 0)
        {
            print $VersionFile."\n";
            if ((($IncludeVersionNumbers cmp "1") == 0) && (($LabelStatus cmp "1") == 0))
            {
                $DescribeCommand = "cleartool describe -fmt \"%[IssueLetter]a\\n%u\\n%Sd\\n%l\\n%Vn\\n\" ".$VersionFile;
            }
            elsif ((($IncludeVersionNumbers cmp "0") == 0) && (($LabelStatus cmp "1") == 0))
            {
                $DescribeCommand = "cleartool describe -fmt \"%[IssueLetter]a\\n%u\\n%Sd\\n%l\\n\" ".$VersionFile;
            }
            elsif ((($IncludeVersionNumbers cmp "1") == 0) && (($LabelStatus cmp "0") == 0))
            {
                $DescribeCommand = "cleartool describe -fmt \"%[IssueLetter]a\\n%u\\n%Sd\\n%Vn\\n\" ".$VersionFile;
            }
            else
            {
                $DescribeCommand = "cleartool describe -fmt \"%[IssueLetter]a\\n%u\\n%Sd\\n\" ".$VersionFile;
            }
            print $DescribeCommand."\n";
#
            $CommandResult = `$DescribeCommand`;
            split(/\n/,$CommandResult);
            $IssueLetter = @_[0];
            $IssueLetter =~ s/\(IssueLetter=\"//;
            $IssueLetter =~ s/\"\)//;
            $UserName = @_[1];
            $Date = @_[2];
            $Result = $Result.$FileName.",".$DocNum.",".$DocName.",".$IssueLetter.",".$UserName.",".$Date;
#
#           Process results.
#
            if ((($IncludeVersionNumbers cmp "1") == 0) && (($LabelStatus cmp "1") == 0))
            {
                $Labels = @_[3];
                $Labels =~ s/\(//;
                $Labels =~ s/\)//;
                $Labels =~ s/ //g;
                $Labels =~ s/\,/ /g;
                $VersionNumber = @_[4];
                $Result = $Result.",".$Labels.",".$VersionNumber;
            }
            elsif ((($IncludeVersionNumbers cmp "0") == 0) && (($LabelStatus cmp "1") == 0))
            {
                $Labels = @_[3];
                $Labels =~ s/\(//;
                $Labels =~ s/\)//;
                $Labels =~ s/ //g;
                $Labels =~ s/\,/ /g;
                $Result = $Result.",".$Labels.",";
            }
            elsif ((($IncludeVersionNumbers cmp "1") == 0) && (($LabelStatus cmp "0") == 0))
            {
                $VersionNumber = @_[3];
                $Result = $Result.",,".$VersionNumber;
            }
            else
            {
                $Result = $Result.",,";
            }
#
            if (($LockStatusToReport cmp "1") == 0)
            {
                $Result = $Result.$LockData;
            }
            else
            {
                $Result = $Result.",,";
            }

            $Result = $Result."\n";
        }
    }
    }
}

#
# Make the ResultFile writeable.
#
$ResultFile = ">".$ResultFile;
open (ResultFileHandle, $ResultFile);
print ResultFileHandle $Result."\n";
close ResultFileHandle;