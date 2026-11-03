export function resourceId(resource) {
  if (!resource?.name) return '';
  return resource.namespace ? `${resource.namespace}/${resource.name}` : resource.name;
}

export function findResource(resources, id) {
  if (!id) return undefined;
  return (resources ?? []).find((resource) => resourceId(resource) === id);
}

export function normalizeSelection(selection) {
  return {
    pipeline: typeof selection?.pipeline === 'string' ? selection.pipeline : '',
    pipelineRun: typeof selection?.pipelineRun === 'string' ? selection.pipelineRun : '',
    triggerTemplate: typeof selection?.triggerTemplate === 'string' ? selection.triggerTemplate : '',
  };
}

export function prepareAnalysis(summary, selection = {}, dropped) {
  if (!summary) return { summary, digest: undefined, selection: normalizeSelection(selection) };
  const requested = normalizeSelection(selection);
  const chosen = {
    pipeline: findResource(summary.pipelines, requested.pipeline) ? requested.pipeline : '',
    pipelineRun: findResource(summary.pipelineRuns, requested.pipelineRun) ? requested.pipelineRun : '',
    triggerTemplate: findResource(summary.triggerTemplates, requested.triggerTemplate) ? requested.triggerTemplate : '',
  };
  const digest = composeRunDigest(summary, chosen, dropped || undefined);
  const pipelines = scopedPipelines(summary, chosen);
  const scoped = pipelines === (summary.pipelines ?? []) ? summary : { ...summary, pipelines };
  return { summary: scoped, digest, selection: chosen };
}

export function composeRunDigest(summary, selection, dropped) {
  const pipelines = summary?.pipelines ?? [];
  const chosen = findResource(pipelines, selection?.pipeline);
  const run = findResource(summary?.pipelineRuns, selection?.pipelineRun);
  const template = findResource(summary?.triggerTemplates, selection?.triggerTemplate);
  const base = run ? digestFromRun(run) : usableDigest(dropped);
  const target = chosen ?? pipelines.find((pipeline) => pipeline.name && pipeline.name === (base?.pipeline || template?.pipeline));
  const injected = template ? resolveTriggerParameters(template, target) : [];
  if (!chosen && !base && !template) return undefined;
  const params = mergeParams(injected, base?.params ?? []);
  const pipelineName = chosen?.name || base?.pipeline || template?.pipeline;
  if (!pipelineName && !params.length && !(base?.workspaces ?? []).length) return undefined;
  return {
    name: base?.name || template?.name || pipelineName,
    pipeline: pipelineName,
    params,
    workspaces: base?.workspaces ?? [],
  };
}

export function scopedPipelines(summary, selection) {
  const pipelines = summary?.pipelines ?? [];
  const chosen = findResource(pipelines, selection?.pipeline);
  return chosen ? [chosen] : pipelines;
}

export function resolveTriggerParameters(template, pipeline) {
  const defaults = new Map();
  for (const param of template?.params ?? []) {
    if (!param?.name || param.default == null || param.default === '') continue;
    defaults.set(param.name, String(param.default));
  }
  const resolved = new Map();
  const bindings = (template?.bindings ?? []).filter((binding) => binding?.name);
  const declared = pipelineParamNames(pipeline);
  if (!bindings.length) {
    const entries = declared.size
      ? [...defaults.entries()].filter(([name]) => declared.has(name))
      : [...defaults.entries()];
    return entries.map(([name, value]) => ({ name, value }));
  }
  for (const [name, value] of defaults) {
    if (declared.has(name)) resolved.set(name, value);
  }
  for (const binding of bindings) {
    resolved.set(binding.name, substituteTriggerParams(binding.value ?? '', defaults));
  }
  return [...resolved.entries()].map(([name, value]) => ({ name, value }));
}

export function substituteTriggerParams(value, defaults) {
  return String(value ?? '').replace(
    /\$\(tt\.params(?:\.([A-Za-z0-9_.-]+)|\[['"]([^'"]+)['"]\])\)/g,
    (match, dotted, bracket) => {
      const name = dotted || bracket;
      return defaults.has(name) ? defaults.get(name) : match;
    },
  );
}

function pipelineParamNames(pipeline) {
  return new Set([
    ...(pipeline?.params ?? []),
    ...((pipeline?.paramDefaults ?? []).map((param) => param.name).filter(Boolean)),
  ]);
}

function digestFromRun(run) {
  return {
    name: run.name,
    pipeline: run.pipeline,
    params: (Array.isArray(run.params) ? run.params : []).map((param) => ({
      name: param.name,
      value: param.value ?? '',
    })),
    workspaces: Array.isArray(run.workspaces) ? run.workspaces : [],
  };
}

function usableDigest(digest) {
  if (!digest || typeof digest !== 'object') return undefined;
  if (!digest.name && !digest.pipeline && !digest.params && !digest.workspaces) return undefined;
  return digest;
}

function mergeParams(base, override) {
  const values = new Map();
  for (const param of base ?? []) {
    if (param?.name) values.set(param.name, param.value ?? '');
  }
  for (const param of override ?? []) {
    if (param?.name) values.set(param.name, param.value ?? '');
  }
  return [...values.entries()].map(([name, value]) => ({ name, value }));
}
