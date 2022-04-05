#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_label.pl
#------ Authors Name : Mark Roberts
#------ Date         : 27 November, 1996.
#------ Description  : This script adds a label to the selected file.
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
print "Item label application.\n";
#
# Get the file to be processed from the command line. if a command line argument is
# not given then get the name from a prompt.
#
$FileToProcess = $ARGV[0];
#
if (length($FileToProcess) == 0)
{
    $HoldingFile = $EnvTemp."\\hold.tmp";
    `clearprompt file -outfile $HoldingFile -prompt "Select the name of a file to which you wish to add a label."`;
#
# Get the name of the file to be processed.
#
    open(HoldingFileHandle, $HoldingFile);
    read(HoldingFileHandle, $FileToProcess, 1024);
    close(HoldingFileHandle);
#
# Remove the file that held the comment.
#
    `del $HoldingFile`;
}
if (length($FileToProcess) == 0)
{
    print "Exit - No file selected\n";
    exit(0);
}
#
# Collecting information.
#
# Label type.
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
}
#
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
    if (length($LabelAddComment) >= 1)
    {

        $AddLabelCommand = "cleartool mklabel -c \\".'""'.$LabelAddComment.'"'."\\".'" '.$LabelName." ".$FileToProcess;
        print $AddLabelCommand."\n";
        `$AddLabelCommand`;
        if ($? == 0)
        {
            print "Version label $LabelName added to $FileToProcess\n";
        }
        else
        {
            `clearprompt yes_no -type warning -default no -mask yes,no -prompt "The label '$LabelName' already exists on $FileToProcess. Replace ?"`;
            if ($? == 0)
            {
                $AddLabelCommand = "cleartool mklabel -replace -c \\".'""'.$LabelAddComment.'"'."\\".'" '.$LabelName." ".$FileToProcess;
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
    else
    {
#
# No comment to be added.
#
        $AddLabelCommand = "cleartool mklabel -nc $LabelName ".$FileToProcess;
        `$AddLabelCommand`;
        if ($? == 0)
        {
            print "Version label $LabelName added to $FileToProcess\n";
        }
        else
        {
            `clearprompt yes_no -type warning -default no -mask yes,no -prompt "The label '$LabelName' already exists on $FileToProcess. Replace ?"`;
            if ($? == 0)
            {
                $AddLabelCommand = "cleartool mklabel -replace -nc $LabelName ".$FileToProcess;
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