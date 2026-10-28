import { parameterUses } from './task-view.js';

export function analyseParameters(summary, runDigest) {
  const sites = collectSites(summary, runDigest);
  const pipelineSites = sites.filter((item) => item.scope !== 'PipelineRun');
  return [
    ...consolidationFindings(sites),
    ...unusedFindings(summary, runDigest),
    ...embeddingFindings(pipelineSites),
  ];
}

function collectSites(summary, runDigest) {
  const sites = [];
  for (const pipeline of summary?.pipelines ?? []) {
    for (const param of pipeline.paramDefaults ?? []) {
      if (!param.name || !present(param.default)) continue;
      sites.push(site(pipeline, '', param.name, 'pipeline default', param.default));
    }
    for (const task of [...(pipeline.tasks ?? []), ...(pipeline.finally ?? [])]) {
      for (const param of task.content?.params ?? []) {
        const raw = present(param.value) ? param.value : param.default;
        if (!param.name || !present(raw)) continue;
        sites.push(site(pipeline, task.name, param.name, present(param.value) ? 'pipeline task' : 'task default', raw));
      }
    }
  }
  for (const param of runDigest?.params ?? []) {
    if (!param.name || !present(param.value)) continue;
    sites.push({
      pipeline: runDigest.pipeline || '',
      source: 'PipelineRun',
      task: '',
      name: param.name,
      scope: 'PipelineRun',
      raw: param.value,
      literal: literalValue(param.value),
    });
  }
  return sites;
}

function site(pipeline, task, name, scope, raw) {
  return {
    pipeline: pipeline.name,
    source: pipeline.source || '',
    task,
    name,
    scope,
    raw,
    literal: literalValue(raw),
  };
}

function consolidationFindings(sites) {
  const groups = new Map();
  for (const item of sites) {
    if (item.scope !== 'PipelineRun' || !item.literal || skipLiteral(item.literal)) continue;
    const group = groups.get(item.literal) ?? [];
    if (!group.some((other) => other.name === item.name)) group.push(item);
    groups.set(item.literal, group);
  }
  const findings = [];
  for (const [literal, group] of groups) {
    if (group.length < 2) continue;
    findings.push({
      type: 'consolidation',
      value: literal,
      parameters: group.map((item) => ({ name: item.name, value: item.literal })),
    });
  }
  return findings;
}

function unusedFindings(summary, runDigest) {
  const pipelines = summary?.pipelines ?? [];
  const runParams = runDigest?.params ?? [];
  const runNames = new Set(runParams.map((param) => param.name).filter(Boolean));
  const findings = [];
  const seen = new Set();
  const add = (name, value, sources) => {
    if (!name || seen.has(name)) return;
    seen.add(name);
    findings.push({ type: 'unused', name, value: value ?? '', sources });
  };
  for (const pipeline of pipelines) {
    for (const name of declaredPipelineParams(pipeline)) {
      if (passedToTask([pipeline], name)) continue;
      const provided = runParams.find((param) => param.name === name && param.value !== '');
      const fallback = (pipeline.paramDefaults ?? []).find((param) => param.name === name);
      const sources = [`pipeline ${pipeline.name}`];
      if (runNames.has(name)) sources.unshift('PipelineRun');
      add(name, provided ? provided.value : (fallback?.default ?? ''), sources);
    }
  }
  for (const param of runParams) {
    if (!param?.name || seen.has(param.name) || passedToTask(pipelines, param.name)) continue;
    add(param.name, param.value ?? '', ['PipelineRun']);
  }
  return findings;
}

function declaredPipelineParams(pipeline) {
  return [...new Set([
    ...(pipeline.params ?? []),
    ...((pipeline.paramDefaults ?? []).map((param) => param.name)),
  ].filter(Boolean))];
}

function passedToTask(pipelines, name) {
  if (!name || !pipelines.length) return false;
  return parameterUses(pipelines, [{ name, value: '' }]).some((item) => item.uses.length > 0);
}

function embeddingFindings(sites) {
  const findings = [];
  for (const host of sites) {
    const matches = sites
      .filter((source) => source !== host && source.literal.length >= 8 && host.raw.includes(source.literal) && host.raw.trim() !== source.literal)
      .filter((source) => !referencesParam(host.raw, source.name))
      .sort((a, b) => b.literal.length - a.literal.length);
    const covered = [];
    for (const source of matches) {
      if (covered.some((longer) => longer.includes(source.literal))) continue;
      covered.push(source.literal);
      findings.push({
        type: 'embedded',
        value: host.raw,
        places: [describePlace(host), describePlace(source)],
      });
    }
  }
  return findings;
}

function describePlace(item) {
  const file = item.source && item.source !== 'PipelineRun' ? ` in ${item.source}` : '';
  if (item.scope === 'PipelineRun') return `PipelineRun parameter ${item.name}`;
  if (item.scope === 'pipeline default') return `pipeline ${item.pipeline}${file}, parameter ${item.name} default`;
  if (item.scope === 'task default') return `pipeline ${item.pipeline}${file}, task ${item.task}, parameter ${item.name} default`;
  return `pipeline ${item.pipeline}${file}, task ${item.task}, parameter ${item.name}`;
}

function referencesParam(text, name) {
  return text.includes(`$(params.${name}`) || text.includes(`$(params['${name}']`) || text.includes(`$(params["${name}"]`);
}

function literalValue(value) {
  const text = String(value).trim();
  if (!text || text.includes('$(') || text.includes('${')) return '';
  return text;
}

function skipLiteral(value) {
  return value.length < 4 || /^(true|false|yes|no)$/i.test(value);
}

function present(value) {
  return value != null && value !== '';
}
