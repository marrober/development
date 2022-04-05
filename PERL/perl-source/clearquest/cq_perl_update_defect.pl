
# Add a new defect record.

use CQPerlExt;

$session = CQSession::Build();
$session->UserLogon("admin", "rebecca1", "", "");

# You really should use a query for the defect that you want to update , but I cannot get
# the filtering to work now... Maybe later after I surf for technotes tomorrow.

$EntityObject = $session->GetEntity("Defect", "SAMPL00000568");

# Get the date and time - just to make the headlines differ.

@DateTime = gmtime(time);

$DateAndTime = @DateTime[3]."/".(@DateTime[4] + 1)."/".(@DateTime[5] + 1900)." ".(@DateTime[2] + 1).":".@DateTime[1].":".@DateTime[0];

# Besides modify you can use a state change.

$session->EditEntity($EntityObject, "Modify");

$EntityObject->SetFieldValue("note_entry", "This is an additional note at ". $DateAndTime);

$ValidationResult = $EntityObject->Validate();

if (length($ValidationResult) != 0)
{
	print $ValidationResult."\n";
}
else
{
	$EntityObject->Commit();
}

# This is necessary for a clean shutdown otherwise you get an error.
CQSession::Unbuild($session);

