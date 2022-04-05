$FileName = @ARGV[0];

open InputFileHandle, $FileName;
  
while (eof(InputFileHandle) == 0)
{
    read InputFileHandle, $DataFromFile, 25;
    $FileContent = join('',$FileContent, $DataFromFile);
}

close InputFileHandle;

@SplitRes = split /\n/, $FileContent;

@SplitLines = @SplitRes;

$FileName = ">".$FileName;
open OutputFileHandle, $FileName;
$LineCounter = 0;
$linesSkipped = 0;
foreach $Line (@SplitLines)
{
	if (length($Line) > 0) {   
	    print OutputFileHandle $Line."\n";
	    $LineCounter++;
	}
	else {
		$LinesSkipped++;
	}
}

close OutputFileHandle;

print "lines written : ".$LineCounter."\n";
print "lines skipped : ".$LinesSkipped."\n";
