$LoginName = $ARGV[0];
$EnteredSignature = $ARGV[1];
$EncryptedString = $ARGV[2];
$LoginName .= $LoginName;
$EnteredSignature .= "ABCDEFGHIJKLMNOPQRSTUVWXYZ";


open SIGFILE, ">c:\\temp\\signaturedata.txt";
print SIGFILE $LoginName."\n";
print SIGFILE $EnteredSignature."\n";
close SIGFILE;

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
print "\n".$EncryptedString."\n".$EDString."\n";
print length($EncryptedString)."  ".length($EDString)."\n";
if ($EncryptedString eq $EDString)
{
    print "Matched\n";
    exit(0);
}
else
{
    print "Failed\n";
    exit(1);
}
