$_ = $ENV{'OS'};

if (m/Windows_NT/) {
	$TempFileName = $ENV{'TEMP'}."\\tempfile.tmp";
	$OS = $_;
}
else {
	$TempFileName = "/tmp/tempfile.tmp";
	$OS = `uname -rs`;
	$OS =~ s/\n//g;
}
print "Operating system in use is : ".$OS."\n";
print "Using temp file : ".$TempFileName."\n";
