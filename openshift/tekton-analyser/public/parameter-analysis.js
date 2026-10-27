export function analyseParameters(summary, runDigest) {
  const sites = collectSites(summary, runDigest);
  return [...duplicationFindings(sites, runDigest), ...embeddingFindings(sites)];
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

function duplicationFindings(sites, runDigest) {
  const groups = new Map();
  for (const item of sites) {
    if (!item.literal || skipLiteral(item.literal)) continue;
    const group = groups.get(item.literal) ?? [];
    group.push(item);
    groups.set(item.literal, group);
  }
  const findings = [];
  for (const [literal, group] of groups) {
    const distinct = group.filter((item, index) => group.findIndex((other) => samePlace(item, other)) === index);
    const copies = distinct.filter((item) => item.scope !== 'PipelineRun' || !distinct.some((other) => sameParameter(item, other)));
    const meaningful = copies.filter((item, index) => copies.some((other, otherIndex) => otherIndex !== index && !sameParameter(item, other)));
    if (meaningful.length < 2) continue;
    findings.push(duplicationFinding(literal, meaningful, runDigest));
  }
  return findings;
}

function duplicationFinding(literal, group, runDigest) {
  return {
    type: 'duplication',
    value: literal,
    parameters: duplicationParameters(group, runDigest),
    places: group.map(describePlace),
  };
}

function duplicationParameters(group, runDigest) {
  const seen = new Set();
  const parameters = [];
  for (const item of group) {
    if (seen.has(item.name)) continue;
    seen.add(item.name);
    const provided = (runDigest?.params ?? []).find((param) => param.name === item.name && param.value !== '');
    parameters.push({ name: item.name, value: provided ? provided.value : item.literal });
  }
  return parameters;
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

function samePlace(a, b) {
  return a.scope === b.scope && a.pipeline === b.pipeline && a.task === b.task && a.name === b.name && a.raw === b.raw;
}

function sameParameter(a, b) {
  if (a.name !== b.name) return false;
  const scopes = new Set([a.scope, b.scope]);
  if (!(scopes.has('PipelineRun') && scopes.has('pipeline default'))) return false;
  return !a.pipeline || !b.pipeline || a.pipeline === b.pipeline;
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
