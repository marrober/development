$running = 1;
while ($running > 0) {
  sleep(3);
  $buildList = `oc get builds -o jsonpath='{range .items[*]}{.metadata.name}{"-"}{.status.phase}{" "}'`;

  @buildArray = split(/ /, $buildList);
  pop(@buildArray);

  $running = 0;

  foreach $build (@buildArray) {
    if (index($build, "-Complete") < 0) {

      print ".";
      $running++;
    }
  }
  if ($running > 0) {
    print "/";
  }
}
print "All builds completed\n\n";
foreach $build (@buildArray) {
  print $build."\n";
}
