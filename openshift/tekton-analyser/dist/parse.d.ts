import type { PipelineResource, PipelineRunResource, TaskResource, TaskRunResource, TektonResource } from './model.js';
import type { Issue, OtherResource } from './types.js';
export interface ParseResult {
    resources: TektonResource[];
    others: OtherResource[];
    issues: Issue[];
}
export declare function parseManifest(text: string, source: string, format: 'yaml' | 'json'): ParseResult;
export declare function isTask(resource: TektonResource): resource is TaskResource;
export declare function isPipeline(resource: TektonResource): resource is PipelineResource;
export declare function isPipelineRun(resource: TektonResource): resource is PipelineRunResource;
export declare function isTaskRun(resource: TektonResource): resource is TaskRunResource;
