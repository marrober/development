#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_label_files.pl
#------ Authors Name : Mark Roberts
#------ Date         : 2 July, 1996.
#------ Description  : This script is called from Visual Basic and it adds a label
#                      to the selected file.
#                      Arguments :
#                           The name of a file containing a coma separated list of
#                           files to be processed.
#                           The name of the label to be applied.
#                           The name of a file to hold the results.
#                           The name of a file that hold the comment.
#
# Variable declaration.
#
#
$FileListHolderFile = $ARGV[0];
$LabelName = $ARGV[1];
$ResultFile = $ARGV[2];
$CommentFile = $ARGV[3];
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
if (($CommentFile cmp "NONE") == 0)
{
    $Comment = "";
}
else
{
    open(CommentFileHandle, $CommentFile);
    while ($LinesToRead == 0)
    {
        if (eof(CommentFileHandle) == 1)
        {
            $LinesToRead = 1;
        }
        else
        {
            read(CommentFileHandle, $CommentBuffer, 1024);
            $Comment = $Comment.$CommentBuffer;
        }
    }
    close(CommentFileHandle);
}
foreach $File (@FilesToProcess)
{
    if (length($Comment) > 0)
    {
        $AddLabelCommand = "cleartool mklabel -c \\".'""'.$Comment.'"'."\\".'" '.$LabelName." ".$File;
        print $AddLabelCommand."\n";
        `$AddLabelCommand`;
        if ($? == 0)
        {
            print "Version label $LabelName added to $File\n";
            $Result = $Result."Version label ".$LabelName." added to ".$File."\n";
        }
        else
        {
            $LabelSearchCommand = "cleartool find $File -directory".
	                              " -version {lbtype($LabelName)} -print";
            $LabelSearchResult = `$LabelSearchCommand`;
#
            print length($LabelSearchResult)."\n".$LabelSearchResult."\n";
            if (length($LabelSearchResult) > 1)
            {
                print "Version label $LabelName already present on $File\n";
                $Result = $Result."Version label ".$LabelName." already present on ".$File."\n";
            }
            else
            {
                print "Error - unable to apply label $LabelName to $File\n";
                $Result = $Result."ERROR - Unable to Apply version label ".$LabelName." to ".$File."\n";
            }
        }
    }
    else
    {
#
#       No comment to be added.
#
        $AddLabelCommand = "cleartool mklabel -nc $LabelName ".$File;
        `$AddLabelCommand`;
        if ($? == 0)
        {
            print "Version label $LabelName added to $File\n";
            $Result = $Result."Version label ".$LabelName." added to ".$File."\n";
        }
        else
        {
            $LabelSearchCommand = "cleartool find $File -directory".
	                              " -version {lbtype($LabelName)} -print";
            $LabelSearchResult = `$LabelSearchCommand`;
#
            print length($LabelSearchResult)."\n".$LabelSearchResult."\n";
            if (length($LabelSearchResult) > 1)
            {
                print "Version label $LabelName already present on $File\n";
                $Result = $Result."Version label ".$LabelName." already present on ".$File."\n";
            }
            else
            {
                print "Error - unable to apply label $LabelName to $File\n";
                $Result = $Result."ERROR - Unable to Apply version label ".$LabelName." to ".$File."\n";
            }
        }
    }
}
$ResultFile = ">".$ResultFile;
open (ResultFileHandle, $ResultFile);
print ResultFileHandle $Result."\n";
close ResultFileHandle;