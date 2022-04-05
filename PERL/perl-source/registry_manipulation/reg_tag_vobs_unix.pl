$DataFile = @ARGV[0];

# Get the host name.
#
# $HostName = `uname -n`;
$HostName = "IBMGB-MROBER01";
$HostName =~ s/\n//g;

print "Host name : ".$HostName."\n";

open DF, $DataFile;

while (!(eof(DF)))
{
	read DF, $DataFromFileTmp, 25;

	$DataFromFile .= $DataFromFileTmp;
}

close DF;

print $DataFromFile."\n";

exit(0);





        # $CTRegCmd = "cleartool register -vob -host ".$HostName." -hpath ".$VOBStgDir."\/".$VOBDir." -gpath \/net\/".$HostName.$VOBStgDir."\/".$VOBDir." ".$VOBStgDir."\/".$VOBDir;
        # $CTMkTagCmd = "cleartool mktag -vob -tag ".$VOBTagPrefix."\/".$VOBDir." -public -password rational -host ".$HostName." -gpath \/net\/".$HostName.$VOBStgDir."\/".$VOBDir." ".$VOBStgDir."\/".$VOBDir;
        $CTRegCmd = "cleartool register -vob ".$VOBStgDir."\/".$VOBDir;
        $CTMkTagCmd = "cleartool mktag -vob -tag ".$VOBTagPrefix."\/".$VOBDir." -public -password rational ".$VOBStgDir."\/".$VOBDir;
        `$CTRegCmd`;
        print ".... registered";
        `$CTMkTagCmd`;
        print ".... tagged\n";



exit(0);

