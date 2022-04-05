use CQPerlExt;

$AdminSession = CQAdminSession::Build();

$AdminSession->Logon("admin", "", "");

$Schemas = $AdminSession->GetSchemas();

for ($Counter = 0; $Counter < $Schemas->Count(); $Counter++)
{
	print $Schemas->Item($Counter)->GetName."\n";

	$ExportCommand = "cqload exportschema admin \"\" ".$Schemas->Item($Counter)->GetName." ".$Schemas->Item($Counter)->GetName."\.schema";

	print $ExportCommand."\n";
	`$ExportCommand`;

}

