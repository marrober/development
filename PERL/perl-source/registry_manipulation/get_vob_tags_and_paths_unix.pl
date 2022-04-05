$DataFile = ">".@ARGV[0];
$Region = @ARGV[1];

$HostName = `uname -n`;
$HostName =~ s/\n//g;

$VOBListCmd = "cleartool lsvob -region ".$Region;

$VobList = `$VOBListCmd`;

@VobArray = split("\n", $VobList);

foreach $VOB (@VobArray)
{
	for ($Counter = 0; $Counter < 10; $Counter++)
	{
		$VOB =~ s/  / /g;
	}

	@VOBDetails = split(" ", $VOB);

	if ((@VOBDetails[0] cmp "*") == 0)
	{
		$VOBLocation = @VOBDetails[2];
		$VOBTag = @VOBDetails[1];
	}
	else
	{
        	$VOBLocation = @VOBDetails[1];
		$VOBTag = @VOBDetails[0];
	}

	$PathRequired = substr($VOBLocation, index($VOBLocation, $HostName) + length($HostName));

	print $VOBTag." ... ".$PathRequired."\n";
    push (@CurrentVobList, $VOBTag.",".$PathRequired);

}

open DF, $DataFile;

foreach $VOB (@CurrentVobList)
{
	print DF $VOB."\n";
}

close DF;

exit(0);

