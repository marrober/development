use Win32::OLE;

$FileToProcess = $ARGV[0];

my $cc = Win32::OLE->new('ClearCase.Application');

my $ElementObj = $cc->Element($FileToProcess);

print "Element path : ". $ElementObj->Path."\n";
print "Element owner : ". $ElementObj->Owner."\n";

my $TriggerList = $ElementObj->Triggers;

for ($Counter = 1; $Counter <= $TriggerList->Count; $Counter = $Counter + 1)
{	
	my $TriggerObj = $TriggerList->Item($Counter)->Type;
	print "Name : ". $TriggerObj->Name."\n";
}



###


