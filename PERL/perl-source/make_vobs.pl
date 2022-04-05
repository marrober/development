for ($Counter = 11; $Counter < 201;$Counter++)
{
	$VOBTag = sprintf("\/vobs\/test_vob_%03d", $Counter);

	$VOBLocation = "\/opt\/store".$VOBTag;

	print $VOBTag."  ".$VOBLocation."\n";

	$CTMkVOBCmd = "cleartool mkvob -tag ".$VOBTag." -public -password rational -nc ".$VOBLocation;

	print `$CTMkVOBCmd`;
}
