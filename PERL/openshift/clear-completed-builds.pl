$buildList = `oc get builds -o jsonpath='{range .items[*]}{.metadata.name}{"-"}{.status.phase}{" "}'`;

@buildArray = split(/ /, $buildList);

foreach $build (@buildArray) {
  if (index($build, "-Complete") != -1) {

    $deleteCommand = "oc delete build/".substr($build, 0, length($build) - length("-Complete"));
    print `$deleteCommand`;
  }
}
