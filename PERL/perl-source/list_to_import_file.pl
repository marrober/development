

$InputFile = $ARGV[0];
$OutputFile = $ARGV[1];

print $ARGV[0]."  ".$ARGV[1]."\n";
open InputHandle, $InputFile;

while (eof(InputHandle) == 0)
{
    read InputHandle, $DataFromFile, 1;

    $FileLineBuffer = $FileLineBuffer.$DataFromFile;
}

close InputHandle;

@LineArray = split("\n", $FileLineBuffer);

$FirstLine = shift(@LineArray);

@Headings = split("\,", $FirstLine);


foreach $Line (@LineArray)
{
	$Index = 0;
	@ItemArray = split("\,", $Line);

	$Record = {};
	$Record->{"USER"} = "";
	$Record->{"password"} = "12345";
	$Record->{"is_active"} = "TRUE";
	$Record->{"is_subscribed_to_all_dbs"} = "TRUE";
	$Record->{"email"} = "";
	$Record->{"fullname"} = "";
	$Record->{"phone"} = "";
	$Record->{"misc_info"} = "";
	$Record->{"is_superuser"} = "FALSE";
	$Record->{"is_appbuilder"} = "FALSE";
	$Record->{"is_packagehacker"} = "FALSE";
	$Record->{"is_user_maint"} = "FALSE";
	$Record->{"databases"} = "";

	foreach $Heading (@Headings)
	{	
		# print $Heading."   ".@ItemArray[$Index]."\n";
			 
		$Record->{$Heading} = @ItemArray[$Index];
		$Index++;
	}

	push @ListOfRecords, $Record;

}

$OutputFile = ">".$OutputFile;

open OutputHandle, $OutputFile;

for $Rec (@ListOfRecords)
{

	print OutputHandle "USER ".$Rec->{"USER"}."\n";
	for $_ (keys %$Rec)
	{
		if (!m/USER/)
		{
			print OutputHandle "\t$_ = ".$Rec->{$_}."\n";
		}
	}
}

close OutputHandle;
