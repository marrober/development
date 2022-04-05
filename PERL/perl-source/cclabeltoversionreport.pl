$VOB = $ARGV[0];
$ResultFile = ">".$ARGV[1];

if (index($ResultFile, "\\") > 0)
{
	$ResultPath = substr($ResultFile, 0, rindex($ResultFile, "\\"));
	print $ResultPath."\n";
}


`cleartool startview default`;

$Header = "<html>\n<head>\n<title>ClearCase Label to Version Report</title>\n</head>\n";
$Footer = "</body>\n</html>\n";

# Get list of all labels

$GetLabelListCmd = "cleartool lstype -kind lbtype -fmt \"%n %[owner]p %Sd\\n\" -invob ".$VOB;
$GetLabelListResult = `$GetLabelListCmd`;

@Labels = split("\n", $GetLabelListResult);

$IndexBody = "<body><h2>Labels in the VOB : ".$VOB."</h2><p>\n";

foreach $LabelData (@Labels)
{
	@LabelInformation = split(" ", $LabelData);
	$Label = @LabelInformation[0];
	print $Label."\n";
	$Creator = @LabelInformation[1];
	$CreationDate = @LabelInformation[2];

	if (($Label ne "LATEST") && ($Label ne "CHECKEDOUT") && ($Label ne "BACKSTOP"))
	{
		$IndexBody .= "<a href=\"".$Label.".html\">".$Label."</a><br>";
		$LabelResultFile = $ResultPath."\\".$Label.".html";
		$LabelFileBody = "<h2>".$Label."</h2>\n";
		$LabelFileBody .= "<h3><i>Created on ".$CreationDate." by ".$Creator."</i></h3>\n";
		
		print "Label : ".$Label."\n";
		print "Created on : ".$CreationDate." by ".$Creator."\n";

		$FindCmd = "cleartool find m:\\default".$VOB." -version {lbtype(".$Label.")} -print";
		$FindResult = `$FindCmd`;

		@VersionList = split("\n", $FindResult);

		$LabelFileBody .= "<table border=\"1\" width=\"800\" bordercolor=\"#808080\" cellspacing=\"0\" cellpadding=\"0\" style=\"border-style: solid; border-width: 1; padding: 0\">";

		foreach $Version (@VersionList)
		{
			$_ = $Version;

			if (!m/lost\+found/)
			{
				$Version = substr($Version, 10);

				# Get final version number, branch and file name

				$VersionNumber = substr($Version, rindex($Version, "\\") + 1);
				$Name = substr($Version, 0, index($Version, "\@\@"));
				$Branch = substr($Version, length($Name) + 2, length($Version) - length($Name) - length($VersionNumber) - 3);

				$LabelFileBody .= "<tr>\n";
				$LabelFileBody .= "<td width = \"650\">".$Name."</td>\n";
				$LabelFileBody .= "<td width = \"170\">".$Branch."</td>\n";
				$LabelFileBody .= "<td width = \"55\">".$VersionNumber."</td>\n";
				$LabelFileBody .= "</tr>\n";
			}
		}
		$LabelFileBody .= "</table></font></p>\n";

		open LabelFileHnd, $LabelResultFile."\n";
		print LabelFileHnd $Header;
		print LabelFileHnd $LabelFileBody;
		print LabelFileHnd $Footer;
		close LabelFileHnd;
	}
}

open ResultFileHnd, $ResultFile;
print ResultFileHnd $Header;
print ResultFileHnd $IndexBody;
print ResultFileHnd $Footer;
close ResultFileHnd;

