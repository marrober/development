# ClearCase trigger script to perform keyword substitution on checkin.
#
# Initial author : Mark Roberts, Rational Software.
# Creation date  : 26th April, 2000.

$EnvTemp = $ENV{'TEMP'};
#
if (length($EnvTemp) == 0)
{
    $EnvTemp = $ENV{'temp'};
}
if (length($EnvTemp) == 0)
{
    print "\n\n ERROR : Could not find one of the following environment variables\n";
    print "        temp, TEMP\n";
    exit(0);
}

# Copy the file being checked in to a safe place, in case recovery is required.
#
$CopyCommand = "copy ".$ENV{CLEARCASE_PN}." ".$EnvTemp."\\cc_key_sub.safe";

print $CopyCommand."\n";

`$CopyCommand`;

# Copy the file being checked in to the temp. directory for manipulation.
#
$CopyCommand = "copy ".$ENV{CLEARCASE_PN}." ".$EnvTemp."\\cc_key_sub.temp_in";

print $CopyCommand."\n";

`$CopyCommand`;

open(FileHandle, $EnvTemp."\\cc_key_sub.temp_in");

while ($LinesToRead == 0)
{
	if (eof(FileHandle) == 1)
	{
		$LinesToRead = 1;
	}
	else
	{
		read(FileHandle, $FileBuffer, 1024);
		$FileContent .= $FileBuffer;
	}
}
close(FileHandle);

# Build CM information.

$CMBlock =  "-----------------------------------------------------------------\n";
$CMBlock .= "Version : ".$ENV{CLEARCASE_ID_STR}."\n";
$CMBlock .= "Comment : ".$ENV{CLEARCASE_COMMENT}."\n";
$CMBlock .= "-----------------------------------------------------------------\n";

print $CMBlock."\n";
print "===========================================================\n";

$FileContent =~ s/##CMBLOCK##/##CMBLOCK##\n$CMBlock/;

print $FileContent."\n";

$OutputFile = ">".$EnvTemp."\\cc_key_sub.temp_out";

open(FileHandle, $OutputFile);

print FileHandle $FileContent;
close(FileHandle);

# Copy the file back to the original storage.

$CopyCommand = "copy ".$EnvTemp."\\cc_key_sub.temp_out ".$ENV{CLEARCASE_PN};

print $CopyCommand."\n";

`$CopyCommand`;




