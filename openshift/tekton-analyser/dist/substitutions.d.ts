export type Substitution = {
    kind: 'param';
    name: string;
    path?: string;
} | {
    kind: 'taskResult';
    task: string;
    result: string;
    path?: string;
} | {
    kind: 'taskStatus';
    task: string;
} | {
    kind: 'aggregateStatus';
} | {
    kind: 'result';
    name: string;
    field?: string;
} | {
    kind: 'workspace';
    name: string;
    field?: string;
} | {
    kind: 'stepExit';
    step: string;
} | {
    kind: 'stepResult';
    step: string;
    result: string;
} | {
    kind: 'context';
    path: string;
} | {
    kind: 'unknown';
    raw: string;
};
export declare function splitReference(body: string): string[];
export declare function parseSubstitution(body: string): Substitution;
export declare function extractSubstitutions(input: string): Substitution[];
export declare function isKnownContext(path: string): boolean;
export declare function isKnownWorkspaceField(field: string | undefined): boolean;
