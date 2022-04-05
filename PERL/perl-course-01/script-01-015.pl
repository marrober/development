$Var = "C:\\default_snap\\Data\\perl-course\\script-001.pl@@\\main\\1";

$Location1 = index($Var, "@@");
$Location2 = rindex($Var, "\\");
$VarLength = length($Var);
$LcVar = lc($Var);
$UcVar = uc($Var);
$VersionInfo = substr($Var, index($Var, "@@") + 2);
$PathName = substr($Var, 0, index($Var, "@@"));

print "          10        20        30        40        50        60\n";
print "0123456789012345678901234567890123456789012345678901234567890\n";

print $Var."\n";
print $Location1."\n";
print $Location2."\n";
print $VarLength."\n";
print $LcVar."\n";
print $UcVar."\n";
print $VersionInfo."\n";
print $PathName."\n";

