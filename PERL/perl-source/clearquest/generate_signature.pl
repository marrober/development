$LoginName = $ARGV[0];
$PlainText = $ARGV[1];
$FileName = $ARGV[2];
$LoginName .= $LoginName;
$EnteredSignature .= "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

@Chars = split(//, $LoginName);
foreach $Char (@Chars)
{
    push(@CharCodes, ord($Char));
}

$Counter = 0;
foreach $CharCode (@CharCodes)
{
    $ShiftedData = $CharCode << $Counter++;
    push(@ShiftedDataArray, $ShiftedData);
    if ($Counter > 5) { $Counter = 0; }
}

@Chars = split(//, $EnteredSignature);
foreach $Char (@Chars)
{
    push(@SigCodes, ord($Char));
}

$Counter = 0;
foreach $SD (@ShiftedDataArray)
{
    $ED = $SD ^ @SigCodes[$Counter++];
    $EDString .= $ED;
}

open EFile, ">".$FileName;
print EFile $EDString."\n";
close EFile;


















































