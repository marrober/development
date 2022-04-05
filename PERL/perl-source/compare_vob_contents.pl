use Win32::OLE;

$ViewDrive = @ARGV[0];
$VOBA = @ARGV[1];
$VOBB = @ARGV[2];

print $VOBA."   ".$VOBB."\n";

my $ct = Win32::OLE->new('ClearCase.ClearTool');
my $cc = Win32::OLE->new('ClearCase.Application');

$VOBAListingCmd = "dir /s/b ".$ViewDrive."\\".$VOBA;
$VOBAListingResult = `$VOBAListingCmd`;

@VOBAContent = split("\n", $VOBAListingResult);

foreach $VOBAItem (@VOBAContent)
{
	$CTDescResult = $ct->CmdExec("describe ".$VOBAItem);

	@DescParts = split("\n", $CTDescResult);

	$_ = @DescParts[0];

	if ((!m/View private/) && (!m/directory version/))
	{

		$_ = $VOBAItem;

		if (!m/lost\+found/)
		{

			$VOBBItem = $VOBAItem;
			$VOBBItem =~ s/$VOBA/$VOBB/g;

			$VOBAVersionReport = $ct->CmdExec("lsvtree -all \"".$VOBAItem."\"");
			$VOBBVersionReport = $ct->CmdExec("lsvtree -all \"".$VOBBItem."\"");

			$VOBBVersionReport =~ s/$VOBB/$VOBA/g;


			if (length($VOBBVersionReport) == 0)
			{
				print "File not found in VOB (".$VOBB.") : ".$VOBBItem."\n";
			}
			else
			{
				if (($VOBAVersionReport cmp $VOBBVersionReport) != 0)
				{
					$_ = $VOBAVersionReport;
					$ErrorMsg = "";

					if (m/CHECKEDOUT/)
					{
						$ErrorMsg = "File is checked out in VOB : ".$VOBA."\n";
					}
					$_ = $VOBBVersionReport;

					if (m/CHECKEDOUT/)
					{
						$ErrorMsg = "File is checked out in VOB : ".$VOBB."\n";
					}


					print "ERROR : ".$VOBAItem."\n";
					if (length($ErrorMsg) > 0)
					{
						print $ErrorMsg;
					}
					else
					{
						$VOBBVersionReport =~ s/$VOBA/$VOBB/g;
						print "--2--\n".$VOBAVersionReport."\n";
						print "--3--".$VOBBVersionReport."\n";
					}
				}
			}
		}
	}
}



