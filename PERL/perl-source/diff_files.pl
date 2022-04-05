$WildCard = @ARGV[0];
$Label1 = @ARGV[1];
$Label2 = @ARGV[2];

print $WildCard."\n";
print $Label1."\n";
print $Label2."\n";

if ($WildCard eq "-")
{
	$WildCard = "*.*";
}

$CleartoolFindCmd = "cleartool find . -name ".$WildCard." -nxname -ver \"lbtype(".$Label1.")&&!lbtype(".$Label2.")\" -print";
print $CleartoolFindCmd."\n";
$FilesThatDiffer = `$CleartoolFindCmd`;

@FilesThatDifferArray = split("\n", $FilesThatDiffer);

foreach $File (@FilesThatDifferArray)
{
	print $File."\n";
	$DiffCommand = "cleartool diff -g ".$File."@@\\".$Label1." ".$File."@@\\".$Label2;
	`$DiffCommand`;
}



