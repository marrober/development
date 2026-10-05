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
export interface PipelineRunDigest {
    name: string;
    pipeline?: string;
    params: RunParam[];
    workspaces: RunWorkspace[];
}
export declare function digestPipelineRun(text: string): PipelineRunDigest;
