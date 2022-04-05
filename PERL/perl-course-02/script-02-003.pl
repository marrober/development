foreach $_ (@ARGV) {
	print "Argument being processed : ".$_."\n";

	if (?/set?) {
		$CQDBSet = substr($_, length("/set="));
	}
	elsif (?/db?) {
		$CQDB = substr($_, length("/db="));
	}
	elsif (?/user?) {
		$UserName = substr($_, length("/user="));
	}
	elsif (?/password?) {
		$Password = substr($_, length("/password="));
	}
}

print "ClearQuest DB set    : ".$CQDBSet."\n";
print "ClearQuest DB        : ".$CQDB."\n";
print "ClearQuest user name : ".$UserName."\n";
print "ClearQuest password  : ".$Password."\n";	