$podList = `oc get pods -o jsonpath='{range .items[*]}{.metadata.name}{"-"}{.status.phase}{" "}'`;

@podArray = split(/ /, $podList);

foreach $pod (@podArray) {

  if (index($pod, "-Succeeded") != -1) {

    $deleteCommand = "oc delete pod/".substr($pod, 0, length($pod) - length("-Succeeded"));
    print `$deleteCommand`;
  }
}
