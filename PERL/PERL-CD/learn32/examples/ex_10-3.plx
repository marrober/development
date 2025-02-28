# ex_10-3
# Learning Perl on Win32 Systems, Exercise 10.3

while (<>) {
  chomp; # eliminate the newline
  print "$_ is readable\n" if -r;
  print "$_ is writable\n" if -w;
  print "$_ is executable\n" if -x;
  print "$_ does not exist\n" unless -e;
}
