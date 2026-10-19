import type { LoadResult } from './load.js';
import { type TektonResource } from './model.js';
import type { Issue } from './types.js';
export interface SummaryResource {
    name: string;
    namespace?: string;
    source?: string;
}
export interface TaskView extends SummaryResource {
    kind: 'Task' | 'ClusterTask';
    description?: string;
    params: string[];
    workspaces: string[];
    results: string[];
    steps: string[];
}
export interface TaskStepContent {
    name: string;
    image?: string;
    script?: string;
    command?: string[];
    args?: string[];
    workingDir?: string;
    env: {
        name: string;
        value?: string;
    }[];
    sidecar?: boolean;
}
export interface TaskContent {
    description?: string;
    params: {
        name: string;
        value?: string;
        default?: string;
    }[];
    workspaces: {
        name: string;
        mountPath?: string;
        pipeline?: string;
    }[];
    steps: TaskStepContent[];
}
export interface PipelineTaskView {
    name: string;
    ref: string;
    runAfter: string[];
    mounts: {
        workspaces: string[];
        volumes: string[];
        secrets: string[];
    };
    content: TaskContent;
}
export interface PipelineView extends SummaryResource {
    description?: string;
    params: string[];
    workspaces: string[];
    paramDefaults: {
        name: string;
        default?: string;
    }[];
    tasks: PipelineTaskView[];
    finally: PipelineTaskView[];
    order: string[][];
    edges: {
        from: string;
        to: string;
        via: Array<'runAfter' | 'result'>;
    }[];
}
export interface RunTaskView {
    name: string;
    phase: string;
    reason?: string;
}
export interface PipelineRunView extends SummaryResource {
    pipeline?: string;
    phase: string;
    reason?: string;
    tasks: RunTaskView[];
}
export interface Summary {
    repository: string;
    contextDir: string;
    counts: {
        tasks: number;
        pipelines: number;
        pipelineRuns: number;
        taskRuns: number;
    };
    tasks: TaskView[];
    pipelines: PipelineView[];
    pipelineRuns: PipelineRunView[];
    taskRuns: PipelineRunView[];
    issues: Issue[];
}
export declare function summarise(loaded: LoadResult, options: {
    root: string;
    repository: string;
    contextDir: string;
}): Summary;
export declare function resourceCounts(resources: TektonResource[]): Summary['counts'];
