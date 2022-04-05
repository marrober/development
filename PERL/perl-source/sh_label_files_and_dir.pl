#------------------------------------------------------------------------------
#------ PERL SCRIPT  : sh_label_files_and_dir.pl
#------ Authors Name : Mark Roberts
#------ Date         : 2 July, 1996.
#------ Description  : This script is called from Visual Basic and it adds a label
#                      to the selected file.
#                      Arguments :
#                           The name of a file containing a coma separated list of
#                           directories to be processed.
#                           The name of the label to be applied.
#                           The name of a file to hold the results.
#                           The name of a file that hold the comment.
#
# Variable declaration.
#
#
$DirectoryListHolderFile = $ARGV[0];
$LabelName = $ARGV[1];
$ResultFile = $ARGV[2];
$CommentFile = $ARGV[3];
#
open (DirectoryListFileHandle, $DirectoryListHolderFile);
while ((read (DirectoryListFileHandle, $LineFromFile, 300)) > 0)
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
            @DirectoriesToProcess[$Counter] = @SplitLines[$i];
            $Counter = $Counter + 1;
        }
        if ($#SplitLines == 0)
        {
            $LineFromFile =~ s/;//g;
            @DirectoriesToProcess[$Counter] = $LineFromFile;
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
close (DirectoryListFileHandle);
#
if (length($LineEnd) > 0)
{
    @DirectoriesToProcess[$Counter] = substr($LineEnd, 0, length($LineEnd) - 1);
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
foreach $Directory (@DirectoriesToProcess)
{
    if (length($Comment) > 0)
    {
        $AddLabelCommand = "cleartool mklabel -recurse -c \\".'""'.$Comment.'"'."\\".'" '.$LabelName." ".$Directory;
        print $AddLabelCommand."\n";
        $AddLabelresult = `$AddLabelCommand`;
        if ($? == 0)
        {
            print $AddLabelresult."\n";
            $Result = $Result.$AddLabelresult;
        }
        else
        {
            print "Error - unable to apply label $LabelName to $Directory\n";
            $Result = $Result."ERROR - Unable to Apply version label ".$LabelName." to some files or directories from $Directory.\n";

        }
    }
    else
    {
#
#       No comment to be added.
#
        $AddLabelCommand = "cleartool mklabel -recurse -nc $LabelName ".$Directory;
        $AddLabelresult = `$AddLabelCommand`;
        if ($? == 0)
        {
            print $AddLabelresult."\n";
            $Result = $Result.$AddLabelresult;
        }
        else
        {
            print "Error - unable to apply label $LabelName to $Directory\n";
            $Result = $Result."ERROR - Unable to Apply version label ".$LabelName." to some files or directories from $Directory.\n";

        }
    }
}
$ResultFile = ">".$ResultFile;
open (ResultFileHandle, $ResultFile);
print ResultFileHandle $Result."\n";
close ResultFileHandle;