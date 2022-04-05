$RoleHash{"Steve"} = "Consultant";
$RoleHash{"Andy"} = "Consultant";
$RoleHash{"Mark"} = "Manager";
$RoleHash{"Peter"} = "SSSR";

foreach $Key (keys %RoleHash){
	print "Key : ".$Key."\tValue : ".$RoleHash{$Key}."\n";;
}

print "CONSULTANTS\n";
while (($Name, $Role) = each(%RoleHash)) {
	if ($Role eq "Consultant") {
		print "\t".$Name."\n";
	}
}
