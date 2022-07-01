$pipelineRunsCmd = "tkn pipelinerun list -o jsonpath='{range .items[*]}{.metadata.name}{\" \"}{.spec.pipelineRef.name}{\" \"}{.metadata.creationTimestamp}{\" \"}{.status.conditions[0].reason}{\"\\n\"}'";

$pipelineRuns = `$pipelineRunsCmd`;

@splitPipelineRunList = split(/\n/, $pipelineRuns);

pop(@splitPipelineRunList);

print("Total pipelines : ".($#splitPipelineRunList  + 1)."\n");

$counter = 1;

foreach $_ (@splitPipelineRunList) {

    print($counter++."   ".$_."\n");

    $pipeline = $_;

    @splitPipelineRunParts = split(" ", $_);

    $_ = @splitPipelineRunParts[3];

    if (m/Running/) {
      print("Ignore running pipeline\n");
    } else {
      push @deletionCandidates, $pipeline;

      push @{$pipelineRunsHash{@splitPipelineRunParts[1]} }, @splitPipelineRunParts[2]." ".@splitPipelineRunParts[0];
    }




    # $pipelineRunDeleteCmd = "tkn pipelinerun delete -f ".@splitPipelineRunParts[0];

    # print($pipelineRunDeleteCmd);

    # `$pipelineRunDeleteCmd`;
}

print("Deletion candidates : ".($#deletionCandidates + 1)."\n");

foreach my $key (sort keys %pipelineRunsHash) {
    my @array = @{ $pipelineRunsHash{$key} };
    print $key." ".($#array + 1)."\n";
    foreach my $element (@array) {
      print "\t".$element."\n";

    }
}
