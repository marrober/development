push (@SearchStrings, "Mark");
push (@SearchStrings, "Marketing");
push (@SearchStrings, "Marks & Spencer");
push (@SearchStrings, "Shops");
push (@SearchStrings, "shopping");
push (@SearchStrings, "Shopss");

foreach (@SearchStrings) {
	print "Searching ".$_."\n";
	if (/Mark/) {
		print "\tfound to contain 'Mark'\n";
	}
	if (/Shop/) {
		print "\tfound to contain 'Shop'\n";
	}
	if (/n/) {
		print "\tfound to contain 'n'\n";
	}
	if (/[MS]/) {
		print "\tfound to contain 'M or S'\n";
	}
	if (!/[k]/) {
		print "\tfound not to contain 'k'\n";
	}	
	if (/p+/) {
		print "\tcontains one or more 'p'\n";
	}
	if (/p{2,2}/) {
		print "\tcontains exactly 2 'p'\n";
	}	
	if (/S/) {
		print "\tcontains an 'S' anywhere\n";
	}
	if (/^S/) {
		print "\tcontains an 'S' at the beginning\n";
	}	
	if (/k/) {
		print "\tcontains a 'k' anywhere\n";
	}
	if (/k$/) {
		print "\tcontains a 'k' at the end\n";
	}
	if (/[Ss]hop[s*]\b/) {
		print "\tcontains shop or shops only (any case)\n";
	}	
	if (/s{2,2}$/) {
		print "\tcontains exactly 2 's' at the end\n";
	}						
}