#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_label.pl
#------ Authors Name : Mark Roberts
#------ Date         : 27 November, 1996.
#------ Description  : This script adds a label to all files and directories
#                      from the current point onwards.
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
    print "\n\n ERROR : Could not find one of the following environment variables\n";
    print "        temp, TEMP, tmp, TMP\n";
    exit(0);
}
#
#Get the script start time, for a report after processing.
#
$StartTime = time;
#
# Print sign on information.
#
print "Recursive item label application to all files and directories from\n";
print "(and including) current directory down.\n";
#
# Get the label type.
#
$HoldingFile = $EnvTemp."\\hold.tmp";
`clearprompt text -outfile $HoldingFile -prompt "Enter the label (or leave blank for a list of labels)."`;
#
# Get the data from the file.
#
open(HoldingFileHandle, $HoldingFile);
read(HoldingFileHandle, $LabelName, 1024);
close(HoldingFileHandle);
#
# Remove the file that held the comment.
#
`del $HoldingFile`;
#
if (length($LabelName) == 0)
{
# Display list of label types.
#
    print "Defined label types in this VOB and any associated administrative VOB.\n\n";
    $LabeListResult = `cleartool lstype -lbtype -s`;
    print $LabeListResult."\n";
#
    print "NOTE : You cannot use the label types CHECKEDOUT or LATEST in assignments\n";
#
# Get label type again.
#
    $HoldingFile = $EnvTemp."\\hold.tmp";
    `clearprompt text -outfile $HoldingFile -prompt "Enter the label."`;
#
# Get the data from the file.
#
    open(HoldingFileHandle, $HoldingFile);
    read(HoldingFileHandle, $LabelName, 1024);
    close(HoldingFileHandle);
#
# Remove the file that held the comment.
#
    `del $HoldingFile`;
#
}
if (length($LabelName) > 0)
{
# A label has been entered so get the comment.
#
    $HoldingFile = $EnvTemp."\\hold.tmp";
    `clearprompt text -outfile $HoldingFile -prompt "Enter a comment for the label addition process."`;
#
# Get the data from the file.
#
    open(HoldingFileHandle, $HoldingFile);
    read(HoldingFileHandle, $LabelAddComment, 1024);
    close(HoldingFileHandle);
#
# Remove the file that held the comment.
#
    `del $HoldingFile`;
#
# Get the list of files to process.
#
    @FileList=`dir /b /s`;
#
# Get the number of files to be processed and display this number.
#
    $FilesToProcess = $#FileList + 1;
#
    print $FilesToProcess." Files (and directories) to be processed.\n";
#
# Depending on the length of the comment select which block of commands
# to use to add the labels. If the comment has a length >= 1 then
# there is a comment to store.
#
    if (length($LabelAddComment) >= 1)
    {
#
# Execute the add label command and display the result on the screen.
#
        $AddLabelCommand = "cleartool mklabel -recurse -c \\".'""'.$LabelAddComment.'"'."\\".'" '.$LabelName." .";
        print $AddLabelCommand."\n";
        $AddLabeLResult = `$AddLabelCommand`;
        if ($? == 0)
        {
            print $AddLabeLResult."\n";
        }
        else
        {
            `clearprompt yes_no -type warning -default no -mask yes,no -prompt "The label '$LabelName' already exists. Replace ?"`;
            if ($? == 0)
            {
                $AddLabelCommand = "cleartool mklabel -replace -recuse -c \\".'""'.$LabelAddComment.'"'."\\".'" '.$LabelName." .";
                print $AddLabelCommand."\n";
                `$AddLabelCommand`;
                if ($? == 0)
                {
                    print "Version label $LabelName added to $FileToProcess\n";
                }
                else
                {
                    `clearprompt proceed -type error -default abort -mask abort -prompt "Unable to add the version label $LabelName."`;
                }
            }
        }
    }
    else
    {
#
# No comment to be added.
#
        $AddLabelCommand = "cleartool mklabel -recurse -nc $LabelName .";
        $AddLabeLResult = `$AddLabelCommand`;
        if ($? == 0)
        {
            print $AddLabeLResult."\n";
        }
        else
        {
            `clearprompt yes_no -type warning -default no -mask yes,no -prompt "The label '$LabelName' already exists. Replace ?"`;
            if ($? == 0)
            {
                $AddLabelCommand = "cleartool mklabel -replace -recuse -nc $LabelName .";
                print $AddLabelCommand."\n";
                `$AddLabelCommand`;
                if ($? == 0)
                {
                    print "Version label $LabelName added to $FileToProcess\n";
                }
                else
                {
                    `clearprompt proceed -type error -default abort -mask abort -prompt "Unable to add the version label $LabelName to the file $FileToProcess"`;
                }
            }
        }
    }
}
#
$EndTime = time;
print "\n\nElasped time = ". ($EndTime - $StartTime). " seconds.";