export interface RunParam {
    name: string;
    value: string;
}
export interface WorkspaceFile {
    path: string;
    source: string;
}
export interface RunWorkspace {
    name: string;
    files: WorkspaceFile[];
    notes: string[];
}
export interface WorkspaceSourceInput {
    kind: 'secret' | 'configmap';
    name?: string;
    items: {
        key?: string;
        path?: string;
    }[];
}
export interface PipelineRunDigest {
    name: string;
    pipeline?: string;
    params: RunParam[];
    workspaces: RunWorkspace[];
}
export declare function digestPipelineRun(text: string): PipelineRunDigest;
export declare function describeWorkspace(name: string, subPath: string | undefined, sources: WorkspaceSourceInput[], params: Map<string, string>): RunWorkspace[];
