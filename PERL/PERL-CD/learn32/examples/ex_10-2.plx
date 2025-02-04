# ex_10-2
# Learning Perl on Win32 Systems, Exercise 10.2

print "Input file name: ";
chomp($infilename = <STDIN>);
print "Output file name: ";
chomp($outfilename = <STDIN>);
print "Search string: ";
chomp($search = <STDIN>);
print "Replacement string: ";
chomp($replace = <STDIN>);
open(IN,$infilename) ||
  die "cannot open $infilename for reading: $!";
## optional test for overwrite...
die "will not overwrite $outfilename" if -e $outfilename;
open(OUT,">$outfilename") ||
  die "cannot create $outfilename: $!";
while (<IN>) { # read a line from file IN into $_
  s/$search/$replace/g; # change the lines
  print OUT $_; # print that line to file OUT
}
close(IN);
close(OUT);
