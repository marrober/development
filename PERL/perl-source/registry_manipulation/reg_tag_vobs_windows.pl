$DataFile = @ARGV[0];
$Region = @ARGV[1];

# Get the host name.
#
# $HostName = `uname -n`;
$HostName = "IBMGB-MROBER01";
$HostName =~ s/\n//g;

print "Host name : ".$HostName."\n";

open DF, $DataFile;

while (!(eof(DF)))
{
	read DF, $DataFromFileTmp, 25;

	$DataFromFile .= $DataFromFileTmp;
}

close DF;

print $DataFromFile."\n";

@Data = split("\n", $DataFromFile);

foreach $VOBToProcess (@Data)
{
	@VOBParts = split("\,", $VOBToProcess);

	$Tag = @VOBParts[0];
	$Location = @VOBParts[1];

	$CTRegCmd = "cleartool register -vob -host ".$HostName." -hpath \\\\".$HostName."\\".$Location." -gpath \\\\".$HostName."\\".$Location." \\\\".$HostName."\\".$Location;
	$CTMkTagCmd = "cleartool mktag -vob -tag ".$Tag." -region ".$Region." -public -password rational -host ".$HostName." -gpath \\\\".$HostName."\\".$Location." \\\\".$HostName."\\".$Location;

	`$CTRegCmd`;
	print ".... registered";
	`$CTMkTagCmd`;
	print ".... tagged\n";
}

exit(0);

