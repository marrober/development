$DataFile = @ARGV[0];
$UnregisterFile = ">".@ARGV[1];

open FH, $DataFile;
while (!eof(FH))
{
    read FH, $DataFromFile, 100;
    $RgyData .= $DataFromFile;
}

close FH;

$RgyData =~ s/\n\n/\n/g;

@RgyData = split("\n", $RgyData);
$RgyCounter = 0;

$StrandedFound = 0;

foreach $_ (@RgyData)
{
    if (m/stranded/)
    {
        $StrandedFound = 1;
    }

    if ((m/view_uuid/) && ($StrandedFound == 1))
    {
        $UUIDLine = $_;

        $LeftQuote = index($UUIDLine, "\"");
        $UUID = substr($UUIDLine, $LeftQuote + 1, length($UUIDLine) - $LeftQuote - 2);

        $RmViewCmd .= "cleartool rmview -force -all -uuid ".$UUID."\n";

        $UnregisterCmd .= "cleartool unregister -view -uuid ".$UUID."\n";

        $StrandedFound = 0;
        $StrandedCounter++;

    }
}
print $StrandedCounter."\n";

open FH, $UnregisterFile;
print FH $RmViewCmd;
print FH $UnregisterCmd;
close FH;
