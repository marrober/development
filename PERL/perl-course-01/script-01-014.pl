foreach $Arg (@ARGV) {
	print "Argument being processed : ".$Arg."\n";

	if (substr($Arg, 0, 4) eq "/set") {
		$CQDBSet = substr($Arg, 5);
	}
	elsif (substr($Arg, 0, 3) eq "/db") {
		$CQDB = substr($Arg, 4);
	}
	elsif (substr($Arg, 0, 5) eq "/user") {
		$UserName = substr($Arg, 6);
	}
	elsif (substr($Arg, 0, 9) eq "/password") {
		$Password = substr($Arg, 10);
	}
}

print "ClearQuest DB set    : ".$CQDBSet."\n";
print "ClearQuest DB        : ".$CQDB."\n";
print "ClearQuest user name : ".$UserName."\n";
print "ClearQuest password  : ".$Password."\n";	