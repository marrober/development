import { findResource, prepareAnalysis, resourceId } from './analysis-scope.js';
import { RUN_KEY, SELECTION_KEY, SUMMARY_KEY, readJson, readSessionToken, removeKey, writeJson, writeSessionToken } from './analysis-store.js';
import { resolveBoundParam } from './task-view.js';
const SVG_NS = 'http://www.w3.org/2000/svg';

let resultsNode;
let metaNode;
let summaryData;
let scopedSummary;
let selection = { pipeline: '', pipelineRun: '', triggerTemplate: '' };
let droppedDigest;
let droppedLabel = '';
let showData = false;
let showParamValues = false;
let showOutputs = false;
let showTaskParams = false;
let showRunParamValues = false;
let runDigest;
const selectedRunParams = new Set();

function boot() {
  resultsNode = document.querySelector('#results');
  metaNode = document.querySelector('#meta');
  if (!resultsNode || !metaNode) return;

  summaryData = readJson(SUMMARY_KEY);
  droppedDigest = readJson(RUN_KEY) ?? undefined;
  selection = { pipeline: '', pipelineRun: '', triggerTemplate: '', ...(readJson(SELECTION_KEY) ?? {}) };
  const summary = summaryData;

  if (!summary) {
    metaNode.textContent = 'Analyse a repository to see pipelines, tasks, and runs.';
    const empty = el('p', 'empty', 'Nothing to show yet.');
    const link = document.createElement('a');
    link.href = '/';
    link.textContent = 'Start an analysis';
    empty.append(document.createTextNode(' '), link, document.createTextNode('.'));
    resultsNode.append(empty);
  } else {
    renderSummary(summary);
  }
}

function renderSummary(summary) {
  syncPrepared();
  const counts = summary.counts ?? {};
  metaNode.textContent = `${summary.repository} · ${summary.contextDir}`;
  resultsNode.append(renderControls());
  resultsNode.append(renderRunDrop());
  updateRunPresentation();
  const bar = el('div', 'summary-bar');
  bar.append(
    count(counts.tasks ?? 0, 'task', 'tasks'),
    count(counts.pipelines ?? 0, 'pipeline', 'pipelines'),
    count(counts.pipelineRuns ?? 0, 'pipeline run', 'pipeline runs'),
    count(counts.taskRuns ?? 0, 'task run', 'task runs'),
    count(counts.triggerTemplates ?? summary.triggerTemplates?.length ?? 0, 'trigger template', 'trigger templates'),
  );
  resultsNode.append(bar);

  if (summary.issues?.length) {
    const issues = card('Issues');
    for (const issue of summary.issues) {
      issues.append(el('p', 'task-line', `${issue.severity}: ${issue.message}`));
    }
    resultsNode.append(issues);
  }

  resultsNode.append(renderPipelines(scopedSummary?.pipelines ?? []));
  resultsNode.append(renderWorkspaces(scopedSummary?.pipelines ?? []));
  resultsNode.append(renderTasks(tasksInScope()));
  resultsNode.append(renderRuns('Pipeline runs', summary.pipelineRuns ?? [], 'pipeline', 'pipeline-runs'));
  resultsNode.append(renderRuns('Task runs', summary.taskRuns ?? [], 'task', 'task-runs'));

  const total = (counts.tasks ?? 0) + (counts.pipelines ?? 0) + (counts.pipelineRuns ?? 0) + (counts.taskRuns ?? 0);
  if (total === 0 && !summary.issues?.length) {
    resultsNode.append(el('p', 'empty', 'No Tekton resources were found in that directory.'));
  }
}

function renderRunDrop() {
  const box = el('section', 'card run-card is-empty');
  box.id = 'run-drop';
  const details = document.createElement('details');
  details.className = 'collapsible';
  details.open = true;
  const summary = document.createElement('summary');
  summary.id = 'run-summary';
  summary.textContent = 'Drop a PipelineRun file';
  details.append(summary);
  const body = el('div', 'collapsible-body');
  const target = el('div', 'run-target');
  target.tabIndex = 0;
  const input = document.createElement('input');
  input.className = 'run-file';
  input.type = 'file';
  input.accept = '.yaml,.yml,.json,application/yaml,application/json';
  input.addEventListener('click', (event) => event.stopPropagation());
  input.addEventListener('change', () => {
    const file = input.files?.[0];
    if (file) void readRunFile(file);
    input.value = '';
  });
  target.append(el('p', 'run-drop-label', 'Drop a PipelineRun file here'));
  target.append(input);
  target.addEventListener('click', () => input.click());
  target.addEventListener('keydown', (event) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      input.click();
    }
  });
  const status = el('p', 'run-drop-status', 'YAML or JSON. Parameter values are read from the file.');
  status.id = 'run-drop-status';
  const params = el('div', 'run-params');
  params.id = 'run-params';
  body.append(target, status, params);
  details.append(body);
  box.append(details);

  box.addEventListener('dragover', (event) => {
    event.preventDefault();
    box.classList.add('is-dropping');
  });
  box.addEventListener('dragleave', (event) => {
    if (!box.contains(event.relatedTarget)) box.classList.remove('is-dropping');
  });
  box.addEventListener('drop', (event) => {
    event.preventDefault();
    box.classList.remove('is-dropping');
    const file = event.dataTransfer?.files?.[0];
    if (file) void readRunFile(file);
    else setRunStatus('Drop a PipelineRun file.');
  });
  return box;
}

async function readRunFile(file) {
  const status = document.querySelector('#run-drop-status');
  if (status) status.textContent = `Reading ${file.name}…`;
  try {
    const manifest = await file.text();
    const response = await fetch('/api/pipelinerun', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ manifest }),
    });
    const body = await response.json();
    if (!response.ok || !body.ok) {
      setRunStatus(body.error || 'Could not read that PipelineRun.');
      return;
    }
    droppedDigest = body.digest;
    droppedLabel = file.name;
    writeJson(RUN_KEY, droppedDigest);
    selection.pipelineRun = '';
    syncSelects();
    applyScope();
  } catch {
    setRunStatus('Could not reach the analyser.');
  }
}

function setRunStatus(message) {
  droppedDigest = undefined;
  droppedLabel = '';
  removeKey(RUN_KEY);
  applyScope();
  const status = document.querySelector('#run-drop-status');
  if (status) status.textContent = message;
}

function syncPrepared() {
  const prepared = prepareAnalysis(summaryData, selection, droppedDigest);
  selection = prepared.selection;
  scopedSummary = prepared.summary ?? summaryData;
  runDigest = prepared.digest;
  writeJson(SELECTION_KEY, selection);
}

function applyScope() {
  syncPrepared();
  updateRunPresentation();
  refreshPipelines();
  refreshWorkspaces();
  refreshTasks();
  refreshRunLists();
}

function updateRunPresentation() {
  const box = document.querySelector('#run-drop');
  const summary = document.querySelector('#run-summary');
  const status = document.querySelector('#run-drop-status');
  const params = document.querySelector('#run-params');
  if (!box || !summary || !status || !params) return;
  const sourced = Boolean(selection.pipelineRun || selection.triggerTemplate || droppedDigest);
  if (!sourced || !runDigest) {
    box.classList.add('is-empty');
    box.classList.remove('is-loaded');
    summary.textContent = 'Drop a PipelineRun file';
    status.textContent = 'YAML or JSON. Parameter values are read from the file, or choose a PipelineRun or trigger template above.';
    params.replaceChildren();
    selectedRunParams.clear();
    return;
  }
  box.classList.add('is-loaded');
  box.classList.remove('is-empty');
  summary.textContent = 'Pipeline parameters';
  const label = parameterSourceLabel();
  status.textContent = runDigest.params?.length ? label : `${label} has no parameters.`;
  const previous = new Set(selectedRunParams);
  selectedRunParams.clear();
  params.replaceChildren(...(runDigest.params ?? []).map((param) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'run-param';
    const selected = previous.has(param.name);
    if (selected) selectedRunParams.add(param.name);
    button.classList.toggle('is-selected', selected);
    button.setAttribute('aria-pressed', String(selected));
    button.append(el('span', 'run-param-name', param.name), el('span', 'run-param-value', param.value));
    button.addEventListener('click', () => {
      const next = !selectedRunParams.has(param.name);
      if (next) selectedRunParams.add(param.name);
      else selectedRunParams.delete(param.name);
      button.classList.toggle('is-selected', next);
      button.setAttribute('aria-pressed', String(next));
      refreshPipelines();
    });
    return button;
  }));
}

function parameterSourceLabel() {
  const parts = [];
  const run = findResource(summaryData?.pipelineRuns, selection.pipelineRun);
  const template = findResource(summaryData?.triggerTemplates, selection.triggerTemplate);
  if (run) parts.push(`PipelineRun ${titled(run.namespace, run.name)}`);
  if (template) parts.push(`trigger template ${titled(template.namespace, template.name)}`);
  if (!run && droppedDigest) parts.push(droppedLabel || droppedDigest.name || 'PipelineRun file');
  return parts.join(' · ') || 'Parameter values';
}

function renderControls() {
  const section = el('section', 'card scope-card');
  section.append(el('h2', null, 'Analysis scope'));
  const row = el('div', 'scope-row');
  const refresh = document.createElement('button');
  refresh.type = 'button';
  refresh.id = 'refresh-analysis';
  refresh.className = 'scope-refresh';
  refresh.textContent = 'Refresh from repository';
  refresh.disabled = !summaryData?.repository;
  refresh.addEventListener('click', () => { void refreshAnalysis(); });
  row.append(
    refresh,
    scopeSelect('scope-pipeline', 'Pipeline', summaryData?.pipelines ?? [], selection.pipeline, 'All pipelines', 'pipeline'),
    scopeSelect('scope-pipelinerun', 'PipelineRun', summaryData?.pipelineRuns ?? [], selection.pipelineRun, 'No PipelineRun', 'pipelineRun'),
    scopeSelect('scope-trigger', 'Trigger template', summaryData?.triggerTemplates ?? [], selection.triggerTemplate, 'No trigger template', 'triggerTemplate'),
  );
  const status = el('p', 'status');
  status.id = 'refresh-status';
  status.hidden = true;
  const error = el('p', 'error');
  error.id = 'refresh-error';
  error.hidden = true;
  error.setAttribute('role', 'alert');
  const auth = el('div', 'refresh-auth');
  auth.id = 'refresh-auth';
  auth.hidden = true;
  const tokenLabel = el('label', 'scope-field');
  tokenLabel.htmlFor = 'refresh-token';
  tokenLabel.append(document.createTextNode('Git token'));
  const token = document.createElement('input');
  token.id = 'refresh-token';
  token.type = 'password';
  token.maxLength = 4096;
  token.autocomplete = 'new-password';
  token.spellcheck = false;
  tokenLabel.append(token);
  const retry = document.createElement('button');
  retry.type = 'button';
  retry.id = 'refresh-retry';
  retry.textContent = 'Refresh with token';
  retry.addEventListener('click', () => { void refreshAnalysis(); });
  auth.append(tokenLabel, el('p', 'hint', 'Replaces the token kept for this browser session. It is not saved permanently or put in a cookie.'), retry);
  section.append(
    row,
    el('p', 'hint', 'The selected pipeline and PipelineRun are used for this analysis. A trigger template fills in parameters that the PipelineRun does not set.'),
    status,
    error,
    auth,
  );
  return section;
}

function scopeSelect(id, label, resources, value, emptyLabel, key) {
  const field = el('label', 'scope-field');
  field.append(document.createTextNode(label));
  const select = document.createElement('select');
  select.id = id;
  select.dataset.scope = key;
  if (!resources.length) {
    const option = document.createElement('option');
    option.value = '';
    option.textContent = 'None in this repository';
    select.append(option);
    select.disabled = true;
  } else {
    const empty = document.createElement('option');
    empty.value = '';
    empty.textContent = emptyLabel;
    select.append(empty);
    for (const resource of resources) {
      const option = document.createElement('option');
      option.value = resourceId(resource);
      option.textContent = titled(resource.namespace, resource.name);
      select.append(option);
    }
    select.value = [...select.options].some((option) => option.value === value) ? value : '';
    select.addEventListener('change', () => {
      selection[key] = select.value;
      if (key === 'pipelineRun' && select.value) {
        droppedDigest = undefined;
        droppedLabel = '';
        removeKey(RUN_KEY);
      }
      applyScope();
    });
  }
  field.append(select);
  return field;
}

function syncSelects() {
  for (const [id, value] of [
    ['scope-pipeline', selection.pipeline],
    ['scope-pipelinerun', selection.pipelineRun],
    ['scope-trigger', selection.triggerTemplate],
  ]) {
    const select = document.querySelector(`#${id}`);
    if (select && [...select.options].some((option) => option.value === value)) select.value = value;
  }
}

async function refreshAnalysis() {
  if (!summaryData?.repository) return;
  const status = document.querySelector('#refresh-status');
  const error = document.querySelector('#refresh-error');
  const auth = document.querySelector('#refresh-auth');
  const tokenInput = document.querySelector('#refresh-token');
  const button = document.querySelector('#refresh-analysis');
  const retry = document.querySelector('#refresh-retry');
  if (error) {
    error.hidden = true;
    error.textContent = '';
  }
  if (status) {
    status.hidden = false;
    status.textContent = 'Cloning repository…';
  }
  if (button) button.disabled = true;
  if (retry) retry.disabled = true;
  const typedToken = auth && !auth.hidden ? (tokenInput?.value ?? '') : '';
  if (typedToken) writeSessionToken(typedToken);
  const token = typedToken || readSessionToken();
  try {
    const response = await fetch('/api/analyse', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        repository: summaryData.repository,
        contextDir: summaryData.contextDir === '.' ? '' : (summaryData.contextDir ?? ''),
        token,
      }),
    });
    const body = await response.json();
    if (!response.ok || !body.ok) {
      showRefreshError(body.error || 'Could not refresh that repository.');
      return;
    }
    if (tokenInput) tokenInput.value = '';
    summaryData = body.summary;
    writeJson(SUMMARY_KEY, summaryData);
    selection = retainSelection(selection, summaryData);
    writeJson(SELECTION_KEY, selection);
    rerender();
    const nextStatus = document.querySelector('#refresh-status');
    if (nextStatus) {
      nextStatus.hidden = false;
      nextStatus.textContent = 'Reloaded from the repository.';
    }
  } catch {
    showRefreshError('Could not reach the analyser.');
  } finally {
    const nextButton = document.querySelector('#refresh-analysis');
    if (nextButton) nextButton.disabled = !summaryData?.repository;
    const nextRetry = document.querySelector('#refresh-retry');
    if (nextRetry) nextRetry.disabled = false;
  }
}

function showRefreshError(message) {
  const status = document.querySelector('#refresh-status');
  const error = document.querySelector('#refresh-error');
  const auth = document.querySelector('#refresh-auth');
  if (status) status.hidden = true;
  if (error) {
    error.hidden = false;
    error.textContent = message;
  }
  if (auth) auth.hidden = false;
}

function retainSelection(current, summary) {
  return {
    pipeline: findResource(summary?.pipelines, current.pipeline) ? current.pipeline : '',
    pipelineRun: findResource(summary?.pipelineRuns, current.pipelineRun) ? current.pipelineRun : '',
    triggerTemplate: findResource(summary?.triggerTemplates, current.triggerTemplate) ? current.triggerTemplate : '',
  };
}

function rerender() {
  if (!resultsNode || !metaNode) return;
  resultsNode.replaceChildren();
  renderSummary(summaryData);
}

function scopeIsActive() {
  return Boolean(selection.pipeline || selection.pipelineRun || selection.triggerTemplate);
}

function tasksInScope() {
  const tasks = summaryData?.tasks ?? [];
  if (!scopeIsActive()) return tasks;
  return tasks.filter((task) => pipelineTaskUses(scopedSummary, runDigest, task).length);
}

function refreshRunLists() {
  const pipelines = document.querySelector('#pipeline-runs');
  if (pipelines && summaryData) pipelines.replaceWith(renderRuns('Pipeline runs', summaryData.pipelineRuns ?? [], 'pipeline', 'pipeline-runs'));
  const taskRuns = document.querySelector('#task-runs');
  if (taskRuns && summaryData) taskRuns.replaceWith(renderRuns('Task runs', summaryData.taskRuns ?? [], 'task', 'task-runs'));
}

function refreshPipelines() {
  const current = document.querySelector('#pipelines');
  if (!current || !summaryData) return;
  current.replaceWith(renderPipelines(scopedSummary?.pipelines ?? []));
}

function refreshWorkspaces() {
  const current = document.querySelector('#workspaces');
  if (!current || !summaryData) return;
  const open = current.querySelector('details')?.open ?? true;
  current.replaceWith(renderWorkspaces(scopedSummary?.pipelines ?? [], open));
}

function refreshTasks() {
  const current = document.querySelector('#tasks');
  if (!current || !summaryData) return;
  const open = current.querySelector('details')?.open ?? true;
  current.replaceWith(renderTasks(tasksInScope(), open));
}

function renderPipelines(pipelines) {
  const section = card('Pipelines');
  section.id = 'pipelines';
  if (!pipelines.length) {
    section.append(el('p', 'empty', 'No pipelines in this directory.'));
    return section;
  }
  const toolbar = el('div', 'pipeline-toolbar');
  const switches = el('div', 'pipeline-switches');
  switches.append(workspacesSwitch(), parameterValuesSwitch(), outputsSwitch());
  toolbar.append(switches);
  if (runDigest?.params?.length) toolbar.append(clearParametersButton());
  section.append(toolbar);
  pipelines.forEach((pipeline, index) => {
    const block = el('article', 'resource');
    block.append(el('h3', null, titled(pipeline.namespace, pipeline.name)));
    if (pipeline.description) block.append(el('p', null, pipeline.description));
    if (pipeline.source) block.append(el('p', null, pipeline.source));
    if (showData) block.append(pipelineNote());
    block.append(flowDiagram(pipeline, index));
    section.append(block);
  });
  return section;
}

function workspacesSwitch() {
  const label = document.createElement('label');
  label.className = 'data-switch pipeline-data-switch';
  const input = document.createElement('input');
  input.id = 'data-switch';
  input.type = 'checkbox';
  input.checked = showData;
  input.addEventListener('change', (event) => {
    showData = event.target.checked;
    refreshPipelines();
  });
  label.append(input, document.createTextNode('Workspaces'));
  return label;
}

function parameterValuesSwitch() {
  const label = document.createElement('label');
  label.className = 'data-switch pipeline-data-switch';
  const input = document.createElement('input');
  input.type = 'checkbox';
  input.checked = showParamValues;
  input.addEventListener('change', (event) => {
    showParamValues = event.target.checked;
    refreshPipelines();
  });
  label.append(input, document.createTextNode('Display parameter values'));
  return label;
}

function outputsSwitch() {
  const label = document.createElement('label');
  label.className = 'data-switch pipeline-data-switch';
  const input = document.createElement('input');
  input.type = 'checkbox';
  input.checked = showOutputs;
  input.addEventListener('change', (event) => {
    showOutputs = event.target.checked;
    refreshPipelines();
  });
  label.append(input, document.createTextNode('Outputs'));
  return label;
}

function clearParametersButton() {
  const clear = document.createElement('button');
  clear.type = 'button';
  clear.className = 'param-clear';
  clear.textContent = 'Clear selected parameters';
  clear.disabled = selectedRunParams.size === 0;
  clear.addEventListener('click', () => {
    selectedRunParams.clear();
    for (const button of document.querySelectorAll('.run-param.is-selected')) {
      button.classList.remove('is-selected');
      button.setAttribute('aria-pressed', 'false');
    }
    refreshPipelines();
  });
  return clear;
}

function selectedParamsByTask(pipeline) {
  const names = new Map();
  if (!selectedRunParams.size) return names;
  for (const task of [...(pipeline.tasks ?? []), ...(pipeline.finally ?? [])]) {
    const matched = [...selectedRunParams].filter((name) => taskReferencesParam(task, name));
    if (matched.length) names.set(task.name, matched);
  }
  return names;
}

function taskReferencesParam(task, name) {
  const text = JSON.stringify({ content: task.content, mounts: task.mounts });
  return text.includes(`$(params.${name}`)
    || text.includes(`$(params['${name}']`)
    || text.includes(`$(params["${name}"]`);
}

function paramCaptionLines(names) {
  return names.map((name) => {
    if (!showParamValues) return { name, value: '' };
    const value = runDigest?.params?.find((param) => param.name === name)?.value ?? '';
    return { name, value };
  });
}

function captionText(line) {
  if (line.kind === 'data') return line.text;
  if (line.kind === 'output') return `${line.location} : ${line.name}`;
  return line.value ? `${line.name} : ${line.value}` : line.name;
}

function flowDiagram(pipeline, index) {
  const wrap = el('div', 'pipeline-flow');
  const tasks = pipeline.tasks ?? [];
  const finallyTasks = pipeline.finally ?? [];
  if (!tasks.length && !finallyTasks.length) {
    wrap.append(el('p', 'empty', 'This pipeline has no tasks to diagram.'));
    return wrap;
  }

  const levels = (pipeline.order?.length ? pipeline.order : [tasks.map((task) => task.name)])
    .map((level) => level.filter(Boolean));
  const placed = new Set(levels.flat());
  const missing = tasks.map((task) => task.name).filter((name) => name && !placed.has(name));
  if (missing.length) levels.push(missing);
  const drawnLevels = levels.filter((level) => level.length);
  const finallyNames = finallyTasks.map((task) => task.name).filter(Boolean);
  const taskByName = new Map();
  const refs = new Map();
  for (const task of [...tasks, ...finallyTasks]) {
    taskByName.set(task.name, task);
    refs.set(task.name, task.ref ?? '');
  }

  const paramsByTask = selectedParamsByTask(pipeline);
  const names = [...drawnLevels.flat(), ...finallyNames];
  const longest = Math.max(...names.map((name) => {
    const ref = refs.get(name) ?? '';
    const detail = finallyNames.includes(name) && ref ? `finally · ${ref}` : ref;
    const captions = taskCaptions(taskByName.get(name), paramCaptionLines(paramsByTask.get(name) ?? []));
    const mounted = captions.lines.reduce((size, line) => Math.max(size, captionText(line).length), 0);
    return Math.max(name.length, detail.length, mounted);
  }));
  const captionHeight = Math.max(0, ...names.map((name) => taskCaptions(taskByName.get(name), paramCaptionLines(paramsByTask.get(name) ?? [])).lines.length)) * 14 + 8;
  const captionSpace = captionHeight > 8 ? captionHeight : 0;
  const model = arrangeTasks(drawnLevels, pipeline.edges ?? [], finallyNames, tasks, {
    nodeWidth: Math.min(showParamValues || showOutputs ? 420 : 280, Math.max(156, longest * 7.2 + 32)),
    captionHeight: captionSpace,
  });
  wrap.style.maxHeight = `min(75vh, ${520 + captionSpace}px)`;

  const svg = document.createElementNS(SVG_NS, 'svg');
  svg.setAttribute('viewBox', `0 0 ${model.width} ${model.height}`);
  svg.setAttribute('width', String(model.width));
  svg.setAttribute('height', String(model.height));
  svg.setAttribute('role', 'img');
  svg.setAttribute('aria-label', flowLabel(pipeline.name, model.levels, finallyNames));
  svg.classList.add('flow-svg');

  const markerId = `arrow-${index}`;
  const defs = document.createElementNS(SVG_NS, 'defs');
  const marker = document.createElementNS(SVG_NS, 'marker');
  marker.setAttribute('id', markerId);
  marker.setAttribute('viewBox', '0 0 8 8');
  marker.setAttribute('refX', '7');
  marker.setAttribute('refY', '4');
  marker.setAttribute('markerWidth', '7');
  marker.setAttribute('markerHeight', '7');
  marker.setAttribute('orient', 'auto');
  const head = document.createElementNS(SVG_NS, 'path');
  head.setAttribute('d', 'M0,0 L8,4 L0,8 Z');
  head.setAttribute('fill', '#4da3ff');
  marker.append(head);
  defs.append(marker);
  svg.append(defs);

  for (const route of model.routes) {
    const path = document.createElementNS(SVG_NS, 'path');
    path.setAttribute('d', route.d);
    path.setAttribute('class', route.dashed ? 'flow-edge flow-skip' : 'flow-edge');
    path.setAttribute('marker-end', `url(#${markerId})`);
    svg.append(path);
  }

  for (const [name, position] of model.positions) {
    const group = document.createElementNS(SVG_NS, 'g');
    group.setAttribute('class', 'flow-task');
    group.style.cursor = 'pointer';
    group.addEventListener('click', () => openTask(pipeline.name, name));
    const rect = document.createElementNS(SVG_NS, 'rect');
    rect.setAttribute('x', String(position.x));
    rect.setAttribute('y', String(position.y));
    rect.setAttribute('width', String(model.nodeWidth));
    rect.setAttribute('height', String(model.nodeHeight));
    rect.setAttribute('rx', '12');
    rect.setAttribute('class', position.finally ? 'flow-node flow-finally' : 'flow-node');
    group.append(rect);

    const title = document.createElementNS(SVG_NS, 'title');
    const ref = refs.get(name);
    title.textContent = `Open ${name}`;
    group.append(title);

    const label = document.createElementNS(SVG_NS, 'text');
    label.setAttribute('x', String(position.x + model.nodeWidth / 2));
    label.setAttribute('y', String(position.y + (ref ? 24 : 34)));
    label.setAttribute('text-anchor', 'middle');
    label.setAttribute('class', 'flow-label');
    label.textContent = fit(name, model.nodeWidth);
    group.append(label);

    if (ref) {
      const detail = document.createElementNS(SVG_NS, 'text');
      detail.setAttribute('x', String(position.x + model.nodeWidth / 2));
      detail.setAttribute('y', String(position.y + 42));
      detail.setAttribute('text-anchor', 'middle');
      detail.setAttribute('class', 'flow-ref');
      detail.textContent = fit(position.finally ? `finally · ${ref}` : ref, model.nodeWidth);
      group.append(detail);
    }
    const captions = taskCaptions(taskByName.get(name), paramCaptionLines(paramsByTask.get(name) ?? []));
    captions.lines.forEach((line, lineIndex) => {
      const mounted = document.createElementNS(SVG_NS, 'text');
      mounted.setAttribute('x', String(position.x + model.nodeWidth / 2));
      mounted.setAttribute('y', String(position.y + model.nodeHeight + 16 + lineIndex * 14));
      mounted.setAttribute('text-anchor', 'middle');
      mounted.setAttribute('class', line.kind === 'param' ? 'flow-param' : line.kind === 'output' ? 'flow-output' : 'flow-data');
      if (line.kind === 'param' && line.value) {
        const fitted = fit(`${line.name} : ${line.value}`, model.nodeWidth);
        const prefix = `${line.name} : `;
        mounted.append(document.createTextNode(fitted.startsWith(prefix) ? line.name : fitted));
        if (fitted.startsWith(prefix)) {
          mounted.append(document.createTextNode(' : '));
          const value = document.createElementNS(SVG_NS, 'tspan');
          value.setAttribute('class', 'flow-param-value');
          value.textContent = fitted.slice(prefix.length);
          mounted.append(value);
        }
      } else if (line.kind === 'output') {
        const prefix = `${line.location} : `;
        const fitted = fit(`${prefix}${line.name}`, model.nodeWidth);
        mounted.append(document.createTextNode(fitted.startsWith(prefix) ? line.location : fitted));
        if (fitted.startsWith(prefix)) {
          mounted.append(document.createTextNode(' : '));
          const file = document.createElementNS(SVG_NS, 'tspan');
          file.setAttribute('class', 'flow-output-file');
          file.textContent = fitted.slice(prefix.length);
          mounted.append(file);
        }
      } else {
        mounted.textContent = fit(line.kind === 'param' ? line.name : line.text, model.nodeWidth);
      }
      group.append(mounted);
    });
    svg.append(group);
  }

  wrap.append(svg);
  return wrap;
}

export function arrangeTasks(levels, edges, finallyNames = [], tasks = [], metrics = {}) {
  const nodeWidth = metrics.nodeWidth ?? 180;
  const nodeHeight = 58;
  const gapX = 120;
  const gapY = 44;
  const pad = 28;
  const pitch = nodeHeight + gapY + (metrics.captionHeight ?? 0);
  const columnOf = new Map();
  levels.forEach((level, column) => {
    for (const name of level) columnOf.set(name, column);
  });
  for (const name of finallyNames) columnOf.set(name, levels.length);
  const dagEdges = (edges.length
    ? edges.filter((edge) => !edge.via || edge.via.includes('runAfter'))
    : tasks.flatMap((task) => (task.runAfter ?? []).map((from) => ({ from, to: task.name, via: ['runAfter'] }))))
    .filter((edge) => columnOf.has(edge.from) && columnOf.has(edge.to) && edge.from !== edge.to);
  const layers = orderLayers(levels.map((level) => [...level]), dagEdges);
  const center = new Map();
  layers.forEach((layer) => {
    layer.forEach((name, row) => center.set(name, row * pitch + nodeHeight / 2));
  });
  const predecessors = linkMap(dagEdges, 'to', 'from');
  const successors = linkMap(dagEdges, 'from', 'to');
  for (let pass = 0; pass < 8; pass += 1) {
    const forward = pass % 2 === 0;
    const sequence = forward ? layers : [...layers].reverse();
    const links = forward ? predecessors : successors;
    for (const layer of sequence) {
      for (const name of layer) {
        const values = (links.get(name) ?? []).map((item) => center.get(item)).filter((value) => value != null);
        if (values.length) center.set(name, median(values));
      }
      separate(layer, center, pitch);
    }
  }

  const positions = new Map();
  layers.forEach((layer, column) => {
    const x = pad + column * (nodeWidth + gapX);
    for (const name of layer) positions.set(name, { x, y: center.get(name) - nodeHeight / 2 });
  });

  const outgoing = new Set(dagEdges.map((edge) => edge.from));
  const sinks = [...columnOf.keys()].filter((name) => !finallyNames.includes(name) && !outgoing.has(name));
  if (finallyNames.length) {
    const sinkCenters = sinks.map((name) => center.get(name)).filter((value) => value != null).sort((a, b) => a - b);
    const anchor = sinkCenters.length ? median(sinkCenters) : nodeHeight / 2;
    const x = pad + layers.length * (nodeWidth + gapX) + 36;
    const start = anchor - ((finallyNames.length - 1) * pitch) / 2;
    finallyNames.forEach((name, index) => {
      positions.set(name, { x, y: start + index * pitch - nodeHeight / 2, finally: true });
    });
  }

  const finallyEdges = finallyNames.flatMap((name) => sinks.map((from) => ({ from, to: name, finally: true })));
  const drawn = [...dagEdges, ...finallyEdges].filter((edge) => positions.has(edge.from) && positions.has(edge.to));
  const drafts = drawn.map((edge) => {
    const span = (columnOf.get(edge.to) ?? 0) - (columnOf.get(edge.from) ?? 0);
    const bend = span > 1
      ? chooseBend(positions.get(edge.from), positions.get(edge.to), edge.from, edge.to, positions, nodeWidth, nodeHeight)
      : 0;
    return { edge, dashed: Boolean(edge.finally), bend };
  });

  let minY = pad;
  let maxY = pad;
  let maxX = pad;
  for (const position of positions.values()) {
    minY = Math.min(minY, position.y);
    maxY = Math.max(maxY, position.y + nodeHeight);
    maxX = Math.max(maxX, position.x + nodeWidth);
  }
  for (const draft of drafts) {
    const from = positions.get(draft.edge.from);
    const to = positions.get(draft.edge.to);
    minY = Math.min(minY, from.y + nodeHeight / 2 + draft.bend, to.y + nodeHeight / 2 + draft.bend);
    maxY = Math.max(maxY, from.y + nodeHeight / 2 + draft.bend, to.y + nodeHeight / 2 + draft.bend);
  }
  const shift = minY < pad ? pad - minY : 0;
  if (shift) {
    for (const position of positions.values()) position.y += shift;
    maxY += shift;
  }

  return {
    levels: layers,
    nodeWidth,
    nodeHeight,
    width: maxX + pad,
    height: maxY + pad + (metrics.captionHeight ?? 0),
    positions,
    routes: drafts.map((draft) => ({
      from: draft.edge.from,
      to: draft.edge.to,
      dashed: draft.dashed,
      d: curvePath(positions.get(draft.edge.from), positions.get(draft.edge.to), nodeWidth, nodeHeight, draft.bend),
    })),
  };
}

function orderLayers(layers, edges) {
  const rowOf = (name) => {
    for (const layer of layers) {
      const row = layer.indexOf(name);
      if (row >= 0) return row;
    }
    return null;
  };
  const predecessors = linkMap(edges, 'to', 'from');
  const successors = linkMap(edges, 'from', 'to');
  const bary = (name, links) => {
    const spots = (links.get(name) ?? []).map(rowOf).filter((spot) => spot != null);
    if (!spots.length) return null;
    return spots.reduce((sum, spot) => sum + spot, 0) / spots.length;
  };
  for (let pass = 0; pass < 4; pass += 1) {
    for (let column = 1; column < layers.length; column += 1) {
      layers[column].sort((left, right) => compareBary(bary(left, predecessors), bary(right, predecessors)));
    }
    for (let column = layers.length - 2; column >= 0; column -= 1) {
      layers[column].sort((left, right) => compareBary(bary(left, successors), bary(right, successors)));
    }
  }
  return layers;
}

function compareBary(left, right) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  return left - right;
}

function linkMap(edges, key, value) {
  const map = new Map();
  for (const edge of edges) {
    if (!edge[key] || !edge[value] || edge[key] === edge[value]) continue;
    const list = map.get(edge[key]) ?? [];
    if (!list.includes(edge[value])) list.push(edge[value]);
    map.set(edge[key], list);
  }
  return map;
}

function separate(layer, center, pitch) {
  if (layer.length < 2) return;
  const desired = layer.map((name) => center.get(name));
  const placed = desired.slice();
  for (let index = 1; index < placed.length; index += 1) {
    placed[index] = Math.max(placed[index], placed[index - 1] + pitch);
  }
  const shift = median(desired) - median(placed);
  layer.forEach((name, index) => center.set(name, placed[index] + shift));
}

function median(values) {
  const sorted = [...values].sort((left, right) => left - right);
  const mid = Math.floor((sorted.length - 1) / 2);
  if (sorted.length % 2) return sorted[mid];
  return (sorted[mid] + sorted[mid + 1]) / 2;
}

function curvePath(from, to, nodeWidth, nodeHeight, bend) {
  const x1 = from.x + nodeWidth;
  const y1 = from.y + nodeHeight / 2;
  const x2 = to.x - 2;
  const y2 = to.y + nodeHeight / 2;
  const dx = Math.max(36, (x2 - x1) * 0.5);
  return `M ${round(x1)} ${round(y1)} C ${round(x1 + dx)} ${round(y1 + bend)}, ${round(x2 - dx)} ${round(y2 + bend)}, ${round(x2)} ${round(y2)}`;
}

function chooseBend(from, to, fromName, toName, positions, nodeWidth, nodeHeight) {
  const x1 = from.x + nodeWidth;
  const y1 = from.y + nodeHeight / 2;
  const x2 = to.x - 2;
  const y2 = to.y + nodeHeight / 2;
  const dx = Math.max(36, (x2 - x1) * 0.5);
  const obstacles = [...positions.entries()]
    .filter(([name]) => name !== fromName && name !== toName)
    .map(([, position]) => ({
      left: position.x + 4,
      right: position.x + nodeWidth - 4,
      top: position.y + 4,
      bottom: position.y + nodeHeight - 4,
    }));
  for (const amount of [0, -64, 64, -104, 104, -148, 148]) {
    if (!curveHits(x1, y1, x2, y2, dx, amount, obstacles)) return amount;
  }
  return -148;
}

function curveHits(x1, y1, x2, y2, dx, bend, obstacles) {
  const c1x = x1 + dx;
  const c1y = y1 + bend;
  const c2x = x2 - dx;
  const c2y = y2 + bend;
  for (let step = 1; step <= 16; step += 1) {
    const t = step / 17;
    const u = 1 - t;
    const x = (u ** 3) * x1 + 3 * (u ** 2) * t * c1x + 3 * u * (t ** 2) * c2x + (t ** 3) * x2;
    const y = (u ** 3) * y1 + 3 * (u ** 2) * t * c1y + 3 * u * (t ** 2) * c2y + (t ** 3) * y2;
    if (obstacles.some((box) => x > box.left && x < box.right && y > box.top && y < box.bottom)) return true;
  }
  return false;
}

function round(value) {
  return Math.round(value * 10) / 10;
}

function pipelineNote() {
  const note = el('p', 'pipeline-note');
  const first = document.createElement('span');
  first.append(
    document.createTextNode('Under each task, '),
    el('span', 'pipeline-note-relation', 'task workspace -> pipeline workspace'),
  );
  note.append(first, el('span', null, 'shows the task workspace bound to that pipeline workspace.'));
  return note;
}

function renderWorkspaces(pipelines, open = true) {
  const section = el('section', 'card');
  section.id = 'workspaces';
  const details = document.createElement('details');
  details.className = 'collapsible';
  details.open = open;
  const summary = document.createElement('summary');
  summary.textContent = 'Workspaces';
  details.append(summary);
  const body = el('div', 'collapsible-body');
  const uses = [];
  const seen = new Set();
  for (const pipeline of pipelines) {
    for (const task of [...(pipeline.tasks ?? []), ...(pipeline.finally ?? [])]) {
      const lines = (task.mounts?.workspaces ?? []).filter(Boolean);
      if (lines.length) uses.push({ pipeline: pipeline.name, task: task.name, lines });
    }
  }
  for (const use of uses) {
    const block = el('article', 'resource');
    block.append(el('h3', null, use.task));
    if (pipelines.length > 1 && use.pipeline) block.append(el('p', null, use.pipeline));
    for (const line of use.lines) {
      block.append(el('p', 'task-line', line));
      const workspace = line.split(' -> ').at(-1);
      seen.add(workspace);
      for (const note of workspaceFileNotes(workspace)) block.append(el('p', 'task-line workspace-file', note));
    }
    body.append(block);
  }
  for (const workspace of runDigest?.workspaces ?? []) {
    if (seen.has(workspace.name)) continue;
    const notes = workspaceFileNotes(workspace.name);
    if (!notes.length) continue;
    seen.add(workspace.name);
    const block = el('article', 'resource');
    block.append(el('h3', null, workspace.name));
    for (const note of notes) block.append(el('p', 'task-line workspace-file', note));
    body.append(block);
  }
  if (!body.childElementCount) body.append(el('p', 'empty', 'No workspaces are used by these pipelines.'));
  details.append(body);
  section.append(details);
  return section;
}

function workspaceFileNotes(name) {
  const workspace = runDigest?.workspaces?.find((item) => item.name === name);
  if (!workspace) return [];
  return [
    ...workspace.files.map((file) => `creates ${file.path} from ${file.source}`),
    ...(workspace.notes ?? []),
  ];
}

function taskCaptions(task, paramLines) {
  const data = (showData ? mountLines(task) : []).map((text) => ({ kind: 'data', text }));
  const params = paramLines.map((line) => ({ kind: 'param', ...line }));
  const outputs = showOutputs ? workspaceOutputs(task, runDigest).map((file) => ({ kind: 'output', ...file })) : [];
  return { lines: [...params, ...data, ...outputs] };
}

export function workspaceOutputs(task, digest) {
  const found = [];
  const seen = new Set();
  const add = (location, name) => {
    if (!location || !name || name.includes('$')) return;
    const key = `${location}/${name}`;
    if (seen.has(key)) return;
    seen.add(key);
    found.push({ location, name });
  };
  const roots = new Map();
  for (const workspace of task?.content?.workspaces ?? []) {
    if (!workspace.name) continue;
    roots.set(workspace.name, String(workspace.mountPath || `/workspace/${workspace.name}`).replace(/\/+$/, ''));
  }
  const pattern = /\$\(workspaces(?:\.([A-Za-z0-9_.-]+)|\[['"]([^'"]+)['"]\])\.path\)((?:\/(?:\$\([^)]*\)|\$\{[^}]*\}|[^/\s'"`);|&<>\\])+)*)/g;
  for (const step of task?.content?.steps ?? []) {
    const text = [step.script, ...(step.command ?? []), ...(step.args ?? []), ...(step.env ?? []).map((item) => item.value ?? '')].filter(Boolean).join('\n');
    for (const match of text.matchAll(pattern)) {
      const workspace = match[1] || match[2];
      const suffix = match[3] || '';
      if (!workspace || !suffix || suffix.endsWith('/')) continue;
      const root = roots.get(workspace) || `/workspace/${workspace}`;
      const relative = substituteParamRefs(suffix, digest);
      if (relative.includes('$')) continue;
      const full = `${root}${relative}`.replace(/\/{2,}/g, '/');
      const name = full.split('/').filter(Boolean).at(-1);
      const location = full.slice(0, full.length - name.length).replace(/\/$/, '');
      add(location, name);
    }
  }
  for (const workspace of task?.content?.workspaces ?? []) {
    if (!workspace.pipeline) continue;
    const placed = digest?.workspaces?.find((item) => item.name === workspace.pipeline);
    const root = roots.get(workspace.name) || `/workspace/${workspace.name}`;
    for (const file of placed?.files ?? []) {
      const full = `${root}/${substituteParamRefs(file.path, digest)}`.replace(/\/{2,}/g, '/');
      if (full.includes('$')) continue;
      const name = full.split('/').filter(Boolean).at(-1);
      const location = full.slice(0, full.length - name.length).replace(/\/$/, '');
      add(location, name);
    }
  }
  return found;
}

function substituteParamRefs(text, digest) {
  return String(text).replace(/\$\(params(?:\.([A-Za-z0-9_.-]+)|\[['"]([^'"]+)['"]\])\)/g, (match, dotted, bracket) => {
    const name = dotted || bracket;
    const provided = digest?.params?.find((param) => param.name === name);
    return provided && provided.value !== '' ? provided.value : match;
  });
}

function mountLines(task) {
  const mounts = task?.mounts;
  if (!mounts) return [];
  return [
    ...(mounts.workspaces ?? []).filter(Boolean),
    ...(mounts.volumes ?? []).filter(Boolean).map((name) => `volume ${name}`),
    ...(mounts.secrets ?? []).filter(Boolean).map((name) => `secret ${name}`),
  ];
}

function openTask(pipelineName, taskName) {
  readJson(SUMMARY_KEY);
  readJson(RUN_KEY);
  const url = `/task.html?pipeline=${encodeURIComponent(pipelineName)}&task=${encodeURIComponent(taskName)}`;
  window.open(url, '_blank', 'noopener');
}

function flowLabel(name, levels, finallyNames) {
  const steps = levels.map((level) => level.join(' and ')).filter(Boolean);
  if (finallyNames.length) steps.push(`finally ${finallyNames.join(' and ')}`);
  return steps.length ? `${name}: ${steps.join(', then ')}` : name;
}

function fit(text, width) {
  const max = Math.max(4, Math.floor((width - 20) / 7));
  if (text.length <= max) return text;
  return `${text.slice(0, max - 1)}…`;
}

function renderTasks(tasks, open = true) {
  const section = el('section', 'card tasks-list');
  section.id = 'tasks';
  if (showTaskParams) section.classList.add('show-task-params');
  if (showTaskParams && showRunParamValues) section.classList.add('show-run-values');
  const details = document.createElement('details');
  details.className = 'collapsible';
  details.open = open;
  const summary = document.createElement('summary');
  summary.textContent = 'Tasks';
  details.append(summary);
  const body = el('div', 'collapsible-body');
  if (!tasks.length) {
    const narrowed = scopeIsActive() && (summaryData?.tasks?.length ?? 0) > 0;
    body.append(el('p', 'empty', narrowed
      ? 'No tasks in the repository match the selected pipeline.'
      : 'No tasks in this directory.'));
  } else {
    body.append(taskParametersSwitch(section));
    for (const task of tasks) body.append(renderTaskBlock(task));
  }
  details.append(body);
  section.append(details);
  return section;
}

function taskParametersSwitch(section) {
  const row = el('div', 'task-parameters-switches');
  const parameters = document.createElement('label');
  parameters.className = 'data-switch task-parameters-switch';
  const parametersInput = document.createElement('input');
  parametersInput.type = 'checkbox';
  parametersInput.checked = showTaskParams;
  parametersInput.addEventListener('click', (event) => event.stopPropagation());

  const values = document.createElement('label');
  values.className = 'data-switch task-parameters-switch';
  if (!showTaskParams) values.classList.add('is-disabled');
  const valuesInput = document.createElement('input');
  valuesInput.type = 'checkbox';
  valuesInput.checked = showTaskParams && showRunParamValues;
  valuesInput.disabled = !showTaskParams;
  valuesInput.addEventListener('click', (event) => event.stopPropagation());
  valuesInput.addEventListener('change', (event) => {
    showRunParamValues = event.target.checked;
    section.classList.toggle('show-run-values', showRunParamValues);
  });

  parametersInput.addEventListener('change', (event) => {
    showTaskParams = event.target.checked;
    section.classList.toggle('show-task-params', showTaskParams);
    if (!showTaskParams) {
      showRunParamValues = false;
      valuesInput.checked = false;
      section.classList.remove('show-run-values');
    }
    valuesInput.disabled = !showTaskParams;
    values.classList.toggle('is-disabled', !showTaskParams);
  });

  parameters.append(parametersInput, document.createTextNode('Parameters'));
  values.append(valuesInput, document.createTextNode('Show pipelinerun values'));
  row.append(parameters, values);
  return row;
}

function renderTaskBlock(task) {
  const block = el('article', 'resource');
  block.append(headingLine('h3', 'task-heading', 'Task name : ', titled(task.namespace, task.name)));
  if (task.description) block.append(labeledLine('task-description', 'Description : ', task.description));
  const uses = pipelineTaskUses(scopedSummary ?? summaryData, runDigest, task);
  const shared = renderStepList(task);
  if (uses.length) shared.classList.add('task-steps-shared');
  if (shared.childElementCount) block.append(shared);
  if (uses.length) {
    const group = el('div', 'task-uses');
    for (const use of uses) {
      const entry = el('div', 'task-use');
      entry.append(headingLine('h4', 'task-use-heading', 'Pipeline task name : ', use.name));
      const steps = renderStepList(task, use);
      if (steps.childElementCount) entry.append(steps);
      group.append(entry);
    }
    block.append(group);
  }
  return block;
}

function headingLine(tag, className, label, text) {
  const heading = el(tag, className);
  heading.append(el('span', 'task-label', label), document.createTextNode(text));
  return heading;
}

function renderStepList(task, use) {
  const steps = el('ul', 'task-steps');
  for (const step of task.steps ?? []) {
    const item = document.createElement('li');
    const name = typeof step === 'string' ? step : step.name;
    item.append(labeledLine('task-step-name', 'Step : ', name));
    for (const param of stepParameters(task, step)) item.append(stepParamLine(param, use));
    steps.append(item);
  }
  return steps;
}

function stepParamLine(param, use) {
  const line = el('p', 'task-step-param');
  line.append(document.createTextNode(param));
  if (!use) return line;
  const value = resolveBoundParam(use.item, param, use.pipeline, runDigest);
  if (value) {
    const suffix = el('span', 'task-step-param-suffix');
    suffix.append(document.createTextNode(' : '), el('span', 'task-step-param-value', value));
    line.append(suffix);
  }
  return line;
}

export function pipelineTaskUses(summary, digest, task) {
  const matches = pipelineTasksFor(summary, task);
  const named = digest?.pipeline;
  const preferred = named ? matches.filter((match) => match.pipeline.name === named) : [];
  return (preferred.length ? preferred : matches).map((match) => ({
    name: match.item.name,
    pipeline: match.pipeline,
    item: match.item,
  }));
}

export function valuesForTaskParam(summary, digest, task, paramName) {
  const values = [];
  for (const use of pipelineTaskUses(summary, digest, task)) {
    const value = resolveBoundParam(use.item, paramName, use.pipeline, digest);
    if (value && !values.includes(value)) values.push(value);
  }
  if (values.length) return values.join(' | ');
  const direct = (digest?.params ?? []).find((param) => param.name === paramName);
  return direct?.value && !/^\$\(params\.[^)]*\)$/.test(String(direct.value).trim()) ? direct.value : '';
}

function pipelineTasksFor(summary, task) {
  const matches = [];
  for (const pipeline of summary?.pipelines ?? []) {
    for (const item of pipeline.tasks ?? []) {
      if (taskRefMatches(item.ref, task.name) || taskShapeMatches(item, task)) matches.push({ pipeline, item });
    }
    for (const item of pipeline.finally ?? []) {
      if (taskRefMatches(item.ref, task.name) || taskShapeMatches(item, task)) matches.push({ pipeline, item });
    }
  }
  return matches;
}

function taskShapeMatches(item, task) {
  if (!/^resolver [^/]+$/.test(item.ref ?? '')) return false;
  const left = (item.content?.steps ?? []).filter((step) => !step.sidecar).map((step) => step.name);
  const right = (task.steps ?? []).map((step) => (typeof step === 'string' ? step : step.name));
  return left.length > 0 && left.length === right.length && left.every((name, index) => name === right[index]);
}

function stepParameters(task, step) {
  if (typeof step !== 'string' && step.params?.length) return step.params;
  const name = typeof step === 'string' ? step : step.name;
  for (const match of pipelineTasksFor(scopedSummary ?? summaryData, task)) {
    const contentStep = (match.item.content?.steps ?? []).find((candidate) => candidate.name === name && !candidate.sidecar);
    const params = paramsInStep(contentStep, task.params ?? []);
    if (params.length) return params;
  }
  return typeof step === 'string' ? [] : (step.params ?? []);
}

function taskRefMatches(ref, taskName) {
  return ref === taskName || ref === `task ${taskName}` || ref?.endsWith(`/${taskName}`);
}

function paramsInStep(step, declared) {
  if (!step) return [];
  const text = [
    step.script,
    step.image,
    step.workingDir,
    ...(step.command ?? []),
    ...(step.args ?? []),
    ...(step.env ?? []).map((item) => `${item.name}=${item.value ?? ''}`),
  ].filter(Boolean).join('\n');
  const found = [];
  const add = (name) => {
    if (name && !found.includes(name)) found.push(name);
  };
  for (const match of text.matchAll(/\$\(([^)]*)\)/g)) {
    const parts = (match[1] ?? '')
      .trim()
      .replace(/\[\s*['"]([^'"]+)['"]\s*\]/g, '.$1')
      .replace(/\[\s*(\*|\d+)\s*\]/g, '.$1')
      .split('.')
      .map((part) => part.trim())
      .filter(Boolean);
    if (parts[0] === 'params' && parts[1]) add(parts[1]);
  }
  for (const match of text.matchAll(/\$\{(PARAM_[A-Za-z0-9_]+)\}/g)) {
    const target = (match[1] ?? '').replace(/^PARAM_/, '').toLowerCase().replace(/[_-]/g, '');
    const param = declared.find((name) => name.toLowerCase().replace(/[_-]/g, '') === target);
    if (param) add(param);
  }
  return found;
}

function labeledLine(className, label, text) {
  const line = el('p', className);
  line.append(el('span', 'task-label', label), document.createTextNode(text));
  return line;
}

function renderRuns(title, runs, refLabel, id) {
  const section = card(title);
  if (id) section.id = id;
  if (!runs.length) {
    section.append(el('p', 'empty', `No ${title.toLowerCase()} in this directory.`));
    return section;
  }
  for (const run of runs) {
    const selected = id === 'pipeline-runs' && resourceId(run) === selection.pipelineRun;
    const block = el('article', selected ? 'resource is-selected' : 'resource');
    const heading = el('h3', null, titled(run.namespace, run.name));
    heading.append(el('span', 'phase', run.phase));
    block.append(heading);
    if (run.pipeline) block.append(el('p', null, `${refLabel} ${run.pipeline}`));
    for (const task of run.tasks ?? []) {
      block.append(el('p', 'task-line', `${task.name} ${task.phase}`));
    }
    section.append(block);
  }
  return section;
}

function card(title) {
  const section = el('section', 'card');
  section.append(el('h2', null, title));
  return section;
}

function count(value, singular, plural) {
  return el('strong', null, `${value} ${value === 1 ? singular : plural}`);
}

function titled(namespace, name) {
  return namespace ? `${namespace}/${name}` : name;
}

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text != null) node.textContent = text;
  return node;
}

if (typeof document !== 'undefined') boot();
