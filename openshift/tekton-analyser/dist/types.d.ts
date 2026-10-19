export type ParamTypeName = 'string' | 'array' | 'object';
export interface Issue {
    severity: 'error' | 'warning';
    code: string;
    message: string;
    kind?: string;
    name?: string;
    namespace?: string;
    source?: string;
    path?: string;
}
export interface ParamSummary {
    name: string;
    type: ParamTypeName;
    required: boolean;
    description?: string;
    default?: unknown;
    enum?: string[];
}
export interface ResultSummary {
    name: string;
    type: ParamTypeName;
    description?: string;
    value?: unknown;
}
export interface WorkspaceSummary {
    name: string;
    description?: string;
    optional: boolean;
    mountPath?: string;
    readOnly?: boolean;
}
export interface StepSummary {
    name?: string;
    displayName?: string;
    image?: string;
    script: boolean;
    command?: string[];
    onError?: string;
    timeout?: string;
    usesStepAction: boolean;
}
export interface TaskAnalysis {
    kind: 'Task' | 'ClusterTask';
    apiVersion: string;
    name: string;
    namespace?: string;
    source?: string;
    description?: string;
    displayName?: string;
    params: ParamSummary[];
    results: ResultSummary[];
    workspaces: WorkspaceSummary[];
    steps: StepSummary[];
    sidecars: StepSummary[];
    volumes: string[];
    issues: Issue[];
}
export type Resolution = {
    mode: 'inline';
} | {
    mode: 'ref';
    taskName?: string;
    resolved: boolean;
    kind?: string;
} | {
    mode: 'resolver';
    resolver: string;
    taskName?: string;
} | {
    mode: 'custom';
    apiVersion?: string;
    kind: string;
    name?: string;
} | {
    mode: 'pipeline';
    pipelineName?: string;
    inline: boolean;
} | {
    mode: 'missing';
};
export interface PipelineTaskAnalysis {
    name: string;
    displayName?: string;
    description?: string;
    runAfter: string[];
    dependencies: {
        task: string;
        via: Array<'runAfter' | 'result'>;
    }[];
    resolution: Resolution;
    params: {
        name: string;
        value?: unknown;
    }[];
    matrixParams: string[];
    workspaces: {
        name: string;
        workspace?: string;
        subPath?: string;
    }[];
    when: {
        input?: string;
        operator?: string;
        values: string[];
        cel?: string;
    }[];
    retries?: number;
    timeout?: string;
    onError?: string;
}
export interface TaskGraph {
    nodes: string[];
    edges: {
        from: string;
        to: string;
        via: Array<'runAfter' | 'result'>;
    }[];
    levels: string[][];
    cycles: string[][];
    unscheduled: string[];
}
export interface PipelineAnalysis {
    apiVersion: string;
    name: string;
    namespace?: string;
    source?: string;
    description?: string;
    displayName?: string;
    params: ParamSummary[];
    workspaces: WorkspaceSummary[];
    results: ResultSummary[];
    tasks: PipelineTaskAnalysis[];
    finally: PipelineTaskAnalysis[];
    graph: TaskGraph;
    issues: Issue[];
}
export interface StepStateSummary {
    name?: string;
    phase: string;
    exitCode?: number;
    reason?: string;
}
export interface ExecutionAnalysis {
    taskRunName?: string;
    phase: string;
    reason?: string;
    message?: string;
    startTime?: string;
    completionTime?: string;
    durationMs?: number;
    duration?: string;
    steps: StepStateSummary[];
    results: {
        name: string;
        value?: unknown;
    }[];
}
export interface RunTaskAnalysis {
    name: string;
    phase: string;
    reason?: string;
    executions: ExecutionAnalysis[];
}
export interface PipelineRunAnalysis {
    apiVersion: string;
    name: string;
    namespace?: string;
    source?: string;
    pipelineName?: string;
    pipelineSource: 'status' | 'inline' | 'ref' | 'unresolved';
    resolver?: string;
    phase: string;
    reason?: string;
    message?: string;
    desiredStatus?: string;
    startTime?: string;
    completionTime?: string;
    finallyStartTime?: string;
    durationMs?: number;
    duration?: string;
    params: {
        name: string;
        value?: unknown;
    }[];
    workspaces: {
        name: string;
        kind: string;
        subPath?: string;
    }[];
    serviceAccountName?: string;
    timeouts?: {
        pipeline?: string;
        tasks?: string;
        finally?: string;
    };
    tasks: RunTaskAnalysis[];
    finally: RunTaskAnalysis[];
    results: {
        name: string;
        value?: unknown;
    }[];
    graph?: TaskGraph;
    issues: Issue[];
}
export interface TaskRunAnalysis {
    apiVersion: string;
    name: string;
    namespace?: string;
    source?: string;
    taskName?: string;
    pipelineTaskName?: string;
    pipelineRunName?: string;
    phase: string;
    reason?: string;
    message?: string;
    podName?: string;
    startTime?: string;
    completionTime?: string;
    durationMs?: number;
    duration?: string;
    steps: StepStateSummary[];
    results: {
        name: string;
        value?: unknown;
    }[];
    issues: Issue[];
}
export interface OtherResource {
    apiVersion: string;
    kind: string;
    name?: string;
    namespace?: string;
    source?: string;
    tekton: boolean;
}
export interface Analysis {
    summary: {
        tasks: number;
        pipelines: number;
        pipelineRuns: number;
        taskRuns: number;
        otherTekton: number;
        ignored: number;
        errors: number;
        warnings: number;
    };
    tasks: TaskAnalysis[];
    pipelines: PipelineAnalysis[];
    pipelineRuns: PipelineRunAnalysis[];
    taskRuns: TaskRunAnalysis[];
    others: OtherResource[];
    issues: Issue[];
}
