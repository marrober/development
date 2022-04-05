use ClearCase::CtCmd;
use Win32::OLE;

$ExcelData = 	Win32::OLE->new("Excel.Application", sub{undef $_[0];});
$BookData = 	$ExcelData->Workbooks->Open("c:\\temp\\VobSpaceStats.xls");
$SheetData =	$BookData->Worksheets(1);
$LastCol = 		$SheetData->UsedRange->Columns->{Count};
$LastRow = 		$SheetData->UsedRange->Rows->{Count};

print "Last column : ".$LastCol."\nLast row : ".$LastRow."\n";

$inst = ClearCase::CtCmd->new();




($Status, $VobList, $err)=$inst->exec(lsvob, "-s");
if ($inst->status()) { die $err; }

@VobListArray = split("\n", $VobList);

foreach $VOB (@VobListArray) {
	print "Collecting space stats for ".$VOB."\n";
	($Status, $SpaceData, $err)=$inst->exec(space, "-vob", $VOB);
	@SplitSpaceData = split("\n", $SpaceData);
	foreach $SpaceLine (@SplitSpaceData) {
		@SplitSpaceLine = split(" ", $SpaceLine);
		$_ = @SplitSpaceLine[2];
		if (/VOB/) { 			$VobSpace{$VOB}{"DB"} = @SplitSpaceLine[0]; }
		elsif (/cleartext/) { 	$VobSpace{$VOB}{"CT"} = @SplitSpaceLine[0]; }
		elsif (/derived/) { 	$VobSpace{$VOB}{"DO"} = @SplitSpaceLine[0]; }
		elsif (/source/) { 		$VobSpace{$VOB}{"SR"} = @SplitSpaceLine[0]; }
	}
}
	
@TimeArray = localtime(time);
$CurrentDate = @TimeArray[3]."/".(@TimeArray[4] + 1)."/".(@TimeArray[5] + 1900)." ";
if (@TimeArray[2] <= 9) { $Time = "0".@TimeArray[2]; }
else                   {  $Time = @TimeArray[2]; }
if (@TimeArray[1] <= 9) { $Time .= ":0".@TimeArray[1]; }
else                   {  $Time .= ":".@TimeArray[1]; }
$CurrentDate .= $Time;
print $CurrentDate."\n";
$RowToUpdate = $LastRow + 1;
$SheetData->Cells($RowToUpdate, 1)->{Value} = $CurrentDate;

foreach $VOB (keys %VobSpace) {
	# Search for the VOB in the spreadsheet
	$DBColumn = 0;	
	for ($ColCounter = 1; $ColCounter < $LastCol; $ColCounter++) {
		$_ = $SheetData->Cells(1, $ColCounter)->{Value};
		$_ =~ s/\\/\\\\/g;
		$VOBtemp = $VOB;
		$VOBtemp =~ s/\\/\\\\/g;
		if ((/$VOBtemp/) && ($DBColumn == 0)) {
			# Entry exists for the vob database.
			$DBColumn = $ColCounter;
		}
	}
	if ($DBColumn == 0) { 
		$DBColumn = $LastCol + 1; 
		$SheetData->Cells(1, $DBColumn)->{Value} = $VOB."-[DB]";
		$SheetData->Cells($RowToUpdate, $DBColumn++)->{Value} = $VobSpace{$VOB}{"DB"};
		$SheetData->Cells(1, $DBColumn)->{Value} = $VOB."-[CT]";
		$SheetData->Cells($RowToUpdate, $DBColumn++)->{Value} = $VobSpace{$VOB}{"CT"};			
		$SheetData->Cells(1, $DBColumn)->{Value} = $VOB."-[DO]";
		$SheetData->Cells($RowToUpdate, $DBColumn++)->{Value} = $VobSpace{$VOB}{"DO"};			
		$SheetData->Cells(1, $DBColumn)->{Value} = $VOB."-[SR]";
		$SheetData->Cells($RowToUpdate, $DBColumn++)->{Value} = $VobSpace{$VOB}{"SR"};					
		$SheetData->Cells(1, $DBColumn)->{Value} = $VOB;
		$SheetData->Cells($RowToUpdate, $DBColumn++)->{Value} = $VobSpace{$VOB}{"DB"} + $VobSpace{$VOB}{"CT"} + $VobSpace{$VOB}{"DO"} + $VobSpace{$VOB}{"SR"};
		$LastCol += 5;
	}
	else {
		$SheetData->Cells($RowToUpdate, $DBColumn++)->{Value} = $VobSpace{$VOB}{"DB"};
		$SheetData->Cells($RowToUpdate, $DBColumn++)->{Value} = $VobSpace{$VOB}{"CT"};
		$SheetData->Cells($RowToUpdate, $DBColumn++)->{Value} = $VobSpace{$VOB}{"DO"};
		$SheetData->Cells($RowToUpdate, $DBColumn++)->{Value} = $VobSpace{$VOB}{"SR"};	
		$SheetData->Cells($RowToUpdate, $DBColumn++)->{Value} = $VobSpace{$VOB}{"DB"} + $VobSpace{$VOB}{"CT"} + $VobSpace{$VOB}{"DO"} + $VobSpace{$VOB}{"SR"};
	}			
	print "VOB ".$VOB." DB : ".$VobSpace{$VOB}{"DB"}." CT : ".$VobSpace{$VOB}{"CT"}." DO : ".$VobSpace{$VOB}{"DO"}." SRC : ".$VobSpace{$VOB}{"SR"}." TOT : ".($VobSpace{$VOB}{"DB"} + $VobSpace{$VOB}{"CT"} + $VobSpace{$VOB}{"DO"} + $VobSpace{$VOB}{"SR"})."\n";
}

$BookData->save();
$ExcelData->Workbooks->Close("c:\\temp\\VobSpaceStats.xls");
$ExcelData->Quit();

