export function parameterUses(pipelines, runParams) {
  return (runParams ?? []).map((param) => ({
    name: param.name,
    value: param.value,
    uses: (pipelines ?? []).flatMap((pipeline) => usesInPipeline(pipeline, param.name)),
  }));
}

export function annotationParts(text) {
  const parts = [];
  const pattern = /\$\(([^)]*)\)|\$\{(PARAM_[A-Za-z0-9_]+)\}|\$\{([A-Za-z_][A-Za-z0-9_]*)\}/g;
  let last = 0;
  for (const match of text.matchAll(pattern)) {
    const start = match.index ?? 0;
    if (start > last) parts.push({ type: 'text', text: text.slice(last, start) });
    if (match[1] != null) parts.push({ type: 'ref', raw: match[1], text: match[0] });
    else if (match[2] != null) parts.push({ type: 'shell', name: match[2], text: match[0] });
    else parts.push({ type: 'env', name: match[3] ?? '', text: match[0] });
    last = start + match[0].length;
  }
  if (last < text.length) parts.push({ type: 'text', text: text.slice(last) });
  return parts;
}

export function describeEnvVar(name, step, task, pipeline, runDigest) {
  const source = (step?.env ?? []).find((item) => item.name === name)?.value?.trim() ?? '';
  if (!source) return { reference: `\${${name}}`, value: 'No value is set.' };
  return { reference: `\${${name}}`, value: substituteExpressions(source, task, pipeline, runDigest) };
}

export function describeShellParam(name, step, task, pipeline, runDigest) {
  const envValue = (step?.env ?? []).find((item) => item.name === name)?.value?.trim() ?? '';
  if (isSingleParamExpression(envValue)) return describeLinkedParam(expressionBody(envValue), envValue, task, pipeline, runDigest);
  if (envValue) return { reference: `\${${name}}`, value: substituteExpressions(envValue, task, pipeline, runDigest) };
  const param = taskParamForShell(name, task);
  if (!param) return { reference: `\${${name}}`, value: 'No value is set.' };
  return describeLinkedParam(`params.${param}`, `$(params.${param})`, task, pipeline, runDigest);
}

export function referenceKind(raw) {
  if (paramReference(raw)) return 'param';
  const parts = splitReference(raw);
  if (parts[0] === 'workspaces') return 'workspace';
  return 'other';
}

export function describeReference(raw, task, pipeline, runDigest) {
  const param = paramReference(raw);
  if (param) return describeParam(param.name, param.path, task, pipeline, runDigest);
  const parts = splitReference(raw);
  if (parts[0] === 'workspaces' && parts[1]) return describeWorkspace(parts[1], parts[2], task, runDigest);
  return {
    title: `$(${raw})`,
    value: 'This reference is not a parameter or workspace.',
    because: '',
  };
}

function usesInPipeline(pipeline, pipelineParam) {
  const uses = [];
  for (const task of [...(pipeline.tasks ?? []), ...(pipeline.finally ?? [])]) {
    const fed = [];
    for (const binding of task.content?.params ?? []) {
      if (referencesParam(binding.value, pipelineParam) || referencesParam(binding.default, pipelineParam)) fed.push(binding.name);
    }
    if (!fed.length) continue;
    let referenced = false;
    for (const step of task.content?.steps ?? []) {
      for (const field of ['image', 'workingDir', 'script', 'command', 'args', 'env']) {
        const text = fieldText(step, field);
        if (!text) continue;
        if (fed.some((name) => referencesParam(text, name) || shellUsesTaskParam(text, name, step, task))) {
          uses.push({
            pipeline: pipeline.name,
            task: task.name,
            step: step.name,
            field: step.sidecar ? `sidecar ${field}` : field,
          });
          referenced = true;
        }
      }
    }
    if (!referenced) {
      uses.push({
        pipeline: pipeline.name,
        task: task.name,
        step: 'parameter',
        field: `passed as ${fed.join(', ')}`,
      });
    }
  }
  return uses;
}

function fieldText(step, field) {
  if (field === 'env') return (step.env ?? []).map((item) => `${item.name}=${item.value ?? ''}`).join('\n');
  if (field === 'command') return (step.command ?? []).join(' ');
  if (field === 'args') return (step.args ?? []).join(' ');
  return step[field] ?? '';
}

function describeParam(name, path, task, pipeline, runDigest) {
  const binding = (task.content?.params ?? []).find((param) => param.name === name);
  const source = present(binding?.value) ? binding.value : binding?.default;
  if (present(source)) {
    const substituted = substitutePipelineParams(source, pipeline, runDigest);
    const value = applyPath(substituted, path) ?? substituted;
    const refs = paramRefs(source);
    let because;
    if (refs.length) {
      const detail = refs.map((ref) => pipelineParamBecause(ref.name, pipeline, runDigest)).join(' ');
      because = `The task parameter ${name} is set from ${source}. ${detail}`.trim();
    } else if (present(binding?.value)) {
      because = `The pipeline task sets ${name} to ${binding.value}.`;
    } else {
      because = `The task default for ${name} is ${binding.default}.`;
    }
    return { title: paramTitle(name, path), value, because };
  }
  const resolved = pipelineParamValue(name, pipeline, runDigest);
  if (resolved) {
    return {
      title: paramTitle(name, path),
      value: applyPath(resolved.value, path) ?? resolved.value,
      because: resolved.because,
    };
  }
  return {
    title: paramTitle(name, path),
    value: 'No value is set.',
    because: `${name} has no value in the pipeline task or the PipelineRun.`,
  };
}

function describeWorkspace(name, field, task, runDigest) {
  const binding = (task.content?.workspaces ?? []).find((workspace) => workspace.name === name);
  const pipelineName = binding?.pipeline;
  const mount = binding?.mountPath || `/workspace/${name}`;
  const runWorkspace = (runDigest?.workspaces ?? []).find((workspace) => workspace.name === (pipelineName || name));
  const files = [
    ...(runWorkspace?.files ?? []).map((file) => `creates ${file.path} from ${file.source}`),
    ...(runWorkspace?.notes ?? []),
  ];
  if (!field || field === 'path') {
    const bound = pipelineName
      ? `Bound to pipeline workspace ${pipelineName}.`
      : 'This task workspace is not bound to a pipeline workspace.';
    return {
      title: `$(workspaces.${name}.path)`,
      value: mount,
      because: [bound, ...files].filter(Boolean).join(' '),
    };
  }
  if (field === 'bound') {
    return {
      title: `$(workspaces.${name}.bound)`,
      value: pipelineName ? 'true' : 'false',
      because: pipelineName
        ? `The task workspace is bound to pipeline workspace ${pipelineName}.`
        : 'The task workspace is not bound.',
    };
  }
  return {
    title: `$(workspaces.${name}.${field})`,
    value: files.length ? files.join(' ') : 'The PipelineRun does not say how this workspace field is set.',
    because: pipelineName ? `Bound to pipeline workspace ${pipelineName}.` : '',
  };
}

function substitutePipelineParams(text, pipeline, runDigest, seen = new Set()) {
  return text.replace(/\$\(([^)]*)\)/g, (match, raw) => {
    const ref = paramReference(raw);
    if (!ref) return match;
    const resolved = pipelineParamValue(ref.name, pipeline, runDigest, seen);
    if (!resolved) return match;
    return applyPath(resolved.value, ref.path) ?? match;
  });
}

function pipelineParamValue(name, pipeline, runDigest, seen = new Set()) {
  if (seen.has(name)) return null;
  const provided = (runDigest?.params ?? []).find((param) => param.name === name);
  if (provided && provided.value !== '') {
    return { value: provided.value, because: `The PipelineRun sets ${name} to ${provided.value}.` };
  }
  const fallback = (pipeline?.paramDefaults ?? []).find((param) => param.name === name);
  if (!present(fallback?.default)) return null;
  seen.add(name);
  const value = substitutePipelineParams(fallback.default, pipeline, runDigest, seen);
  return { value, because: `The pipeline default for ${name} is ${fallback.default}.` };
}

function pipelineParamBecause(name, pipeline, runDigest) {
  const resolved = pipelineParamValue(name, pipeline, runDigest);
  if (resolved) return resolved.because;
  return `The PipelineRun does not set ${name}.`;
}

function paramRefs(text) {
  const names = [];
  for (const match of String(text).matchAll(/\$\(([^)]*)\)/g)) {
    const ref = paramReference(match[1]);
    if (ref) names.push(ref);
  }
  return names;
}

function referencesParam(text, name) {
  return paramRefs(text).some((ref) => ref.name === name);
}

function shellUsesTaskParam(text, taskParamName, step, task) {
  for (const part of annotationParts(text)) {
    if (part.type !== 'shell') continue;
    const envValue = (step?.env ?? []).find((item) => item.name === part.name)?.value ?? '';
    if (envValue) {
      if (referencesParam(envValue, taskParamName)) return true;
      continue;
    }
    if (taskParamForShell(part.name, task) === taskParamName) return true;
  }
  return false;
}

function describeLinkedParam(raw, originalText, task, pipeline, runDigest) {
  const described = describeReference(raw, task, pipeline, runDigest);
  return { reference: linkedReference(raw, originalText, task), value: described.value };
}

function linkedReference(raw, originalText, task) {
  const ref = paramReference(raw);
  if (!ref) return originalText;
  const binding = (task.content?.params ?? []).find((param) => param.name === ref.name);
  const source = (present(binding?.value) ? binding.value : binding?.default ?? '').trim();
  if (isSingleParamExpression(source)) return source;
  return originalText;
}

function substituteExpressions(text, task, pipeline, runDigest) {
  return text.replace(/\$\(([^)]*)\)/g, (match, raw) => {
    if (referenceKind(raw) === 'other') return match;
    const described = describeReference(raw, task, pipeline, runDigest);
    if (!described.value || described.value === 'No value is set.' || described.value === 'This reference is not a parameter or workspace.') return match;
    return described.value;
  });
}

function taskParamForShell(shellName, task) {
  const target = compact(shellName.replace(/^PARAM_/, ''));
  return (task.content?.params ?? []).find((param) => compact(param.name) === target)?.name;
}

function compact(name) {
  return String(name).toLowerCase().replace(/[_-]/g, '');
}

function isSingleParamExpression(text) {
  const source = text.trim();
  return /^\$\([^)]*\)$/.test(source) && Boolean(paramReference(expressionBody(source)));
}

function expressionBody(text) {
  return text.trim().slice(2, -1);
}

function paramReference(raw) {
  const parts = splitReference(raw);
  if (parts[0] !== 'params' || !parts[1]) return null;
  return { name: parts[1], path: parts.slice(2) };
}

function splitReference(body) {
  const normalized = String(body)
    .trim()
    .replace(/\[\s*['"]([^'"]+)['"]\s*\]/g, '.$1')
    .replace(/\[\s*(\*|\d+)\s*\]/g, '.$1');
  return normalized.split('.').map((part) => part.trim()).filter(Boolean);
}

function paramTitle(name, path) {
  return `$(params.${[name, ...(path ?? [])].join('.')})`;
}

function applyPath(value, path) {
  if (!path?.length) return value;
  let current = value;
  for (const key of path) {
    if (typeof current === 'string') {
      try {
        current = JSON.parse(current);
      } catch {
        return null;
      }
    }
    if (current == null || typeof current !== 'object') return null;
    current = current[key];
  }
  if (current == null) return null;
  return typeof current === 'string' ? current : JSON.stringify(current);
}

function present(value) {
  return value != null && value !== '';
}
