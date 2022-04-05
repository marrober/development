sub ReadDefinitionFile;

$InputFile = @ARGV[0];

ReadDefinitionFile($InputFile);

@SplitData = split("\n", $DefinitionData);

$Counter = 0;

foreach $SplitItem (@SplitData)
{
	
	$_ = $SplitItem;

	if (m/VERSION_BEGIN/)
	{
		$Counter++;
	}
}

print $Counter."\n";


sub ReadDefinitionFile
{
    my $FileName = shift;

    $FileName =~ s|/D=||;

    open InputFileHandle, $FileName;

    while (eof(InputFileHandle) == 0)
    {
        read InputFileHandle, $DataFromFile, 25;
        $DefinitionData = join('',$DefinitionData, $DataFromFile);
    }

    close InputFileHandle;
}



