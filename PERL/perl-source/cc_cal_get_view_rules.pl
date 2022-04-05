use Win32::OLE;

$FileToProcess = $ARGV[0];

my $cc = Win32::OLE->new('ClearCase.Application');

my $ViewProperties = $cc->View("default");

$ViewProperties->ConfigSpec("element * \\main\\LATEST\n");
print $ViewProperties->ConfigSpec."\n";


