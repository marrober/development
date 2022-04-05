use OLE;
print "\nReading spreadsheet ";

$InputFileName = "c:\\data\\team\\SOW Log CY04.xls";
$excel = CreateObject OLE 'Excel.Application' or warn "Couldn't create new instance of Excel App!!";
$book = $excel->Workbooks->Open($InputFileName);

$sheet = $book->Worksheets(1);
$lastcol = $sheet->UsedRange->Columns->{Count};
$lastrow = $sheet->UsedRange->Rows->{Count};

$DatabaseRowCounter = 0;

$DisplayCounter = 0;

%SAccountData = "";

foreach $Row (1..$lastrow)
{
    $DisplayCounter++;

    if ($DisplayCounter > ($lastrow / 10))
    {
        $DisplayCounter = 0;

        print ".";
    }

	$SOW = $sheet->Cells(int($Row),int(1))->{Value};

	foreach $Col (2..$lastcol)
	{
		$AccountData[$SOW][$Col - 2] = $sheet->Cells(int($Row),int($Col))->{Value};
		
		print $sheet->Cells(int($Row),int($Col))->{Value}.",";
	}
	print ("\n");
}

$excel->Workbooks->Close($InputFileName);

$excel->Quit();



