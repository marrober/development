$ViewList = `cleartool lsview`;

@ViewArray = split("\n", $ViewList);

foreach $View (@ViewArray)
{
	for ($c = 0; $c < 10; $c++)
	{
		$View =~ s/  / /g;
	}

	@ViewLine = split(" ", $View);

	$_ = @ViewLine[0];
	
	if (m/\*/)
	{
		print "Active view : ".@ViewLine[1]."\n";

		$EndViewCmd = "cleartool endview -server ".@ViewLine[1];
		print `$EndViewCmd`;
	}
}

$NetViewList = `net use`;

@NetViewArray = split("\n", $NetViewList);

foreach $NV (@NetViewArray)
{
	for ($c = 0; $c < 10; $c++)
	{
		$NV =~ s/  / /g;
	}	

	@NVLine = split(" ", $NV);

	if ((@NVLine[0] cmp "Unavailable") == 0)
	{
		$NetUseDel = "net use ".@NVLine[1]." /d";
		print `$NetUseDel`;
	}
}


print `cleartool umount -all`;
