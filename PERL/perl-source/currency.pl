	my ($InputCurrency) = 129.3456789;
	my ($NewCurrency) = "";

	if (index($InputCurrency, "\.") < 0) {
		$InputCurrency .= ".00";
	}
	@Reversed = split("", reverse($InputCurrency));

	$Cent = 0;
	$Counter = 0;
	
	foreach $Digit (@Reversed) {
		$_ = $Digit;
		$NewCurrency .= $Digit;
		if ($Cent == 1) { 
			$Counter++; 
			if ($Counter == 3) {
				$NewCurrency .= ",";
				$Counter = 0;
			}
		}
		if (m/\./) { $Cent = 1; }
	}
	$NewCurrency = reverse($NewCurrency);
	$_ = substr($NewCurrency, 0, 1);
	if (m/,/) {
		$NewCurrency = substr($NewCurrency, 1);	
	}
	if ((length($NewCurrency) - index($NewCurrency, "\.")) == 2) {
		$NewCurrency .= "0";
	}
	print $NewCurrency."\n";

	$New2 = sprintf("%.02f", $InputCurrency);

	print $New2."\n";
