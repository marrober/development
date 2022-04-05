#
#********************************************************************************
#** Module        : ddtscq_GetEnclosureList.pl
#** Originator    : Mark Roberts
#** Creation Date : 15th June, 2000
#**
#********************************************************************************
#

$InputFile = $ARGV[0];
$EnclosureListFile = $ARGV[1];

open InputFileHandle, $InputFile;

while (defined($DataFromFile = <InputFileHandle>))
{
	$EnclosureData = join('',$EnclosureData, $DataFromFile);
}

close InputFileHandle;

$EnclosureData =~ s/\"//g;

@SplitData = split(/\n/, $EnclosureData);


foreach $Line (@SplitData)
{
	@LineParts = split(/\\/, $Line);

	$Final = $LineParts[$#LineParts];
	
	$_ = $Final;

	if (m/\.txt/)
	{
		$_ =~ s/\.txt//;

		$Found = FALSE;

		foreach $Mls (@MultiLineStrings)
		{
			if (m/$Mls/)
			{
				$Found = TRUE;
				# print $Found."    ";
			}
		}
		if ($Found eq FALSE)
		{
			push(@MultiLineStrings, $_);
		}
		

	}
}

$EnclosureListFile = ">".$EnclosureListFile;

open OutputFile, $EnclosureListFile;

foreach $Mls (@MultiLineStrings)
{
	print OutputFile $Mls."\n";
}

close OutputFile;




