sub ReadDefinitionFile;


$InputFile = @ARGV[0];
$OutputFile = ">".@ARGV[1];


ReadDefinitionFile($InputFile);

@SplitData = split("\n", $DefinitionData);

$Counter = 0;

foreach $SplitItem (@SplitData)
{
	#print "-------".$SplitItem."\n";

	@SplitLine = split("\,", $SplitItem);

	if ($SplitLine[0] == "0")
	{

		$SplitLine[1] =~ s/\"//g;
		$SplitLine[2] =~ s/\"//g;
		$SplitLine[2] = substr($SplitLine[2], 0, 10);
		$SplitLine[3] =~ s/\"//g;
		$SplitLine[3] = substr($SplitLine[2], 0, 10);
		$SplitLine[4] =~ s/\"//g;
		$SplitLine[5] =~ s/\"//g;
		$SplitLine[6] =~ s/\"//g;
		push @CalendarData, $SplitLine[2]."##".$SplitLine[3]."##".substr($SplitLine[4],0,60)."##".$SplitLine[5]."##".$SplitLine[6];
	}

	

}

open OUTPUTFILE, $OutputFile;


foreach $Entry (sort @CalendarData)
{

	@SplitLine = split("##", $Entry);
	
	@StartDateSplit = split("-", @SplitLine[0]);

	@EndDateSplit = split("-", @SplitLine[1]);

	print OUTPUTFILE @StartDateSplit[2]."-".@StartDateSplit[1]."-".@StartDateSplit[0].",".@EndDateSplit[2]."-".@EndDateSplit[1]."-".@EndDateSplit[0].",".@SplitLine[2].",".@SplitLine[3].",".@SplitLine[4]."\n";


}

close OUTPUTFILE;


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



