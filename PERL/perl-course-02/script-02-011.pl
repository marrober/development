use Win32::OLE;

my $cc = Win32::OLE->new('ClearCase.Application');

my $ver = $cc->Version("g:\\Data\\perl-source\\activity_dependence_triggers\\cc_trigger_co.pl@@\\main\\4") or die("Could not get version: ", Win32::OLE->LastError(), "\n"); 
my $path = $ver->Path; 
my $subbranches = $ver->SubBranches; 
my $enum = Win32::OLE::Enum->new($subbranches);

while (defined(my $branch = $enum->Next)) { 
     print($branch->Path, " branch sprouting from ", $ver->branch->Type->Name."\/".$ver->VersionNumber, " has ", 
           $branch->Versions->Count, " version(s); latest version is ", 
           $branch->LatestVersion->VersionNumber, "\n"); 
}
