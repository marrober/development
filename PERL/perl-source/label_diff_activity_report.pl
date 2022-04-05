use CQPerlExt;

$session = CQSession::Build();
$session->UserLogon("admin", "", "CLSIC", "");

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

$GetLabelListCmd = "cleartool lstype -kind lbtype -fmt \"%Nd;%n\\n\" -invob ".$VOB;
$GetLabelListResult = `$GetLabelListCmd`;

@Labels = split("\n", $GetLabelListResult);

$PreviousDate = "2001-01-01 00:00:01";

$qryDef = $session->BuildQuery("Defect");
$qryDef->BuildField("id");
$qryDef->BuildField("headline");
$qryDef->BuildField("state");
$qryDef->BuildField("record_type");

foreach $Label (sort NumericalSort @Labels)
{
    @LabelParts = split(";", $Label);
    if ((@LabelParts[1] ne "LATEST") && (@LabelParts[1] ne "CHECKEDOUT") && (@LabelParts[1] ne "BACKSTOP"))
    {
        $LabelName = @LabelParts[1];
        $LabelDate = @LabelParts[0];

        print $LabelName.".....".$LabelDate."\n";

        @DateTimeParts = split(/\./, $LabelDate);

        $Year = substr(@DateTimeParts[0], 0, 4);
        $Month = substr(@DateTimeParts[0], 4, 2);
        $Day = substr(@DateTimeParts[0], 6, 2);

        $Hours = substr(@DateTimeParts[1], 0, 2);
        $Minutes = substr(@DateTimeParts[1], 2, 2);
        $Seconds = substr(@DateTimeParts[1], 4, 2);

        $RequiredDate = $Year."-".$Month."-".$Day." ".$Hours.":".$Minutes.":".$Seconds;

        push (@DateRange, $PreviousDate);
        push (@DateRange, $RequiredDate);

        print "From : ".@DateRange[0]." to ".@DateRange[1]."\n";

        my $Filter = $qryDef->BuildFilterOperator($CQPerlExt::CQ_BOOL_OP_AND);

        $Filter->BuildFilter("Submit_Date", $CQPerlExt::CQ_COMP_OP_BETWEEN, \@DateRange);

        $resultSet = $session->BuildResultSet($qryDef);
        $resultSet->Execute();
        $status = $resultSet->MoveNext();
        $Counter = 0;
        while ($status == $CQPerlExt::CQ_SUCCESS)
        {
            print substr($resultSet->GetColumnValue(1), 10, 3) ." ";
            $status = $resultSet->MoveNext();
        }
        print "\n";
        pop (@DateRange);
        pop (@DateRange);
        $PreviousDate = $RequiredDate;
    }
}

CQSession::Unbuild($session);


sub NumericalSort
{
    if ($a < $b) { return -1; }
    elsif ($a == $b) { return 0; }
    else { return 1; }
}
