# Perl script to manage the version control process for ReqPro files.
# This script will do the following :
#
# 1. Checkin all VOB resident files that are checked out to the shared snapshot view.
# 2. Checkout all VOB resident files so that they can be modified through the snapshot view.
# 3. Create new VOB resident files for ReqPro files that are view private (add to source control).
# 4. Checkout the new VOB resident files.
#
#
# Read the parameter file.
#
$ParameterFile = $ARGV[0];

open InputFileHandle, $ParameterFile;

while (eof(InputFileHandle) == 0)
{
    read InputFileHandle, $DataFromFile, 25;
    $InputData = join('',$InputData, $DataFromFile);
}

close InputFileHandle;

@Parameters = split("\n", $InputData);

$Directory = @Parameters[0];

print $Directory."\n";

@Extensions = split(" ", @Parameters[1]);

$VobResidentFileList = `cleartool ls -vob_only $Directory`;

@VobResidentFiles = split("\n", $VobResidentFileList);

foreach $_ (@VobResidentFiles)
{
	if (m/@@/)
	{
		# The file contains @@ [eclipsed by checkout] after the name.

		$VobFile = substr($_, 0, index($_, "@@"));
	}
	else
	{
		$VobFile = $_;
	}

	$CheckinResult = `cleartool ci -nc $VobFile`;
	$CheckoutResult = `cleartool co -nc $VobFile`;
	print $CheckinResult."\n".$CheckoutResult."\n";

}

$ViewResidentFileList = `cleartool ls -view_only $Directory`;

@ViewResidentFiles = split("\n", $ViewResidentFileList);

$AddFiles = FALSE;

foreach $ViewFile (@ViewResidentFiles)
{
	# Ignore the listed checkedout files. 

	$_ = $ViewFile;

	if (!m/@@/)
	{
		print $_;

		# Get file extension.
	
		if (index($_, ".") >= 0)
		{
			$FileExtension = substr($_, rindex($_, ".") + 1);
			print "   ".$FileExtension."\n";

			$AddThisFile = FALSE;
			foreach $Ext (@Extensions)
			{
				if ($Ext eq $FileExtension)
				{
					$AddFiles = TRUE;
					$AddThisFile = TRUE;
					push (@FilesToAdd, $ViewFile);
				}
			}
			if ($AddThisFile eq FALSE)
			{
				print "Not adding view private file : ".$ViewFile."\n";
			}
		}
	}
}

if ($AddFiles eq TRUE)
{
	# Checkout the parent directory.

	$ParentCheckoutResult = `cleartool co -nc $Directory`;

	print $ParentCheckoutResult."\n";

	foreach $FileToAdd (@FilesToAdd)
	{
		print $FileToAdd."\n";

		$MkElemResult = `cleartool mkelem -eltype ms_word -ci -nc $FileToAdd`;

		print $MkElemResult."\n";

		$CheckoutResult = `cleartool co -nc $FileToAdd`;
		
		print $CheckoutResult."\n";
	}

	# Checkin the parent directory.

	$ParentCheckinResult = `cleartool ci -nc $Directory`;

	print $ParentCheckinResult."\n";
}
else
{
	print "NO FILES TO ADD...\n";
}
