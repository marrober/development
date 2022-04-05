# Put the appropriate license server name here.
$LIC_SERVER="put th ename of the license server here";
# The name of the file to hold summary information.
$Summary = "summary.txt";
# The name of the log file.
$LogFileName = "log.txt";
my @TimeArray = localtime(time);
$CurrentDate = @TimeArray[3]."/".(@TimeArray[4] + 1)."/".(@TimeArray[5] + 1900);
if (@TimeArray[2] <= 9)
{
    $Time = "0".@TimeArray[2];
}
else
{
    $Time = @TimeArray[2];
}
if (@TimeArray[1] <= 9)
{
    $Time .= ":0".@TimeArray[1];
}
else
{
    $Time .= ":".@TimeArray[1];
}
$CurrentDateTime = $CurrentDate." ".$Time;
# Add unquoted list of products for which licenses are to be recorded. Use the actual word reported by the
# FlexLM license tools. Use the command 'lmutil lmstat -a' to show the appropriate keywords to use for the
# products that you have.
@FlexLicenses = qw(RationalSuiteEnterprise DevelopmentStudio);
# Add an unquoted list of suitable license key abreviations. In the summary document these abreviations will
# have -Max and -Cur appended to them to indicate maximum available licenses and current license use.
@LicenseAbreviations = qw(RSE RSDS);
$SummaryData = $CurrentDateTime;
foreach $Flex (@FlexLicenses)
{   
    print "=========================================================\n";
    GetSuiteLicenseUse($Flex);
    UpdateUseStats($Flex, $LogFileName);
    ClearDataStructures();
    $SummaryData .= ",".$MaxLicenses.",".$UseCount;
}

$SummaryData .= "\n";
# ClearCase block - remove is ClearCase is not used.
# print "=========================================================\n";
# ClearDataStructures();
# GetClearCaseLicenseUse("ClearCase");
# UpdateUseStats("ClearCase", $LogFileName);
# $SummaryData .= ",".$MaxLicenses.",".$UseCount;
# End of ClearCase block
# ClearCase MultiSite block - remove is ClearCase is not used.
# print "=========================================================\n";
# ClearDataStructures();
# GetClearCaseLicenseUse("MultiSite");
# UpdateUseStats("MultiSite", $LogFileName);
# $SummaryData .= ",".$MaxLicenses.",".$UseCount."\n";
# End of ClearCase MultiSite block
if (-e $Summary){
    $Summary = ">>".$Summary;
    open SUMMARY, $Summary;
    print SUMMARY $SummaryData;
    close SUMMARY;
}
else
{
    $Summary = ">".$Summary;
    open SUMMARY, $Summary;
    print SUMMARY "Date & Time";
    foreach $LicAbr (@LicenseAbreviations)
    {
        print SUMMARY ",".$LicAbr."-Max,".$LicAbr."-Cur";
    }
    print SUMMARY "\n".$SummaryData;
    close SUMMARY;
}
exit(0);

sub GetSuiteLicenseUse{

    my ($LicType) = @_;
    print $LicType."\n";
    $GetLicenseDataCmd = "lmutil lmstat -f ".$LicType;
    $LicenseData = `$GetLicenseDataCmd`;
    # Split the license report data into an array and process it.
    #
    @LicenseArray = split("\n", $LicenseData);
    $LineCounter = 1;
    $UseCount = 0;
    foreach $_ (@LicenseArray)
    {
        # Get the total number of licenses available.
        #
        if ((m/\(Total of/) && (m/licenses available/))
        {
            $MaxLicensesTmp = substr($_, index($_, "Total of ") + length("Total of "));
            $MaxLicenses = substr($MaxLicensesTmp, 0, index($MaxLicensesTmp, " "));
        }
        # Get the date that the command was run.
        #
        if (m/Flexible License Manager status on/)
        {
            $DateSampled = substr($_, index($_, "Flexible License Manager status on ") + length("Flexible License Manager status on ") + 4);
            @DateTime = split(" ", $DateSampled);
            @DateParts = split("/", @DateTime[0]);
            $DateSampled = @DateParts[1]."/".@DateParts[0]."/".@DateParts[2];
            $DateTimeSampled = $DateSampled." ".@DateTime[1];
        }
        # Get the total number of lines that start at the specific column.
        # These are the names of the users.
        #
        if ($LineCounter >  9)
        {
            if (m/^    ([A-Z]|[a-z]|[0-9])/)
            {
                $UserInformation = substr($_, 4);
                @UserInformationArray = split(" ", $UserInformation);
                $UserName = @UserInformationArray[0];
                $ClientIPAddress = @UserInformationArray[1];
                $ClientMachineName = @UserInformationArray[2];
                # push the username, IP address and the client PC name into an array for processing later.
                #
                push @UseArray, $UserName.",".$ClientIPAddress.",".$ClientMachineName."\n";
                $UseCount++;
            }
        }
        $LineCounter++;
    }
    $ResultString = $DateSampled.",".$MaxLicenses.",".$UseCount;
    print "Max Licenses : ".$MaxLicenses." ";
    print "Use count : ".$UseCount."\n";
}
sub GetClearCaseLicenseUse
{
    my ($LicType) = @_;
    print $LicType."\n";
    $GetLicenseDataCmd = "clearlicense -product ".$LicType;
    $LicenseData = `$GetLicenseDataCmd`;
    print $LicenseData."\n";
    $DateSampled = $CurrentDate;
    $DateTimeSampled = $CurrentDateTime;
    # Split the license report data into an array and process it.
    #
    @LicenseArray = split("\n", $LicenseData);
    $LineCounter = 1;
    $UseCount = 0;
    foreach $_ (@LicenseArray)
    {
        # Get the total number of licenses available.
        #
        if (m/\Maximum active users allowed:/)
        {
            $MaxLicenses = substr($_, index($_, ": ") + length(": "));
        }
        # Get the total number of lines that start at the specific column.
        # These are the names of the users.
        #
        if (m/Current active users:/)
        {
            $UseCount = substr($_, index($_, ": ") + length(": "));
        }
        if (m/License Usage Statistics/)
        {
            $ActiveUsersRegion = 0;
        }
        if ((!m/Time-out in/) && ($ActiveUsersRegion == "1") && (m/$\\)/))
        {
            for ($Counter = 0; $Counter < 20; $Counter++)
            {
                $_ =~ s/  / /g;
            }
            $_ =~ s/^ //g;
            @UseData = split(" ", $_);
            push @UseArray, @UseData[0]."\n";
        }
        if (m/ACTIVE users:/)
        {
            $ActiveUsersRegion = 1;
        }
    }
    $ResultString = $DateSampled.",".$MaxLicenses.",".$UseCount;
    print "Max Licenses : ".$MaxLicenses." ";
    print "Use count : ".$UseCount."\n";
}

sub UpdateUseStats{
    my ($StatsFileName, $LogFile) = @_;
    $StatsFileName = $StatsFileName."\.txt";
    # Get the current usage information from the file.
    #
    if (-e $StatsFileName)
    {
        # The file exists.
        $FileData = "";
        open STATS_FILE, $StatsFileName;
        while (!eof(STATS_FILE))
        {
            read STATS_FILE, $Buffer, 25;
            $FileData .= $Buffer;
        }
        close STATS_FILE;
        # Populate the hash data.
        #
        @FileDataArray = split("\n", $FileData);
        pop(@FileDataArray);
        @NamesList = split("\,", @FileDataArray[0]);
        @NamesList = reverse(@NamesList);
        pop(@NamesList);
        @NamesList = reverse(@NamesList);
        for ($DataCounter = 1; $DataCounter <= $#FileDataArray; $DataCounter++)
        {
            @LineContent = split("\,", @FileDataArray[$DataCounter]);
            for ($RowCounter = 1; $RowCounter <= $#LineContent; $RowCounter++)
            {
                $Data{$LineContent[0]}{@NamesList[$RowCounter - 1]} = @LineContent[$RowCounter];
            }
        }
        # Print the file data to screen.
        #
        print "-------------------------------------------------------------------\n";
        print "Old statistics .....\n";
        for $Date (sort SortDates keys %Data)
        {
            print $Date.".... ";
            for $Person (sort keys %{$Data{$Date}})
            {
                print $Person." = ".$Data{$Date}{$Person}." ";
            }
            print "\n";
        }
    }
    $DateFound = 0;
    for $Date (sort keys %Data)
    {
        $_ = $Date;
        if (m/$DateSampled/)
        {
            $DateFound = 1;
        }
    }
    if ($DateFound == "0")
    {
        print "Date to be added.\n";
        foreach $Name (@NamesList)
        {
            $Data{$DateSampled}{$Name} = 0;
            print "placeholder for : ".$Name."\n";
        }
    }
    # Add new names to the hash if necessary.
    #
    foreach $Use (@UseArray)
    {
        if (index($Use, ",") > 0)
        {
            @UseData = split("\,", $Use);
            $_ = @UseData[0];
        }
        else
        {
            if (index($Use, "\n") > 0)
            {
                $_ = $Use;
                $_ =~ s/\n//g;
            }
        }
        $NameFound = 0;
        foreach $CurrentName (@NamesList)
        {
            if (m/$CurrentName/)
            {
                $NameFound = 1;
            }
        }
        if ($NameFound == "0")
        {
            # Add the new name to the hash.
            for $Date (sort keys %Data)
            {
                $Data{$Date}{$_} = 0;
            }
        }
    }
    # Add current usage stats.
    #
    foreach $Use (@UseArray)
    {
        if (index($Use, ",") > 0)
        {
            @UseData = split("\,", $Use);
            $_ = @UseData[0];
        }
        else
        {
            if (index($Use, "\n") > 0)
            {
                $_ = $Use;
                $_ =~ s/\n//g;
            }
        }
        if ($Data{$DateSampled}{$_} == "")
        {
            $Data{$DateSampled}{$_} = "1";
        }
        else
        {
            $Data{$DateSampled}{$_}++;
        }
    }
    print "-------------------------------------------------------------------\n";
    print "New statistics .....\n";
    for $Date (sort SortDates keys %Data)
    {
        print $Date.".... ";
        for $Person (sort keys %{$Data{$Date}})
        {
            print $Person." = ".$Data{$Date}{$Person}." ";
        }
        print "\n";
        $LastDate = $Date;
    }
    # Totals
    #
    foreach $Person (keys %{$Data{$DateSampled}})
    {
        $Total = 0;
        for $Date (sort keys %Data)
        {
            $Total += $Data{$Date}{$Person};
        }
        $Totals{$Person} = $Total;
    }
    # Store the new data in the file.
    #
    print "-------------------------------------------------------------------\n";
    # Save the old stats to a .bak file.
    $CopyCmd = "copy ". $StatsFileName." ". $StatsFileName.".bak";
    `$CopyCmd`;
    $FileName = ">".$StatsFileName;
    open FILEHANDLE, $FileName;
    for $Person (sort keys %{$Data{$LastDate}})
    {
        print FILEHANDLE ",".$Person;
    }
    print FILEHANDLE "\n";
    for $Date (sort SortDates (keys %Data))
    {
        print FILEHANDLE $Date;
        for $Person (sort keys %{$Data{$Date}})
        {
            print FILEHANDLE ",".$Data{$Date}{$Person};
        }
        print FILEHANDLE "\n";
    }
    print FILEHANDLE "Totals";
    for $Person (sort keys %{Totals})
    {
        print FILEHANDLE ",".$Totals{$Person};
    }
    print FILEHANDLE "\n";
    close FILEHANDLE;
    $LogFile = ">>".$LogFile;
    open FILEHANDLE, $LogFile;
    foreach $Use (@UseArray)
    {
        print FILEHANDLE $DateTimeSampled.",".$StatsFileName.",".$Use;
    }
    close FILEHANDLE;
}

sub SortDates{    @AParts = split("\/", $a);
    @BParts = split("\/", $b);
    if (     @BParts[2] < @AParts[2])   {  return (1);   }
    elsif   (@BParts[2] > @AParts[2])   {  return (-1);  }
    if      (@BParts[1] < @AParts[1])   {  return(1);    }
    elsif   (@BParts[1] > @AParts[1])   {  return(-1);   }
    if      (@BParts[0] < @AParts[0])   {  return(1);    }
    elsif   (@BParts[0] > @AParts[0])   {  return(-1);   }
    else                                {  return(0);    }
}

sub ClearDataStructures{
    undef @UseArray;
    undef %Data;
    undef %Totals;
    undef @NamesList;
}














