use Win32::OLE;

$ExcelTargetData = Win32::OLE->new("Excel.Application", sub{undef $_[0];});
$bookTargetData = $ExcelTargetData->Workbooks->Open("c:\\temp\\mklbtype_performance.xls");

$sheetTargetData = $bookTargetData->Worksheets(1);
$lastcolTargetData = $sheetTargetData->UsedRange->Columns->{Count};
$lastrowTargetData = $sheetTargetData->UsedRange->Rows->{Count};

foreach ($RowCounter = 4; $RowCounter <= $lastrowTargetData; $RowCounter++) {
	foreach ($ColCounter = 1; $ColCounter <= 3; $ColCounter++) {	
		print $sheetTargetData->Cells($RowCounter, $ColCounter)->{Value}."\t\t";
	}
	print "\n";
}

$ExcelTargetData->Workbooks->Close("c:\\temp\\mklbtype_performance.xls");
$ExcelTargetData->Quit();
