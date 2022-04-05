$Var1 = 21;
$Var2 = 37;

$Addition = $Var1 + $Var2;
$Subtraction = $Var2 - $Var1;
$Multiplication = $Var1 * $Var2;
$Division = $Var2 / $Var1;
$Modulo = $Var2 % $Var1;
$Power = $Var1 ** $Var2;

print "$Var1 + $Var2 = ".$Addition."\n";
print "$Var2 - $Var1 = ".$Subtraction."\n";
print "$Var1 * $Var2 = ".$Multiplication."\n";
print "$Var2 / $Var1 = ".$Division."\n";
print "$Var2 % $Var1 = ".$Modulo."\n";
print "$Var1 ** $Var2 = ".$Power."\n";

$IncrementVariable = 10;

print "Post increment : ".$IncrementVariable++."\n";
print $IncrementVariable."\n";

print "Pre increment : ".++$IncrementVariable."\n";
print $IncrementVariable."\n";