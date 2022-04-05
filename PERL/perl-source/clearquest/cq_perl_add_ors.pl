use CQPerlExt;

sub ReadDefinitionFile;

$session = CQSession::Build();
$session->UserLogon("admin", "", "cog", "2003.06.00");

ReadDefinitionFile("c:\\data\\customer_work\\cogent\\import_or.csv");

@DataArray = split("\n", $DefinitionData);


foreach $Line (@DataArray)
{
    $EntityObject = $session->BuildEntity("OR");

	@LineParts = split("\,", $Line);

	$RaisedBy = $LineParts[0];
	$Priority = $LineParts[1];
	$Description = $LineParts[2];
	$ORNumber = $LineParts[3];
	$PointOfEmbodimentType = $LineParts[4];
	$Identifier = $LineParts[5];

	print $RaisedBy."\n";		
	print $Priority."\n";
	print $Description."\n";
	print $ORNumber."\n";
	print $PointOfEmbodimentType."\n";
	print $Identifier."\n";

    $EntityObject->SetFieldValue("RaisedBy", $RaisedBy);
    $EntityObject->SetFieldValue("Priority", $Priority);
    $EntityObject->SetFieldValue("Description", $Description); 
    $EntityObject->SetFieldValue("PointOfEmbodimentType", $PointOfEmbodimentType);
    $EntityObject->SetFieldValue("Identifier", $Identifier);
	$EntityObject->SetFieldValue("ORNumber", $ORNumber);

    $ValidationResult = $EntityObject->Validate();

    if (length($ValidationResult) != 0)
    {
        print $ValidationResult."\n";
    }
    else
    {
        $EntityObject->Commit();
    }
	print ".";
}

# This is necessary for a clean shutdown otherwise you get an error.
CQSession::Unbuild($session);


sub ReadDefinitionFile
{
    my $FileName = shift;

    open InputFileHandle, $FileName;

    while (eof(InputFileHandle) == 0)
    {
        read InputFileHandle, $DataFromFile, 25;
        $DefinitionData = join('',$DefinitionData, $DataFromFile);
    }

    close InputFileHandle;
}

