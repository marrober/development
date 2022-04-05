$InputFile = $ARGV[0];

open InputFileHandle, $InputFile;

while (eof(InputFileHandle) == 0)
{
    read InputFileHandle, $DataFromFile, 25;
    $InputData = join('',$InputData, $DataFromFile);
}

close InputFileHandle;

@InputArray = split("\n", $InputData);

foreach $_ (@InputArray)
{
	if (m/CLASS/)
	{
		$SubStr = substr($_, 48);

		@ReqData = split(" ", $SubStr);

		$Label = @ReqData[0];

		$Comment = substr($SubStr, length($Label) + 1);

		$Comment =~ s/\"//g;

		if (length($Comment) eq 0)
		{
			$CleartoolCommand = "cleartool mklbtype -nc ".$Label;
		}
		else
		{
			$CleartoolCommand = "cleartool mklbtype -c \"".$Comment."\" ".$Label;
		}

		print `$CleartoolCommand`;

	}
}
