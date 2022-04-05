open InputFileHandle, @ARGV[0];

while (eof(InputFileHandle) == 0)
{
	read InputFileHandle, $DataFromFile, 25;
	$Data = join('',$Data, $DataFromFile);

}

close InputFileHandle;

@SplitLines = split("\n", $Data);

$Max = 0;
foreach $Line (@SplitLines)
{
	if (length($Line) > $Max)
	{
		$Max = length($Line);
		print "New Max : ".$Max."\n";
	}
}





