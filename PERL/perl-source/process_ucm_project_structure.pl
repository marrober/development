$DataFile = @ARGV[0];

open FH, $DataFile;
while (!eof(FH))
{
    read FH, $DataFromFile, 100;
    $ProjData .= $DataFromFile;
}

close FH;

@ProjectData = split("\n", $ProjData);
$ProjectCounter = 0;
foreach $_ (@ProjectData)
{
    if (m/^([a-z]|[A-Z]|[0-9])/)
    {
        if ( index($_,"\t") < 0)
        {
            $Index = index($_, " ");
        }
        else
        {
            $Index = index($_,"\t");
        }
        $ProjectName = substr($_, 0, $Index);
        print $ProjectName."\n";
        $ProjectCounter++;
    }
}
print $ProjectCounter."\n";
