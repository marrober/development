import type { TektonResource, TriggerTemplateResource } from './model.js';
import type { Issue, OtherResource } from './types.js';
export interface LoadResult {
    resources: TektonResource[];
    others: OtherResource[];
    triggerTemplates: TriggerTemplateResource[];
    issues: Issue[];
}
export declare function loadResources(paths: string[]): Promise<LoadResult>;
