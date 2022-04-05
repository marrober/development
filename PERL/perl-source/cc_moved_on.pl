#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_moved_on.pl
#------ Authors Name : Mark Roberts
#------ Date         : 8th December, 1998.
#------ Description  : This script locates files whose version visible in the
#                      view is further down the version tree than the given
#                      label.
#
# Variable declaration.
#
# Get the label.
#
$Label = $ARGV[0];
#
print "Searching for files that have a version visible in the view after the\n";
print "application of the '".$Label."' label.\n";
print "The report shows the following : \n";
print "<filename> LABELLED version : VISIBLE version\n";
#
# Find all files that have the label.
#
$FilesWithLabel = `cleartool find . -version {lbtype($Label)} -print`;

@LabelledFilesArray = split(/\n/, $FilesWithLabel);

foreach $LabelledFile (@LabelledFilesArray)
{
    #
    # Split the name and the version information.
    #
    @SplitLine = split(/@@/, $LabelledFile);
    $CurrentVersionCommand = "cleartool desc -fmt ".'\"'."%Vn".'\"'." ".$SplitLine[0];
    $CurrentVersionInfo = `$CurrentVersionCommand`;

    $CurrentVersionInfo =~ s/\"//g;

    #  split each version report on the / character.
    @LabelledArrayVersionReport = split(/\\/, $SplitLine[1]);
    @CurrentArrayVersionReport = split(/\\/, $CurrentVersionInfo);

    $Result = 0;

    if ($#LabelledArrayVersionReport == $#CurrentArrayVersionReport)
    {
        $Counter = 0;

        foreach $Section (@LabelledArrayVersionReport)
        {
            if ($LabelledArrayVersionReport[$Counter] != $CurrentArrayVersionReport[$Counter])
            {
                $Result = 1;
            }
            $Counter++;
        }
    }
    else
    {
        $Result = 1;
    }

    if ($Result == 1)
    {
        # Check for a merge hyperlink from the version visible in the view to the
        # version of the file that has the label.
        #
        $GetMergeDataCommand = "cleartool desc ".$LabelledFile;
        $MergeResult = `$GetMergeDataCommand`;

        @SplitResult = split(/\n/, $MergeResult);

        $Result = 1;

        foreach $_ (@SplitResult)
        {
            if(m/Merge <-/)
            {
                $Result = 0;
                # Merge line.
                #
                @SplitMergeLine = split(/@@/, $_);

                #  split each version report on the / character.
                @LabelledArrayVersionReport = split(/\\/, $SplitMergeLine[1]);

                if ($#LabelledArrayVersionReport == $#CurrentArrayVersionReport)
                {
                    $Counter = 0;

                    foreach $Section (@LabelledArrayVersionReport)
                    {
                        if ($LabelledArrayVersionReport[$Counter] != $CurrentArrayVersionReport[$Counter])
                        {

                            $Result = 1;
                        }
                        $Counter++;
                    }
                }
                else
                {
                    $Result = 1;
                }
            }
        }
    }
    if ( $Result == 1)
    {
        print @SplitLine[0]." ".@SplitLine[1]." : ".$CurrentVersionInfo."\n";
    }
}

