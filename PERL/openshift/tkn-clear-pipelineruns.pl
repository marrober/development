$pipelineRunsCmd = "tkn pipelinerun list -o jsonpath='{.items[*].metadata.name}'";
$pipelineRuns = `$pipelineRunsCmd`;

@splitPipelineRunList = split(" ", $pipelineRuns);

foreach $pipelineRun (@splitPipelineRunList) {
    $pipelineStatusCmd = "tkn pipelinerun describe ".$$pipelineRun." -o jsonpath='{.status.conditions[0].reason}'";
    $pipelineStatus = `$pipelineStatusCmd`;

    print($pipelineStatus);


    $pipelineRunDeleteCmd = "tkn pipelinerun delete -f ".$pipelineRun;

    print($pipelineRunDeleteCmd);

    # `$pipelineRunDeleteCmd`;
}
