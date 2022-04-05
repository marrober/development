use Win32::OLE;

my $CC = Win32::OLE->new('ClearCase.Application');

my $VobList = $CC->Vobs();

my $VobEnum = Win32::OLE::Enum->new($VobList);

while (defined(my $Vob = $VobEnum->Next)) { 

	print $Vob->TagName()."\n";

}
