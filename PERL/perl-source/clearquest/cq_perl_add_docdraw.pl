
# Add a new docdraw.

use CQPerlExt;
$Start = @ARGV[0];
$End = @ARGV[1];

sub ReadDefinitionFile;

$session = CQSession::Build();
$session->UserLogon("admin", "", "cog", "2003.06.00");

ReadDefinitionFile("c:\\data\\customer_work\\cogent\\import_docdraw.csv");

@DataArray = split("\n", $DefinitionData);


foreach $Line (@DataArray)
{
    $EntityObject = $session->BuildEntity("DocDrawPart");

	@LineParts = split("\,", $Line);

	$Type = $LineParts[0];
	$Number = $LineParts[1];
	$Issue = $LineParts[2];
	$Original_ORNumber = $LineParts[3];
	$Description = $LineParts[4];		

	$Type =~ s/\"//g;
	$Number =~ s/\"//g; 
	$Issue =~ s/\"//g; 
	$Original_ORNumber =~ s/\"//g;
	$Description =~ s/\"//g;

    $EntityObject->SetFieldValue("Type", $Type);
    $EntityObject->SetFieldValue("Number", $Number);
    $EntityObject->SetFieldValue("Issue", $Issue);
    $EntityObject->SetFieldValue("Original_ORNumber", $Original_ORNumber);
    $EntityObject->SetFieldValue("Description", $Description);

    $ValidationResult = $EntityObject->Validate();

	$ValidationResult = "";

    if (length($ValidationResult) != 0)
    {
        print $ValidationResult."\n";
    }
    else
    {
        $EntityObject->Commit();
    }
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

