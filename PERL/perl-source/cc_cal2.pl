use Win32::OLE;
my $cc = Win32::OLE->new('ClearCase.Application');
my $ElementObj = $cc->Element($ARGV[0]);
print "Element owner : ". $ElementObj->Owner."\n";
my $TriggerList = $ElementObj->Triggers;
for ($Ctr = 1; $Ctr <= $TriggerList->Count; $Ctr = $Ctr + 1)
{	
	my $TriggerObj = $TriggerList->Item($Ctr)->Type;
	print "Trigger Name : ". $TriggerObj->Name."\n";
}

#

