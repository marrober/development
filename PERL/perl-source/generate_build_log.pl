
# Add a new defect record.

use CQPerlExt;

$session = CQSession::Build();
$session->UserLogon("auto_build", "auto_build", "cqdb", "");

$EntityObject = $session->BuildEntity("BuildLog");

$EntityObject->SetFieldValue("BaselineRef", $ARGV[0]);

$EntityObject->SetFieldValue("Status", $ARGV[1]);

$BRFileName = $ARGV[2];
open BuildResult, $BRFileName;
	
while (eof(BuildResult) == 0)
{
	read BuildResult, $DataFromFile, 25;
	$BuildData = join('',$BuildData, $DataFromFile);
}
	
close BuildResult; 

if (length($ARGV[3]) > 0)
{
	$CRFileName = $ARGV[3];
	open ConfigRecord, $CRFileName;
	
	while (eof(ConfigRecord) == 0)
	{
		read ConfigRecord, $DataFromFile, 25;
		$CRData = join('',$CRData, $DataFromFile);
	}
	
	close ConfigRecord;
 
	@SplitData = split("\n", $CRData);
	foreach $Line (@SplitData)
	{
		$Line =~ s/\r//g;

		$_ = $Line;

		if (m/^\\library/)
		{
			$_ = substr($_, 0, index($_, " <"));

			$DescLibCmd = "cleartool desc m:\\auto_build".$_;
			$DescResult = `$DescLibCmd`;
			@DescResultLines = split("\n", $DescResult);
	
			foreach $DescResultLine (@DescResultLines)
			{
				$_ = $DescResultLine;
				if (m/Merge <-/)
				{
					$MergeFromVer = substr($DescResultLine, index($DescResultLine, "<- ") + 3);
					$DescLibCmd = "cleartool desc -fmt \"%S[VersionID]a\" ".$MergeFromVer;
					$DescResult = `$DescLibCmd`;
					$DescResult =~ s/[\(\)\"]//g;

					if (length($DescResult) == 0)
					{
						$Line .= " [Version ID not found]";
					}
					else
					{
						$Line .= " [".$DescResult."]";
					} 
					print $Line."\n";	
				}
			}
		}
		$CRLogData = $CRLogData.$Line."\r\n";
	}
}
else
{	
	$CRLogData = "Build Failed\r\nConfiguration record was not generated\r\n";
}

@SplitData = split("\n", $BuildData);
foreach $Line (@SplitData)
{
	$Line =~ s/\r//g;
	$BRLogData = $BRLogData.$Line."\r\n";
}


$EntityObject->SetFieldValue("log", $BRLogData);
$EntityObject->SetFieldValue("ConfigurationRecord", $CRLogData);

$ValidationResult = $EntityObject->Validate();

if (length($ValidationResult) != 0)
{
	print $ValidationResult."\n";
}
else
{
	$EntityObject->Commit();
}

# This is necessary for a clean shutdown otherwise you get an error.
CQSession::Unbuild($session);

