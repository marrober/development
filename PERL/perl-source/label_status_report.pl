$VOB = $ARGV[0];
$ResultFile = ">".$ARGV[1];

$Header = "<html>\n<head>\n<title>ClearCase Label Status Report</title>\n</head>\n";
$Footer = "</body>\n</html>\n";

# Get list of all labels

$GetLabelListCmd = "cleartool lstype -kind lbtype -fmt \"%Nd;%n;%[owner]p\\n\" -invob ".$VOB;
$GetLabelListResult = `$GetLabelListCmd`;

@Labels = split("\n", $GetLabelListResult);

$LabelStatusBody .= "<table border=\"1\" width=\"700\" bordercolor=\"#808080\" cellspacing=\"0\" cellpadding=\"0\" style=\"border-style: solid; border-width: 1; padding: 0\">";

$LabelStatusBody .= "<tr>\n";
$LabelStatusBody .= "<td width = \"300\">Label Name</td>\n";
$LabelStatusBody .= "<td width = \"200\">Label Status</td>\n";
$LabelStatusBody .= "<td width = \"200\">Creator</td>\n";
$LabelStatusBody .= "</tr>\n";
foreach $Label (sort NumericalSort @Labels)
{
    @LabelParts = split(";", $Label);
    if ((@LabelParts[1] ne "LATEST") && (@LabelParts[1] ne "CHECKEDOUT") && (@LabelParts[1] ne "BACKSTOP"))
    {
        $LabelName = @LabelParts[1];
        $LabelDate = @LabelParts[0];
		$LabelCreator = @LabelParts[2];

		$LabelStatusCmd = "cleartool desc -fmt \"%S[LabelStatus]a\" lbtype:".$LabelName."@".$VOB;
		$LabelStatus = `$LabelStatusCmd`;

		if (length($LabelStatus) == 0)
		{
			$LabelStatus = "Initial";
		}

		$LabelStatus =~ s/[()\"]//g;

		print $LabelName." ".$LabelStatus." ".$LabelCreator."\n";

		$LabelStatusBody .= "<tr>\n";
		$LabelStatusBody .= "<td width = \"300\">".$LabelName."</td>\n";
		$LabelStatusBody .= "<td width = \"200\">".$LabelStatus."</td>\n";
		$LabelStatusBody .= "<td width = \"200\">".$LabelCreator."</td>\n";
		$LabelStatusBody .= "</tr>\n";
	}
}

$LabelStatusBody .= "</table></font></p>\n";

open LabelFileHnd, $ResultFile."\n";
print LabelFileHnd $Header;
print LabelFileHnd $LabelStatusBody;
print LabelFileHnd $Footer;
close LabelFileHnd;

sub NumericalSort
{
    if ($a < $b) { return -1; }
    elsif ($a == $b) { return 0; }
    else { return 1; }
}

