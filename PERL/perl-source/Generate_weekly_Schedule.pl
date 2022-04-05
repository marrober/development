use OLE;
use File::stat;

$OS = @ARGV[0];

if ($OS eq "") { $OS = "NT"; }

# Get the current date to decide which quarter is current.

my @TimeArray = localtime(time);

my $MonthIndex = @TimeArray[4];

my $Quarter = "";

if ($MonthIndex <= 2) { $Quarter = "Q4"; $QStartMonth = 1;}
elsif ($MonthIndex => 3 && $MonthIndex <= 5) { $Quarter = "Q1"; $QStartMonth = 4; }
elsif ($MonthIndex => 6 && $MonthIndex <= 8) { $Quarter = "Q2"; $QStartMonth = 7; }
else { $Quarter = "Q3"; $QStartMonth = 10;}

$DoneCounter = 0;

$ForecastSpreadsheet = "c:\\data\\services\\temp.xls"; 

# Get target data.
$ExcelData = Win32::OLE->new("Excel.Application", sub{undef $_[0];});
$BookData = $ExcelData->Workbooks->Open($ForecastSpreadsheet);

$SheetData = $BookData->Worksheets(4);
for $Counter(1..4)
{
    print $SheetData->Cells(1, $Counter)->{Value}."\n";
}

$ExcelData->Workbooks->Close($ForecastSpreadsheet);
$ExcelData->Quit();

############################################################################
sub FormatPrice
############################################################################
{
    my ($Value) = @_;
    if ($Value eq "\&nbsp\;")
    {
        $P = $Value;
    }
    elsif ($Value eq 0)
    {
        $P = "0.00";
    }
    else
    {
        if (index($Value, "\.") == -1)
        {
            $Pounds = $Value;
            $Pence = "00";
        }
        else
        {
            $Pounds = substr($Value, 0, index($Value, "\."));
            $Pence = substr($Value, index($Value, "\.") + 1, 2);
        }

        # Rounding for pennies

        if (length($Pence) == 0)
        {
            $Pence = "00";
        }

        if (length($Pounds) >= 7)
        {
            $P = substr($Pounds, -3, 3);
            $P = substr($Pounds, -6, 3).",".$P;
            $P = substr($Pounds, 0, length($Pounds) - 6).",".$P."\.".$Pence;
            if (length($Pence) == 1) { $P = $P."0"; }
        }
        elsif ((length($Pounds) >= 4) && (length($Pounds) <= 6))
        {
            $P = substr($Pounds, -3, 3);
            $P = substr($Pounds, 0, length($Pounds) - 3).",".$P."\.".$Pence;
            if (length($Pence) == 1) { $P = $P."0"; }
        }
        else
        {
            $P = $Pounds."\.".$Pence;
        }
    }
    return $P;
}

############################################################################
sub FormatPriceForSummary
############################################################################
{
    my ($Value) = @_;
    if ($Value eq "\&nbsp\;")
    {
        $P = $Value;
    }
    elsif ($Value eq 0)
    {
        $P = "0";
    }
    else
    {
        if (index($Value, "\.") == -1)
        {
            $Pounds = $Value;
        }
        else
        {
            $Pounds = substr($Value, 0, index($Value, "\."));
        }

        if (length($Pounds) >= 7)
        {
            $P = substr($Pounds, -3, 3);
            $P = substr($Pounds, -6, 3).",".$P;
            $P = substr($Pounds, 0, length($Pounds) - 6).",".$P;
        }
        elsif ((length($Pounds) >= 4) && (length($Pounds) <= 6))
        {
            $P = substr($Pounds, -3, 3);
            $P = substr($Pounds, 0, length($Pounds) - 3).",".$P;
        }
        else
        {
            $P = $Pounds;
        }
    }
    return $P;
}


############################################################################
sub FormatPercentforSummary
############################################################################

{
    my ($Value) = @_;

    return(sprintf("%.1f", $Value));
}


############################################################################
sub FormatPercent
############################################################################

{
    my ($Value) = @_;

    return(sprintf("%5.1f%%", $Value));
}


############################################################################
sub StripLeadTrailSpaces
############################################################################

{
    my($String) = @_;

    while (substr($String, length($String) - 1, 1) eq " ")
    {
        $String = substr($String, 0, length($String) - 1);
    }

    while (substr($String, 0, 1) eq " ")
    {
        $String = substr($String, 1,);
    }


    return($String);
}
############################################################################
sub GetHTMLTemplate
############################################################################

{
    my ($FileName) = @_;

    open InputFileHandle, $FileName;

    while (eof(InputFileHandle) == 0)
    {
        read InputFileHandle, $DataFromFile, 25;
        $DefinitionData = join('',$DefinitionData, $DataFromFile);
    }

    close InputFileHandle;

    return($DefinitionData);
}
############################################################################
sub WriteResultsFile
############################################################################
{
    my($ResultsFile, $ResultsData) = @_;

    open OUT_FILE, $ResultsFile;
    print OUT_FILE $ResultsData;
    close OUT_FILE;
}

