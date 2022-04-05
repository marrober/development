sub ReadDataFile;

	for($Counter = 0; $Counter <= $#ARGV; $Counter++) {
    		$_ = $ARGV[$Counter];

		if (m|/D|) {
			$FileName = @ARGV[$Counter];
			$FileName =~ s|/D=||;
			ReadDataFile($FileName);
        	}
        	elsif (m|/C|) {
			$Temp = @ARGV[$Counter];
			$Temp =~ s|/C=||;
	            	$Current[$#Current+1] = $Temp;
        	}
        	elsif (m|/N|) {
			$Temp = @ARGV[$Counter];
			$Temp =~ s|/N=||;
			$New[$#New+1] = $Temp;
        	}
	        else {
	            print "ARGUMENT ERROR \n";
	        }
	}

	print "Swaps to be done :\n";

	for ($Counter = 0; $Counter <= $#Current; $Counter++) {
		print @Current[$Counter]." for ".@New[$Counter]."\n";
	}

	for ($Counter = 0; $Counter <= $#Current; $Counter++) {
		$Data =~ s/@Current[$Counter]/@New[$Counter]/g;
	}

	$OutputFile = ">".$FileName;

	open OutputFileHandle, $OutputFile;

	print OutputFileHandle $Data;

	close OutputFileHandle;

	exit(0);

sub ReadDataFile
{
	my $FileName = shift;

	$FileName =~ s|/D=||;

	open InputFileHandle, $FileName;

	while (eof(InputFileHandle) == 0)
	{
	        read InputFileHandle, $DataFromFile, 25;
        	$Data = join('',$Data, $DataFromFile);
    	}

	close InputFileHandle;
}


