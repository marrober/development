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
export function buildTaskGraph(tasks: GraphTask[]): TaskGraph {
  const nodes = tasks.map((task) => task.name);
  const index = new Map(nodes.map((name, position) => [name, position]));
  const nodeSet = new Set(nodes);
  const edgeMap = new Map<string, { from: string; to: string; via: Array<'runAfter' | 'result'> }>();

  for (const task of tasks) {
    for (const dependency of task.dependencies) {
      if (!nodeSet.has(dependency.name) || dependency.name === task.name) continue;
      const key = `${dependency.name}->${task.name}`;
      const existing = edgeMap.get(key);
      if (!existing) {
        edgeMap.set(key, { from: dependency.name, to: task.name, via: [dependency.via] });
      } else if (!existing.via.includes(dependency.via)) {
        existing.via.push(dependency.via);
      }
    }
  }

  const edges = [...edgeMap.values()].sort((left, right) => {
    const byTo = (index.get(left.to) ?? 0) - (index.get(right.to) ?? 0);
    if (byTo !== 0) return byTo;
    return (index.get(left.from) ?? 0) - (index.get(right.from) ?? 0);
  });

  const dependencies = new Map<string, string[]>();
  for (const name of nodes) dependencies.set(name, []);
  for (const edge of edges) dependencies.get(edge.to)?.push(edge.from);

  const cycles = findCycles(nodes, dependencies);
  const levels: string[][] = [];
  const indegree = new Map(nodes.map((name) => [name, 0]));
  const dependents = new Map<string, string[]>(nodes.map((name) => [name, []]));
  for (const edge of edges) {
    indegree.set(edge.to, (indegree.get(edge.to) ?? 0) + 1);
    dependents.get(edge.from)?.push(edge.to);
  }

  let ready = nodes.filter((name) => (indegree.get(name) ?? 0) === 0);
  const seen = new Set<string>();
  while (ready.length > 0) {
    const level = [...ready].sort((left, right) => (index.get(left) ?? 0) - (index.get(right) ?? 0));
    levels.push(level);
    const next: string[] = [];
    for (const name of level) {
      seen.add(name);
      for (const dependent of dependents.get(name) ?? []) {
        const remaining = (indegree.get(dependent) ?? 1) - 1;
        indegree.set(dependent, remaining);
        if (remaining === 0) next.push(dependent);
      }
    }
    ready = [...new Set(next)].filter((name) => !seen.has(name));
  }

  const scheduled = new Set(levels.flat());
  return {
    nodes,
    edges,
    levels,
    cycles,
    unscheduled: nodes.filter((name) => !scheduled.has(name)),
  };
}

function findCycles(nodes: string[], dependencies: Map<string, string[]>): string[][] {
  const color = new Map<string, number>();
  const stack: string[] = [];
  const seen = new Set<string>();
  const cycles: string[][] = [];

  const visit = (name: string): void => {
    color.set(name, 1);
    stack.push(name);
    for (const dependency of dependencies.get(name) ?? []) {
      const state = color.get(dependency) ?? 0;
      if (state === 1) {
        const start = stack.indexOf(dependency);
        const cycle = start >= 0 ? [...stack.slice(start), dependency] : [name, dependency];
        const label = cycleLabel(cycle);
        if (!seen.has(label)) {
          seen.add(label);
          cycles.push(cycle);
        }
      } else if (state === 0) {
        visit(dependency);
      }
    }
    stack.pop();
    color.set(name, 2);
  };

  for (const name of nodes) {
    if ((color.get(name) ?? 0) === 0) visit(name);
  }
  return cycles;
}

function cycleLabel(cycle: string[]): string {
  const body = cycle.slice(0, -1);
  if (body.length === 0) return cycle.join('→');
  let min = 0;
  for (let index = 1; index < body.length; index += 1) {
    if (body[index]! < body[min]!) min = index;
  }
  const rotated = body.slice(min).concat(body.slice(0, min));
  return rotated.join('→');
}

export function formatCycle(cycle: string[]): string {
  const body = cycle.slice(0, -1);
  if (body.length === 0) return cycle.join(' → ');
  let min = 0;
  for (let index = 1; index < body.length; index += 1) {
    if (body[index]! < body[min]!) min = index;
  }
  const rotated = body.slice(min).concat(body.slice(0, min), body[min]!);
  return rotated.join(' → ');
}
