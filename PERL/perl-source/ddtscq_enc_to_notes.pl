$DefectFile = $ARGV[0];
$NewDefectFile = $ARGV[1];
$EnclosurePath = $ARGV[2];
$NewField = $ARGV[3];

open DefectFileHandle, $DefectFile;

while (defined($DataFromFile = <DefectFileHandle>))
{
    $DefectData = join('',$DefectData, lc($DataFromFile));
}

close DefectFileHandle;

@DefectLines = split("\n", $DefectData);

$FirstLine = shift(@DefectLines);

$FirstLine .= ",\"".$NewField."\"";

print $FirstLine."\n";

$Counter = 0;

$NewDefectFile = ">".$NewDefectFile;

open NewDefectFileHandle, $NewDefectFile;

print NewDefectFileHandle $FirstLine."\n";

foreach $DefectLine (@DefectLines)
{
	@DefectParts = split(",", $DefectLine);

	# Get the enclosures for each defect.
	#

	$_ = @DefectParts[0];

	s/\"//g;

	$EnclosurePathForDefect = $EnclosurePath."\\".substr($_, length($_) - 2)."\\".$_;

	$FileListCommand = "dir ".$EnclosurePathForDefect." /b";

	$FileList = `$FileListCommand`;

	if (!($FileList eq "File Not Found"))
	{

		@FileListArray = split("\n", $FileList);

		# Get final file name.

		foreach $File (@FileListArray)
		{
			$FullName = $EnclosurePathForDefect."\\".$File;

			$EnclosureName = $File;

			$EnclosureName =~ s/\.txt//g;	

			open EncFileHandle, $FullName;

			while (defined($DataFromFile = <EncFileHandle>))
			{
			    $EncData = join('',$EncData, $DataFromFile);
			}

			$EncData =~ s/\"/\"\"/g;

			close EncFileHandle;	

			$EncBlock .= "-----------------------------------\n".$EnclosureName.":\n".$EncData."\n";
			$EncData = "";
		}

#		print $EncBlock;	
	}	

	$DefectLine .= ",\"".$EncBlock."\"";

	print NewDefectFileHandle $DefectLine."\n";

	$EncBlock = "";

	$Counter = $Counter + 1;

	print " .... done .... ".$Counter."\n";
}
