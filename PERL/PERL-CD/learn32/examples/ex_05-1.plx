# ex_05-1
# Learning Perl on Win32 Systems, Exercise 5.1

%map = qw(red apple green leaves blue ocean);
print "A string please: "; chomp($some_string = <STDIN>);
print "The value for $some_string is $map{$some_string}\n";
