for ($Counter = 1; $Counter < 201;$Counter++)
{
	$ViewTag = sprintf("view_%03d", $Counter);

	$ViewLocation = "\/opt\/store\/views\/".$ViewTag;

	print $ViewTag."  ".$ViewLocation."\n";

	$CTMkViewCmd = "cleartool mkview -tag ".$ViewTag." ".$ViewLocation;

	print `$CTMkViewCmd`;
}
