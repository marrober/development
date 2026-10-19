import { parseAllDocuments } from 'yaml';
import type {
  ChildReference,
  Condition,
  LegacyTaskRun,
  Matrix,
  ObjectMeta,
  Param,
  ParamSpec,
  PipelineRef,
  PipelineResource,
  PipelineRunResource,
  PipelineRunSpec,
  PipelineRunStatus,
  PipelineSpec,
  PipelineTask,
  ResultDecl,
  SkippedTask,
  Step,
  StepState,
  TaskRef,
  TaskResource,
  TaskRunResource,
  TaskRunSpec,
  TaskRunStatus,
  TaskSpec,
  TaskVolume,
  TektonResource,
  WhenExpression,
  WorkspaceBinding,
  WorkspaceDecl,
  WorkspacePipelineBinding,
} from './model.js';
import type { Issue, OtherResource } from './types.js';
import { asBoolean, asDuration, asNumber, asRecord, asString, asStringMap, hasOwn, recordsOf } from './util.js';

export interface ParseResult {
  resources: TektonResource[];
  others: OtherResource[];
  issues: Issue[];
}

export function parseManifest(text: string, source: string, format: 'yaml' | 'json'): ParseResult {
  if (format === 'json') {
    try {
      return flattenDocuments(JSON.parse(text) as unknown, source);
    } catch (error) {
      return {
        resources: [],
        others: [],
        issues: [loadIssue('invalid-json', error instanceof Error ? error.message : String(error), source)],
      };
    }
  }

  let documents;
  try {
    documents = parseAllDocuments(text);
  } catch (error) {
    return {
      resources: [],
      others: [],
      issues: [loadIssue('invalid-yaml', error instanceof Error ? error.message : String(error), source)],
    };
  }

  const result: ParseResult = { resources: [], others: [], issues: [] };
  documents.forEach((document, index) => {
    const docSource = documents.length > 1 ? `${source}#${index + 1}` : source;
    if (document.errors.length > 0) {
      result.issues.push(loadIssue('invalid-yaml', document.errors.map((error) => error.message).join('; '), docSource));
      return;
    }
    const data = document.toJS({ maxAliasCount: 50 }) as unknown;
    if (data == null) return;
    const parsed = flattenDocuments(data, docSource);
    result.resources.push(...parsed.resources);
    result.others.push(...parsed.others);
    result.issues.push(...parsed.issues);
  });
  return result;
}

function flattenDocuments(data: unknown, source: string): ParseResult {
  const result: ParseResult = { resources: [], others: [], issues: [] };
  const items = unwrap(data, source, result.issues);
  for (const item of items) {
    const record = asRecord(item);
    if (!record) {
      result.issues.push(loadIssue('invalid-document', 'Expected a Kubernetes resource object.', source));
      continue;
    }
    classify(record, source, result);
  }
  return result;
}

function unwrap(data: unknown, source: string, issues: Issue[]): unknown[] {
  if (data == null) return [];
  if (Array.isArray(data)) {
    return data.flatMap((item, index) => unwrap(item, `${source}[${index}]`, issues));
  }
  const record = asRecord(data);
  if (!record) {
    issues.push(loadIssue('invalid-document', 'Expected a Kubernetes resource object.', source));
    return [];
  }
  if (record.kind === 'List' && Array.isArray(record.items)) {
    return record.items.flatMap((item, index) => unwrap(item, `${source}#items[${index}]`, issues));
  }
  return [record];
}

function classify(record: Record<string, unknown>, source: string, result: ParseResult): void {
  const apiVersion = asString(record.apiVersion) ?? '';
  const kind = asString(record.kind) ?? '';
  const metadata = metadataOf(record.metadata);
  if (!apiVersion.startsWith('tekton.dev/')) {
    result.others.push({ apiVersion, kind: kind || 'Unknown', name: metadata.name, namespace: metadata.namespace, source, tekton: false });
    return;
  }

  const base = { apiVersion, metadata, source };
  if (kind === 'Task' || kind === 'ClusterTask') {
    result.resources.push({ ...base, kind, spec: taskSpecOf(record.spec) });
    return;
  }
  if (kind === 'Pipeline') {
    result.resources.push({ ...base, kind, spec: pipelineSpecOf(record.spec) });
    return;
  }
  if (kind === 'PipelineRun') {
    result.resources.push({
      ...base,
      kind,
      spec: pipelineRunSpecOf(record.spec),
      status: record.status === undefined ? undefined : pipelineRunStatusOf(record.status),
    });
    return;
  }
  if (kind === 'TaskRun') {
    result.resources.push({
      ...base,
      kind,
      spec: taskRunSpecOf(record.spec),
      status: record.status === undefined ? undefined : taskRunStatusOf(record.status),
    });
    return;
  }

  result.others.push({ apiVersion, kind: kind || 'Unknown', name: metadata.name, namespace: metadata.namespace, source, tekton: true });
}

function metadataOf(value: unknown): ObjectMeta {
  const metadata = asRecord(value) ?? {};
  return {
    name: asString(metadata.name),
    generateName: asString(metadata.generateName),
    namespace: asString(metadata.namespace),
    uid: asString(metadata.uid),
    labels: asStringMap(metadata.labels),
    annotations: asStringMap(metadata.annotations),
  };
}

function paramSpecOf(raw: Record<string, unknown>): ParamSpec {
  const type = asString(raw.type);
  const properties = asRecord(raw.properties);
  return {
    name: asString(raw.name) ?? '',
    type: type === 'string' || type === 'array' || type === 'object' ? type : undefined,
    description: asString(raw.description),
    hasDefault: hasOwn(raw, 'default') && raw.default != null,
    default: raw.default,
    enum: Array.isArray(raw.enum) ? raw.enum.filter((item): item is string => typeof item === 'string') : undefined,
    properties: properties ? Object.keys(properties) : undefined,
  };
}

function paramOf(raw: Record<string, unknown>): Param {
  return {
    name: asString(raw.name) ?? '',
    hasValue: hasOwn(raw, 'value'),
    value: raw.value,
  };
}

function paramsOf(value: unknown): Param[] {
  return recordsOf(value).map(paramOf);
}

function resultOf(raw: Record<string, unknown>): ResultDecl {
  const type = asString(raw.type);
  const properties = asRecord(raw.properties);
  return {
    name: asString(raw.name) ?? '',
    type: type === 'string' || type === 'array' || type === 'object' ? type : undefined,
    description: asString(raw.description),
    value: raw.value,
    properties: properties ? Object.keys(properties) : undefined,
  };
}

function workspaceDeclOf(raw: Record<string, unknown>): WorkspaceDecl {
  return {
    name: asString(raw.name) ?? '',
    description: asString(raw.description),
    optional: asBoolean(raw.optional) ?? false,
    mountPath: asString(raw.mountPath),
    readOnly: asBoolean(raw.readOnly),
  };
}

function whenOf(raw: Record<string, unknown>): WhenExpression {
  const values = Array.isArray(raw.values)
    ? raw.values.filter((item) => ['string', 'number', 'boolean'].includes(typeof item)).map((item) => String(item))
    : [];
  return {
    input: asString(raw.input),
    operator: asString(raw.operator),
    values,
    cel: asString(raw.cel),
  };
}

function envList(value: unknown): { name: string; value?: string }[] {
  return recordsOf(value).flatMap((item) => {
    const name = asString(item.name);
    if (!name) return [];
    return [{ name, value: asString(item.value) }];
  });
}

function stepOf(raw: Record<string, unknown>): Step {
  const ref = asRecord(raw.ref);
  const env = recordsOf(raw.env).map((item) => ({
    name: asString(item.name) ?? '',
    value: asString(item.value),
  }));
  return {
    name: asString(raw.name),
    displayName: asString(raw.displayName),
    image: asString(raw.image),
    command: Array.isArray(raw.command) ? raw.command.filter((item): item is string => typeof item === 'string') : undefined,
    args: Array.isArray(raw.args) ? raw.args.filter((item): item is string => typeof item === 'string') : undefined,
    script: asString(raw.script),
    workingDir: asString(raw.workingDir),
    env,
    timeout: asDuration(raw.timeout),
    onError: asString(raw.onError),
    refName: asString(ref?.name) ?? asString(ref?.resolver),
    when: recordsOf(raw.when).map(whenOf),
  };
}

function taskSpecOf(value: unknown): TaskSpec {
  const spec = asRecord(value) ?? {};
  const stepTemplate = asRecord(spec.stepTemplate);
  return {
    displayName: asString(spec.displayName),
    description: asString(spec.description),
    params: recordsOf(spec.params).map(paramSpecOf),
    results: recordsOf(spec.results).map(resultOf),
    workspaces: recordsOf(spec.workspaces).map(workspaceDeclOf),
    steps: recordsOf(spec.steps).map(stepOf),
    sidecars: recordsOf(spec.sidecars).map(stepOf),
    volumes: recordsOf(spec.volumes).map(taskVolumeOf),
    stepTemplateImage: asString(stepTemplate?.image),
    stepTemplateEnv: envList(stepTemplate?.env),
    hasResources: hasOwn(spec, 'resources') && spec.resources != null,
  };
}

function taskRefOf(value: unknown): TaskRef | undefined {
  const ref = asRecord(value);
  if (!ref) return undefined;
  return {
    name: asString(ref.name),
    kind: asString(ref.kind),
    apiVersion: asString(ref.apiVersion),
    resolver: asString(ref.resolver),
    params: paramsOf(ref.params),
  };
}

function pipelineRefOf(value: unknown): PipelineRef | undefined {
  const ref = asRecord(value);
  if (!ref) return undefined;
  return {
    name: asString(ref.name),
    apiVersion: asString(ref.apiVersion),
    resolver: asString(ref.resolver),
    params: paramsOf(ref.params),
  };
}

function matrixOf(value: unknown): Matrix | undefined {
  const matrix = asRecord(value);
  if (!matrix) return undefined;
  return {
    params: paramsOf(matrix.params),
    include: recordsOf(matrix.include).map((item) => ({
      name: asString(item.name),
      params: paramsOf(item.params),
    })),
  };
}

function pipelineTaskOf(raw: Record<string, unknown>): PipelineTask {
  return {
    name: asString(raw.name) ?? '',
    displayName: asString(raw.displayName),
    description: asString(raw.description),
    taskRef: taskRefOf(raw.taskRef),
    taskSpec: raw.taskSpec === undefined ? undefined : taskSpecOf(raw.taskSpec),
    pipelineRef: pipelineRefOf(raw.pipelineRef),
    pipelineSpec: raw.pipelineSpec === undefined ? undefined : pipelineSpecOf(raw.pipelineSpec),
    when: recordsOf(raw.when).map(whenOf),
    retries: asNumber(raw.retries),
    runAfter: Array.isArray(raw.runAfter) ? raw.runAfter.filter((item): item is string => typeof item === 'string') : [],
    params: paramsOf(raw.params),
    matrix: matrixOf(raw.matrix),
    workspaces: recordsOf(raw.workspaces).map(workspaceBindingOf),
    timeout: asDuration(raw.timeout),
    onError: asString(raw.onError),
    hasResources: hasOwn(raw, 'resources') && raw.resources != null,
  };
}

function workspaceBindingOf(raw: Record<string, unknown>): WorkspacePipelineBinding {
  return {
    name: asString(raw.name) ?? '',
    workspace: asString(raw.workspace),
    subPath: asString(raw.subPath),
  };
}

function pipelineSpecOf(value: unknown): PipelineSpec {
  const spec = asRecord(value) ?? {};
  return {
    displayName: asString(spec.displayName),
    description: asString(spec.description),
    tasks: recordsOf(spec.tasks).map(pipelineTaskOf),
    params: recordsOf(spec.params).map(paramSpecOf),
    workspaces: recordsOf(spec.workspaces).map((workspace) => ({
      name: asString(workspace.name) ?? '',
      description: asString(workspace.description),
      optional: asBoolean(workspace.optional) ?? false,
    })),
    results: recordsOf(spec.results).map(resultOf),
    finally: recordsOf(spec.finally).map(pipelineTaskOf),
    hasResources: hasOwn(spec, 'resources') && spec.resources != null,
  };
}

function taskVolumeOf(raw: Record<string, unknown>): TaskVolume {
  const secret = asRecord(raw.secret);
  const projected = asRecord(raw.projected);
  const secrets = [
    secretName(secret),
    ...recordsOf(projected?.sources).map((source) => secretName(asRecord(source.secret))),
  ].filter((name): name is string => Boolean(name));
  return {
    name: asString(raw.name) ?? '',
    kind: ['secret', 'configMap', 'persistentVolumeClaim', 'emptyDir', 'projected', 'csi', 'hostPath'].find((kind) => raw[kind] != null) ?? 'volume',
    secrets: [...new Set(secrets)],
    claim: asString(asRecord(raw.persistentVolumeClaim)?.claimName),
    configMap: asString(asRecord(raw.configMap)?.name),
  };
}

function secretName(raw: Record<string, unknown> | undefined): string | undefined {
  return asString(raw?.secretName) ?? asString(raw?.name);
}

function volumeKind(raw: Record<string, unknown>): string {
  const kinds = ['volumeClaimTemplate', 'persistentVolumeClaim', 'emptyDir', 'configMap', 'secret', 'projected', 'csi'];
  return kinds.find((kind) => raw[kind] != null) ?? 'unknown';
}

function workspaceVolumeOf(raw: Record<string, unknown>): WorkspaceBinding {
  return {
    name: asString(raw.name) ?? '',
    subPath: asString(raw.subPath),
    kind: volumeKind(raw),
  };
}

function pipelineRunSpecOf(value: unknown): PipelineRunSpec {
  const spec = asRecord(value) ?? {};
  const timeouts = asRecord(spec.timeouts);
  const template = asRecord(spec.taskRunTemplate);
  return {
    pipelineRef: pipelineRefOf(spec.pipelineRef),
    pipelineSpec: spec.pipelineSpec === undefined ? undefined : pipelineSpecOf(spec.pipelineSpec),
    params: paramsOf(spec.params),
    status: asString(spec.status),
    timeouts: timeouts
      ? {
          pipeline: asDuration(timeouts.pipeline),
          tasks: asDuration(timeouts.tasks),
          finally: asDuration(timeouts.finally),
        }
      : undefined,
    serviceAccountName: asString(template?.serviceAccountName) ?? asString(spec.serviceAccountName),
    workspaces: recordsOf(spec.workspaces).map(workspaceVolumeOf),
    taskRunSpecs: recordsOf(spec.taskRunSpecs).map((item) => ({
      pipelineTaskName: asString(item.pipelineTaskName),
      serviceAccountName: asString(item.serviceAccountName),
      timeout: asDuration(item.timeout),
    })),
  };
}

function conditionsOf(value: unknown): Condition[] {
  return recordsOf(value).map((condition) => ({
    type: asString(condition.type),
    status: asString(condition.status),
    reason: asString(condition.reason),
    message: asString(condition.message),
  }));
}

function stepStateOf(raw: Record<string, unknown>): StepState {
  const terminated = asRecord(raw.terminated);
  return {
    name: asString(raw.name),
    waitingReason: asString(asRecord(raw.waiting)?.reason),
    running: asRecord(raw.running) != null,
    terminated: terminated
      ? {
          exitCode: asNumber(terminated.exitCode),
          reason: asString(terminated.reason),
        }
      : undefined,
  };
}

function taskRunStatusOf(value: unknown): TaskRunStatus {
  const status = asRecord(value) ?? {};
  return {
    conditions: conditionsOf(status.conditions),
    podName: asString(status.podName),
    startTime: asString(status.startTime),
    completionTime: asString(status.completionTime),
    steps: recordsOf(status.steps).map(stepStateOf),
    results: recordsOf(status.results).map((result) => ({
      name: asString(result.name) ?? '',
      value: result.value,
    })),
  };
}

function pipelineRunStatusOf(value: unknown): PipelineRunStatus {
  const status = asRecord(value) ?? {};
  const taskRuns: Record<string, LegacyTaskRun> = {};
  const legacy = asRecord(status.taskRuns) ?? {};
  for (const [name, entry] of Object.entries(legacy)) {
    const record = asRecord(entry) ?? {};
    taskRuns[name] = {
      pipelineTaskName: asString(record.pipelineTaskName),
      status: record.status === undefined ? undefined : taskRunStatusOf(record.status),
      when: recordsOf(record.whenExpressions).map(whenOf),
    };
  }
  const results = recordsOf(status.results ?? status.pipelineResults);
  return {
    conditions: conditionsOf(status.conditions),
    startTime: asString(status.startTime),
    completionTime: asString(status.completionTime),
    finallyStartTime: asString(status.finallyStartTime),
    results: results.map((result) => ({ name: asString(result.name) ?? '', value: result.value })),
    pipelineSpec: status.pipelineSpec === undefined ? undefined : pipelineSpecOf(status.pipelineSpec),
    skippedTasks: recordsOf(status.skippedTasks).map(skippedOf),
    childReferences: recordsOf(status.childReferences).map(childOf),
    taskRuns,
  };
}

function skippedOf(raw: Record<string, unknown>): SkippedTask {
  return {
    name: asString(raw.name),
    reason: asString(raw.reason),
    when: recordsOf(raw.whenExpressions).map(whenOf),
  };
}

function childOf(raw: Record<string, unknown>): ChildReference {
  return {
    name: asString(raw.name),
    displayName: asString(raw.displayName),
    pipelineTaskName: asString(raw.pipelineTaskName),
    kind: asString(raw.kind),
    apiVersion: asString(raw.apiVersion),
    when: recordsOf(raw.whenExpressions).map(whenOf),
  };
}

function taskRunSpecOf(value: unknown): TaskRunSpec {
  const spec = asRecord(value) ?? {};
  return {
    params: paramsOf(spec.params),
    serviceAccountName: asString(spec.serviceAccountName),
    taskRef: taskRefOf(spec.taskRef),
    taskSpec: spec.taskSpec === undefined ? undefined : taskSpecOf(spec.taskSpec),
    status: asString(spec.status),
    timeout: asDuration(spec.timeout),
    workspaces: recordsOf(spec.workspaces).map(workspaceVolumeOf),
    retries: asNumber(spec.retries),
  };
}

function loadIssue(code: string, message: string, source: string): Issue {
  return { severity: 'error', code, message, source };
}

export function isTask(resource: TektonResource): resource is TaskResource {
  return resource.kind === 'Task' || resource.kind === 'ClusterTask';
}

export function isPipeline(resource: TektonResource): resource is PipelineResource {
  return resource.kind === 'Pipeline';
}

export function isPipelineRun(resource: TektonResource): resource is PipelineRunResource {
  return resource.kind === 'PipelineRun';
}

export function isTaskRun(resource: TektonResource): resource is TaskRunResource {
  return resource.kind === 'TaskRun';
}
