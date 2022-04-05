$pipelineRunsCmd = "tkn pipelinerun list -o jsonpath='{.items[*].metadata.name}'";
$pipelineRuns = `$pipelineRunsCmd`;

@splitPipelineRunList = split(" ", $pipelineRuns);

foreach $pipelineRun (@splitPipelineRunList) {
    $pipelineRunDeleteCmd = "tkn pipelinerun delete -f ".$pipelineRun;
    `$pipelineRunDeleteCmd`;
}
