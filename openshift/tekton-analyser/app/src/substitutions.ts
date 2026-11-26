export type Substitution =
  | { kind: 'param'; name: string; path?: string }
  | { kind: 'taskResult'; task: string; result: string; path?: string }
  | { kind: 'taskStatus'; task: string }
  | { kind: 'aggregateStatus' }
  | { kind: 'result'; name: string; field?: string }
  | { kind: 'workspace'; name: string; field?: string }
  | { kind: 'stepExit'; step: string }
  | { kind: 'stepResult'; step: string; result: string }
  | { kind: 'context'; path: string }
  | { kind: 'unknown'; raw: string };

const SUBSTITUTION = /(?<!\$)\$\(([^)]*)\)/g;

const CONTEXT_PATHS = new Set([
  'pipeline.name',
  'pipelineRun.name',
  'pipelineRun.namespace',
  'pipelineRun.uid',
  'pipelineTask.name',
  'pipelineTask.retries',
  'task.name',
  'task.retry-count',
  'taskRun.name',
  'taskRun.namespace',
  'taskRun.uid',
  'taskRun.retries',
]);

export function splitReference(body: string): string[] {
  const normalized = body
    .trim()
    .replace(/\[\s*['"]([^'"]+)['"]\s*\]/g, '.$1')
    .replace(/\[\s*(\*|\d+)\s*\]/g, '.$1');
  return normalized
    .split('.')
    .map((part) => part.trim())
    .filter((part) => part.length > 0);
}

export function parseSubstitution(body: string): Substitution {
  const parts = splitReference(body);
  if (parts.length === 0) return { kind: 'unknown', raw: body.trim() };

  if (parts[0] === 'params' && parts[1]) {
    return { kind: 'param', name: parts[1], path: parts[2] };
  }
  if (parts[0] === 'tasks' && parts[1] === 'status' && parts.length === 2) {
    return { kind: 'aggregateStatus' };
  }
  if (parts[0] === 'tasks' && parts[1] && parts[2] === 'status') {
    return { kind: 'taskStatus', task: parts[1] };
  }
  if (parts[0] === 'tasks' && parts[1] && parts[2] === 'results' && parts[3]) {
    return { kind: 'taskResult', task: parts[1], result: parts[3], path: parts[4] };
  }
  if (parts[0] === 'results' && parts[1]) {
    return { kind: 'result', name: parts[1], field: parts[2] };
  }
  if (parts[0] === 'workspaces' && parts[1]) {
    return { kind: 'workspace', name: parts[1], field: parts[2] };
  }
  if (parts[0] === 'steps' && parts[1] && parts[2] === 'exitCode') {
    return { kind: 'stepExit', step: parts[1] };
  }
  if (parts[0] === 'steps' && parts[1] && parts[2] === 'results' && parts[3]) {
    return { kind: 'stepResult', step: parts[1], result: parts[3] };
  }
  if (parts[0] === 'context' && parts.length > 1) {
    return { kind: 'context', path: parts.slice(1).join('.') };
  }
  return { kind: 'unknown', raw: body.trim() };
}

export function extractSubstitutions(input: string): Substitution[] {
  const found: Substitution[] = [];
  for (const match of input.matchAll(SUBSTITUTION)) {
    found.push(parseSubstitution(match[1] ?? ''));
  }
  return found;
}

export function isKnownContext(path: string): boolean {
  return CONTEXT_PATHS.has(path);
}

const WORKSPACE_FIELDS = new Set(['path', 'bound', 'claim', 'volume']);

export function isKnownWorkspaceField(field: string | undefined): boolean {
  return field !== undefined && WORKSPACE_FIELDS.has(field);
}
