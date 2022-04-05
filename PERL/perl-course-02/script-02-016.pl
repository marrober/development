
# Add a new defect record.

use CQPerlExt;
$Start = @ARGV[0];
$End = @ARGV[1];

$session = CQSession::Build();
$session->UserLogon("admin", "rational", "CLSIC", "2003.06.00");

$DisplayCounter = 0;
for ($Counter = $Start; $Counter <= $End; $Counter++)
{
    print "*";
    if (++$DisplayCounter > 50)
    {
        print $Counter."\n";
        $DisplayCounter = 0;
    }

    $EntityObject = $session->BuildEntity("Defect");

    @DateTime = gmtime(time);

    $DateAndTime = @DateTime[3]."/".(@DateTime[4] + 1)."/".(@DateTime[5] + 1900)." ".(@DateTime[2] + 1).":".@DateTime[1].":".@DateTime[0];

    $SystemName = sprintf("System %06d", $Counter);

    $EntityObject->SetFieldValue("Headline", $SystemName);
    $EntityObject->SetFieldValue("Description", "This is a description for the system.");
    $EntityObject->SetFieldValue("Severity", "1-Critical");


    $ValidationResult = $EntityObject->Validate();

    if (length($ValidationResult) != 0)
    {
        print $ValidationResult."\n";
    }
    else
    {
        $EntityObject->Commit();
    }
}

# This is necessary for a clean shutdown otherwise you get an error.
CQSession::Unbuild($session);