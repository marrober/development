$Region = @ARGV[0];

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
		$VOBTag = @VOBDetails[1];
		$VOBLocation = @VOBDetails[2];
		$UmountCmd = "cleartool umount ".$VOBTag;
	}
	else
	{
        $VOBTag = @VOBDetails[0];
		$VOBLocation = @VOBDetails[1];
	}
    $_ = $VOBTag;
    if (m/2/)
    {
        print $VOBTag."\n";
        $UnregCmd = "cleartool unregister -vob ".$VOBLocation;
        $RMTagCmd = "cleartool rmtag -vob -region ".$Region." -password rational ".$VOBTag;

        `$UnregCmd`."\n";
        `$RMTagCmd`."\n";
    }

}

exit(0);
