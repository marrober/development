$runningPipeline = `oc create -f $ARGV[0]`;

@splitPipelineResult = split("/", $runningPipeline);
@splitPipelineResult = split(" ", @splitPipelineResult[1]);
$pipelineName = @splitPipelineResult[0];

print "Pipeline name : ".$pipelineName."\n";

sleep (1);

$pipelineRunningReasonCmd = "tkn pipelinerun describe ".$pipelineName." -o jsonpath='{.status.conditions[0].reason}'";
$pipelineRunningReason = `$pipelineRunningReasonCmd`;

while($pipelineRunningReason eq "Running") {
  sleep(1);
  $pipelineRunningReason = `$pipelineRunningReasonCmd`;
  $pipelineRunningStatusCmd = "tkn pipelinerun describe ".$pipelineName." -o jsonpath='{.status.conditions[0]}'";
}

if ($pipelineRunningStatus eq "False") {
  print "EXECUTION FAILED ....\n";
}

$pipelineGetLogsCmd = "tkn pipelinerun logs ".$pipelineName;
print `$pipelineGetLogsCmd`;
