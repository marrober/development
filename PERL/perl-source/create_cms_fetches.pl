$InputFile = $ARGV[0];
$CMSCommandFile = $ARGV[1];
$ClearFile = $ARGV[2];
$BranchName = $ARGV[3];

open InputFileHandle, $InputFile;

while (eof(InputFileHandle) == 0)
{
    read InputFileHandle, $DataFromFile, 25;
    $InputData = join('',$InputData, $DataFromFile);
}

close InputFileHandle;

@InputArray = split("\n", $InputData);

$DirCount = 0;

foreach $_ (@InputArray)
{
	if (m/CLASS/)
	{
		$Index = index($_, "CLASS");

		$SubStr = substr($_, $Index + 6);

		@ReqData = split(" ", $SubStr);

		$Label = @ReqData[0];

		$_ = $Label;

		if (!m/DEU/)
		{
		
			$CMSCommandBuffer .= "\$cre/dir [.DIR".$DirCount."]\n";
			$CMSCommandBuffer .= "\$set def [.DIR".$DirCount."]\n";
			$CMSCommandBuffer .= "\$cms fetch *.* /occ=none /gen=".$Label." \"\"\n"; 
			$CMSCommandBuffer .= "\$set def [-]\n";
	
			$CCCommandBuffer .= "cd DIR".$DirCount."\n";

			if (length($BranchName) > 0)
			{
				$CCCommandBuffer .= "clearexport_ffile -b ".$BranchName." -l ".$Label."\n";
			}
			else
			{
				$CCCommandBuffer .= "clearexport_ffile -l ".$Label."\n";
			}

			$CCCommandBuffer .= "cd ..\nz:\n";
			$CCCommandBuffer .= "clearimport j:\\DIR".$DirCount."\\cvt_data\nj:\n";

			$DirCount++;
		}	

	}

}

$CMSCommandFile = ">".$CMSCommandFile;

open CMSCommandFileHandle, $CMSCommandFile;

print CMSCommandFileHandle $CMSCommandBuffer;

close CMSCommandFileHandle;

$ClearFile = ">".$ClearFile;

open ClearFileHandle, $ClearFile;

print ClearFileHandle $CCCommandBuffer;

close ClearFileHandle;



