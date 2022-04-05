$ChangeSetNumber = @ARGV[0];

$DescribeCommand = "p4 describe -s ".$ChangeSetNumber;
$DescribeResult = `$DescribeCommand`;

$HeaderLine = substr($DescribeResult, 0, index($DescribeResult, "\n"));
@SplitHeader = split(" ", $HeaderLine);
$UserName = substr(@SplitHeader[3], 0, index(@SplitHeader[3], "@"));
$DateTime = @SplitHeader[5]." ".@SplitHeader[6];
print $HeaderLine."\n";
print "---------------------------------------------------------\n";
$DescribeResult = substr($DescribeResult, index($DescribeResult, "\n"));
$Comment = substr($DescribeResult, 0, index($DescribeResult, "Affected files ..."));
$Comment =~ s/\n\n/\n/g;
$Comment =~ s/^\n//g;
$Comment =~ s/\n$//;
$Comment = substr($Comment, 1);
print $ChangeSetNumber."\n";
print $UserName."\n";
print $DateTime."\n";
print $Comment."\n";

open CommentFile, ">c:\\temp\\AttributeData.txt";
print CommentFile $ChangeSetNumber."\n";
print CommentFile $UserName."\n";
print CommentFile $DateTime."\n";
print CommentFile $Comment."\n";
close CommentFile;


