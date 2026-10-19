export interface ObjectMeta {
    name?: string;
    generateName?: string;
    namespace?: string;
    uid?: string;
    labels?: Record<string, string>;
    annotations?: Record<string, string>;
}
export interface ParamSpec {
    name: string;
    type?: 'string' | 'array' | 'object';
    description?: string;
    hasDefault: boolean;
    default?: unknown;
    enum?: string[];
    properties?: string[];
}
export interface Param {
    name: string;
    hasValue: boolean;
    value?: unknown;
}
export interface ResultDecl {
    name: string;
    type?: 'string' | 'array' | 'object';
    description?: string;
    value?: unknown;
    properties?: string[];
}
export interface WorkspaceDecl {
    name: string;
    description?: string;
    optional: boolean;
    mountPath?: string;
    readOnly?: boolean;
}
export interface Step {
    name?: string;
    displayName?: string;
    image?: string;
    command?: string[];
    args?: string[];
    script?: string;
    workingDir?: string;
    env: {
        name: string;
        value?: string;
    }[];
    timeout?: string;
    onError?: string;
    refName?: string;
    when: WhenExpression[];
}
export interface TaskVolume {
    name: string;
    kind: string;
    secrets: string[];
    claim?: string;
    configMap?: string;
}
export interface TaskSpec {
    displayName?: string;
    description?: string;
    params: ParamSpec[];
    results: ResultDecl[];
    workspaces: WorkspaceDecl[];
    steps: Step[];
    sidecars: Step[];
    volumes: TaskVolume[];
    stepTemplateImage?: string;
    stepTemplateEnv: {
        name: string;
        value?: string;
    }[];
    hasResources: boolean;
}
export interface TaskRef {
    name?: string;
    kind?: string;
    apiVersion?: string;
    resolver?: string;
    params: Param[];
}
export interface PipelineRef {
    name?: string;
    apiVersion?: string;
    resolver?: string;
    params: Param[];
}
export interface WhenExpression {
    input?: string;
    operator?: string;
    values: string[];
    cel?: string;
}
export interface WorkspacePipelineBinding {
    name: string;
    workspace?: string;
    subPath?: string;
}
export interface MatrixInclude {
    name?: string;
    params: Param[];
}
export interface Matrix {
    params: Param[];
    include: MatrixInclude[];
}
export interface PipelineTask {
    name: string;
    displayName?: string;
    description?: string;
    taskRef?: TaskRef;
    taskSpec?: TaskSpec;
    pipelineRef?: PipelineRef;
    pipelineSpec?: PipelineSpec;
    when: WhenExpression[];
    retries?: number;
    runAfter: string[];
    params: Param[];
    matrix?: Matrix;
    workspaces: WorkspacePipelineBinding[];
    timeout?: string;
    onError?: string;
    hasResources: boolean;
}
export interface PipelineWorkspaceDecl {
    name: string;
    description?: string;
    optional: boolean;
}
export interface PipelineSpec {
    displayName?: string;
    description?: string;
    tasks: PipelineTask[];
    params: ParamSpec[];
    workspaces: PipelineWorkspaceDecl[];
    results: ResultDecl[];
    finally: PipelineTask[];
    hasResources: boolean;
}
export interface WorkspaceBinding {
    name: string;
    subPath?: string;
    kind: string;
}
export interface TaskRunSpecOverride {
    pipelineTaskName?: string;
    serviceAccountName?: string;
    timeout?: string;
}
export interface PipelineRunSpec {
    pipelineRef?: PipelineRef;
    pipelineSpec?: PipelineSpec;
    params: Param[];
    status?: string;
    timeouts?: {
        pipeline?: string;
        tasks?: string;
        finally?: string;
    };
    serviceAccountName?: string;
    workspaces: WorkspaceBinding[];
    taskRunSpecs: TaskRunSpecOverride[];
}
export interface Condition {
    type?: string;
    status?: string;
    reason?: string;
    message?: string;
}
export interface StepState {
    name?: string;
    waitingReason?: string;
    terminated?: {
        exitCode?: number;
        reason?: string;
    };
    running: boolean;
}
export interface TaskRunStatus {
    conditions: Condition[];
    podName?: string;
    startTime?: string;
    completionTime?: string;
    steps: StepState[];
    results: {
        name: string;
        value?: unknown;
    }[];
}
export interface ChildReference {
    name?: string;
    displayName?: string;
    pipelineTaskName?: string;
    kind?: string;
    apiVersion?: string;
    when: WhenExpression[];
}
export interface SkippedTask {
    name?: string;
    reason?: string;
    when: WhenExpression[];
}
export interface LegacyTaskRun {
    pipelineTaskName?: string;
    status?: TaskRunStatus;
    when: WhenExpression[];
}
export interface PipelineRunStatus {
    conditions: Condition[];
    startTime?: string;
    completionTime?: string;
    finallyStartTime?: string;
    results: {
        name: string;
        value?: unknown;
    }[];
    pipelineSpec?: PipelineSpec;
    skippedTasks: SkippedTask[];
    childReferences: ChildReference[];
    taskRuns: Record<string, LegacyTaskRun>;
}
export interface TaskRunSpec {
    params: Param[];
    serviceAccountName?: string;
    taskRef?: TaskRef;
    taskSpec?: TaskSpec;
    status?: string;
    timeout?: string;
    workspaces: WorkspaceBinding[];
    retries?: number;
}
export interface ResourceBase {
    apiVersion: string;
    kind: string;
    metadata: ObjectMeta;
    source?: string;
}
export interface TaskResource extends ResourceBase {
    kind: 'Task' | 'ClusterTask';
    spec: TaskSpec;
}
export interface PipelineResource extends ResourceBase {
    kind: 'Pipeline';
    spec: PipelineSpec;
}
export interface PipelineRunResource extends ResourceBase {
    kind: 'PipelineRun';
    spec: PipelineRunSpec;
    status?: PipelineRunStatus;
}
export interface TaskRunResource extends ResourceBase {
    kind: 'TaskRun';
    spec: TaskRunSpec;
    status?: TaskRunStatus;
}
export type TektonResource = TaskResource | PipelineResource | PipelineRunResource | TaskRunResource;
export declare function resourceName(metadata: ObjectMeta): string;
