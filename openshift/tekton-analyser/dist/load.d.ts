import type { TektonResource } from './model.js';
import type { Issue, OtherResource } from './types.js';
export interface LoadResult {
    resources: TektonResource[];
    others: OtherResource[];
    issues: Issue[];
}
export declare function loadResources(paths: string[]): Promise<LoadResult>;
