use CQPerlExt;
$SessionObj = CQSession::Build();
$SessionObj->UserLogon("admin","","CLSIC","2003.06.00");
$Record= $SessionObj->GetEntity( "defect", "CLSIC00000089");

srand(time);

$RandomNum = rand() * 100000;
$RandomNum = substr($RandomNum, 0, index($RandomNum, "."));
$FileName = ">c:\\temp\\" . $RandomNum . "_CLSIC00000089_Headline";
$Headline = $Record->GetFieldValue("Headline")->GetValue()."\n";
open $FH, $FileName;
print $FH $Headline;
close $FH;
print ".";
$FileName = ">c:\\temp\\" . $RandomNum . "_CLSIC00000089_Severity";
$Severity = $Record->GetFieldValue("Severity")->GetValue()."\n";
open $FH, $FileName;
print $FH $Severity;
close $FH;
print ".";
$FileName = ">c:\\temp\\" . $RandomNum . "_CLSIC00000089_Description";
$Description = $Record->GetFieldValue("Description")->GetValue()."\n";
open $FH, $FileName;
print $FH $Description;
close $FH;
print ".";
$AttachFields = $Record->GetAttachmentFields();

for ($AttachmentFieldCounter = 0; $AttachmentFieldCounter < $AttachFields->Count(); $AttachmentFieldCounter++)
{
	$AttachField = $AttachFields->Item($AttachmentFieldCounter);

	if ($AttachField->GetFieldName() == "Attachments") 
	{
		$AttachmentsSummaryDoc = ">c:\\temp\\".$RandomNum."_CLSIC00000089_".$AttachField->GetFieldName();

		open $FH, $AttachmentsSummaryDoc;
		
		$Attachments = $AttachField->GetAttachments();
		$NumAttachments = $Attachments->Count();
		for ($AttachmentCounter = 0 ; $AttachmentCounter < $NumAttachments ; $AttachmentCounter++)
		{
			$Attachment = $Attachments->Item($AttachmentCounter);
			print $FH $Attachment->GetFileName().";".$Attachment->GetDescription()."\n";
			$LoadFileName = "c:\\temp\\".$RandomNum."_CLSIC00000089_".$Attachment->GetFileName();
			$Attachment->Load($LoadFileName);
		}
		close $FH;
	}
}
exit($RandomNum);
