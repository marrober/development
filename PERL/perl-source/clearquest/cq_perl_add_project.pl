
# Add a new defect record.

use CQPerlExt;

# Get the date and time - just to make the headlines differ.

@DateTime = gmtime(time);

$DateAndTime = @DateTime[3]."/".(@DateTime[4] + 1)."/".(@DateTime[5] + 1900)." ".(@DateTime[2] + 1).":".@DateTime[1].":".@DateTime[0];

$session = CQSession::Build();
$session->UserLogon("admin", "", "SAMPL", "");

$EntityObject = $session->BuildEntity("Project");

$EntityObject->SetFieldValue("name", "This is a project created on ". $DateAndTime);
$EntityObject->SetFieldValue("Description", "This is a description for the project.");

# If you do not supply values for all mandatory fields then you get a validation error returned below.

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

