$FileName = "c:\\temp\\large_user_import.txt";
$BufferSize = 1;
# Validate the file exists first 

if (-e $FileName) {
	open FILE_HANDLE, $FileName;
	$StartTime = time;
	$BuffersUsed = 0;
	$FileData = "";
	while (read(FILE_HANDLE, $ReadBuffer, ($BufferSize * 1024))) {
		$FileData .= $ReadBuffer;
		$BuffersUsed++;
	}
	$EndTime = time;
	print $EndTime - $StartTime." :: ".$BuffersUsed."\n";
	close FILE_HANDLE;
}