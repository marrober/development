import type { TaskGraph } from './types.js';
export interface GraphDependency {
    name: string;
    via: 'runAfter' | 'result';
}
export interface GraphTask {
    name: string;
    dependencies: GraphDependency[];
}
/**
 * Build the Pipeline task DAG. Edges point from the task that must finish
 * to the task that waits for it. Result references are dependencies because
 * Tekton runs a producing task before any task that reads its results.
 */
export declare function buildTaskGraph(tasks: GraphTask[]): TaskGraph;
export declare function formatCycle(cycle: string[]): string;
