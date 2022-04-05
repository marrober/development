use strict;
use Win32::OLE;
use CQPerlExt;

my $Baseline = $ARGV[0];
my $OutputFile = ">".$ARGV[1];

my $CC = Win32::OLE->new('ClearCase.Application');
# Get a list of all projects in the project VOB.

open OUTFILE, $OutputFile;

my $BlDescCmd = "cleartool lsbl -l ".$Baseline;

my $Results = `$BlDescCmd`;

my @ResultStrings = split("\n", $Results);

my @CQRecs = "";
my $InChangeSetSection = "no";
my $CQID = "";

foreach $_ (@ResultStrings)
{
	if (/change sets:/) { $InChangeSetSection = "yes"; next;}
	if (/promotion level:/) { $InChangeSetSection = "no"; next;}

	if ($InChangeSetSection eq "yes")
	{
    	# Get details of the change set.
		$CQID = substr($_, 0, index($_, "\@"));
		$CQID =~ s/^[ \t]+//;

		print "CQ ID : ".$CQID."\n";
		push (@CQRecs, $CQID);
	}
}

my $SessionObj = CQSession::Build();
$SessionObj->UserLogon("admin", "", "CLSIC", "2003.06.00x");

my $qryDef = $session->BuildQuery("defects");
$qryDef->BuildField("id");
my $resultSet = $session->BuildResultSet($qryDef);
$resultSet->Execute();

my $EntityObject = $SessionObj->BuildEntity("Baseline");

print $#CQRecs."\n";
my $CQRec = "";
foreach $CQRec (@CQRecs) {
	if (length($CQRec) > 0) {
		print "------------".$CQRec."\n";
		
		
		
		
		my $Record = $SessionObj->GetEntity( "defect", $CQRec);
	}
}
close OUTFILE;

exit(0);
