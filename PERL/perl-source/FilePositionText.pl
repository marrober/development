#

$BSlash = chr(92);
sub ReadDefinitionFile;

my $FileName = $ARGV[0];
my $FileLocationInterested = $ARGV[1];

open InputFileHandle, $FileName;
while (eof(InputFileHandle) == 0)
{
	read InputFileHandle, $DataFromFile, 25;
	$CQSchemaData = join('',$CQSchemaData, $DataFromFile);
}

close InputFileHandle;

@FileContent = split("\n", $CQSchemaData);
$TotalLength = 0;
$printed = 5;
foreach $_ (@FileContent) {
	$LineLength = length($_);
	$TotalLength += $LineLength;
	
	if (($TotalLength > $FileLocationInterested) && ($printed-- > 0)) {
		print $TotalLength."  ".$_."\n";
	}
}




