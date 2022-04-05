$FileName = "c:\\temp\\cc_label_data.txt";

if (-e $FileName) {
	open FILE_HANDLE, $FileName;
	$FileData = "";
	while (read(FILE_HANDLE, $ReadBuffer, 1024)) {
		$FileData = $FileData.$ReadBuffer;
	}
	close FILE_HANDLE;
	
	@LinesOfData = split("\n", $FileData);
	
	foreach $Line (@LinesOfData) {
		@LineSegments = split("\,", $Line);
		
		if ($LineSegments[2] ne "vobadm") {
			push(@MrLabels, $LineSegments[0]);
		}
	}
}

foreach $Label (@MrLabels) {
	print "Label : ".$Label." was NOT created by Vob Admin\n";	
}

