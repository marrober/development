$Array[0] = "Mark";
$Array[1] = "Andy";
$Array[2] = "Steve";

print "The num items is : ".($#Array + 1)."\n";

print "last entry\t".pop(@Array)."\n";
print "middle entry\t".pop(@Array)."\n";
