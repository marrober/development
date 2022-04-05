#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_describe_db.pl
#------ Authors Name : Mark Roberts
#------ Date         : 21 May, 1997.
#------ Description  : Shell PERL script to generate a report of all documents
#                      that is to be displayed using a Visual Basic program.
#                      Arguments to the script are as listed below :
#                      Argument 1 - a file containing a semi-colon separated list
#                                   of files to process.
#                      Argument 2 - the name of a file to hold the results.
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
$ResultFile = $ARGV[1];
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
    $_ = $LineFromFile;
    if (m/\n/)
    {
        if ((substr($LineFromFile, length($LineFromFile) - 1, 1) cmp "\n") == 0)
        {
            $SemiEnd = 1;
        }
        else
        {
            $SemiEnd = 0;
        }
        @SplitLines = split(/\n/g, $LineFromFile);
        for ($i = 0; $i < $#SplitLines; $i++)
        {
            @FilesToProcess[$Counter] = @SplitLines[$i];
            $Counter = $Counter + 1;
        }
        if ($#SplitLines == 0)
        {
            $LineFromFile =~ s/\n//g;
            @FilesToProcess[$Counter] = $LineFromFile;
            print $LineFromFile."\n";
            $Counter = $Counter + 1;
        }
        if ($#SplitLines > 0)
        {
            if ($SemiEnd == 1)
            {
                $LineEnd = @SplitLines[$#SplitLines]."\n";
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
$Result = "";
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
#       Describe command for element.
#
        $DescribeCommand = "cleartool describe -fmt \"%[DocNum]a\\n%[DocName]a\\n\" ".$File."@@";
#
        $CommandResult = `$DescribeCommand`;
        split(/\n/,$CommandResult);
        $DocNum = @_[0];
        $DocNum =~ s/\(DocNum=\"//;
        $DocNum =~ s/\"\)//;
        $DocName = @_[1];
        $DocName =~ s/\(DocName=\"//;
        $DocName =~ s/\"\)//;
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
            $LockData = "#~".$lockPerson."#~".$LockDate;
        }
        else
        {
            $LockData = "#~NOT LOCKED#~";
        }
#
        $GetStdFileNameCommand = "cleartool ls -s ".$File;
        $StdFileName = `$GetStdFileNameCommand`;
        @FileVersions[0] = $StdFileName;
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
#           Get the final part of the version name and split it into an array. Then check each
#           character to see if it is a number or a character. If a character is encountered then
#           the part is a branch name and should not be processed.
#
            $FinalPart = @_[$Number - 1];
#
            split(/ */,$FinalPart);
            $NotNumeric = "0";
            foreach $Character (@_)
            {
                if ((($Character cmp "0") != 0) && (($Character cmp "1") != 0) && (($Character cmp "2") != 0) && (($Character cmp "3") != 0) && (($Character cmp "4") != 0) && (($Character cmp "5") != 0) && (($Character cmp "6") != 0) && (($Character cmp "7") != 0) && (($Character cmp "8") != 0) && (($Character cmp "9") != 0))
                {
#
#                   not numeric.
#
                    $NotNumeric = "1";
                }
            }
#
            if (($NotNumeric cmp "0") == 0)
            {
                $DescribeCommand = "cleartool describe -fmt \"%[IssueLetter]a\\n%u\\n%Sd\\n%l\\n%Vn\\n\" ".$VersionFile;
#
                $CommandResult = `$DescribeCommand`;
                split(/\n/,$CommandResult);
                $IssueLetter = @_[0];
                $IssueLetter =~ s/\(IssueLetter=\"//;
                $IssueLetter =~ s/\"\)//;
                $UserName = @_[1];
                $Date = @_[2];
                $Result = $Result.$FileName."#~".$DocNum."#~".$DocName."#~".$IssueLetter."#~".$UserName."#~".$Date;
#
#               Process results.
#
                $Labels = @_[3];
                $Labels =~ s/\(//;
                $Labels =~ s/\)//;
                $Labels =~ s/ //g;
                $Labels =~ s/\,/ /g;
                $VersionNumber = @_[4];
                $Result = $Result."#~".$Labels."#~".$VersionNumber;
#
                if (length($LockData) > 0)
                {
                    $Result = $Result.$LockData;
                }
                else
                {
                    $Result = $Result."#~#~";
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