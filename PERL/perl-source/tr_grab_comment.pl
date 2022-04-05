# ClearCase Trigger Script.

$Time = time();

@TimeArray = gmtime($Time);

print @TimeArray[2].":".@TimeArray[1].":".@TimeArray[0]."\n";

$TempFile = "c:\\temp\\cc_comment_capture_".@TimeArray[3]."_".(@TimeArray[4] + 1)."_".@TimeArray[2]."_".@TimeArray[1]."_".@TimeArray[0].".txt";

print $TempFile."\n";

if (-e $TempFile)
{
	`del $TempFile`;
}

$TempFile = ">".$TempFile;

open FileHandle, $TempFile;

$Comment = $ENV{'CLEARCASE_COMMENT'};

print FileHandle $Comment;

close FileHandle;

