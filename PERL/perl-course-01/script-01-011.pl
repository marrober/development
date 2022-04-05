$FileName = "c:\\temp\\small_user_import.txt";
# Validate the file exists first 
if (-e $FileName) {
	open FILE_HANDLE, $FileName;
	while (read(FILE_HANDLE, $ReadBuffer, 5)) {
		$FileData = $FileData.$ReadBuffer;
	}
	print $FileData."\n";
	close FILE_HANDLE;
}