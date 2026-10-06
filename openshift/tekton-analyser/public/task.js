import { RUN_KEY, SUMMARY_KEY, readJson } from './analysis-store.js';
import { annotationParts, describeEnvVar, describeReference, describeShellParam, referenceKind } from './task-view.js';

const params = new URLSearchParams(window.location.search);
const pipelineName = params.get('pipeline') ?? '';
const taskName = params.get('task') ?? '';
const nameNode = document.querySelector('#task-name');
const metaNode = document.querySelector('#task-meta');
const view = document.querySelector('#task-view');

const summary = readJson(SUMMARY_KEY);
const runDigest = readJson(RUN_KEY);
const pipeline = (summary?.pipelines ?? []).find((item) => item.name === pipelineName);
const task = [...(pipeline?.tasks ?? []), ...(pipeline?.finally ?? [])].find((item) => item.name === taskName);

if (!pipeline || !task) {
  nameNode.textContent = taskName || 'Task';
  metaNode.textContent = 'Open this task from the pipeline diagram after the analysis has loaded.';
} else {
  nameNode.textContent = task.name;
  document.title = `${task.name} · Tekton analyser`;
  metaNode.textContent = [pipeline.name, task.ref].filter(Boolean).join(' · ');
  renderTask(pipeline, task, runDigest);
}

function renderTask(pipeline, task, run) {
  const detail = el('section', 'task-detail');
  detail.hidden = true;
  view.append(detail);

  const content = task.content;
  if (!content) {
    view.append(el('p', 'empty', 'Analyse the repository again to load the task content.'));
    return;
  }
  if (content.description) view.append(el('p', 'lede', content.description));

  if (content.params?.length) {
    const block = el('article', 'card task-step');
    block.append(el('h2', null, 'Parameters'));
    const pre = el('pre', 'task-script');
    content.params.forEach((param, index) => {
      if (index) pre.append(document.createTextNode('\n'));
      pre.append(document.createTextNode(`${param.name}: `));
      const source = param.value || param.default || '';
      if (source) appendAnnotated(pre, source, task, pipeline, run, detail);
      else pre.append(document.createTextNode('No value is set.'));
      const described = describeReference(`params.${param.name}`, task, pipeline, run);
      if (described.value && described.value !== source && described.value !== 'No value is set.') {
        pre.append(document.createTextNode(`\n${described.value}`));
      }
    });
    block.append(pre);
    view.append(block);
  }

  if (content.workspaces?.length) {
    const block = el('article', 'card task-step');
    block.append(el('h2', null, 'Workspaces'));
    const pre = el('pre', 'task-script');
    content.workspaces.forEach((workspace, index) => {
      if (index) pre.append(document.createTextNode('\n'));
      pre.append(document.createTextNode(`${workspace.name}: `));
      appendAnnotated(pre, `$(workspaces.${workspace.name}.path)`, task, pipeline, run, detail);
    });
    block.append(pre);
    view.append(block);
  }

  const steps = content.steps ?? [];
  if (!steps.length) {
    view.append(el('p', 'empty', 'The task body is not in the analysed files, so the step text cannot be shown.'));
    return;
  }
  for (const step of steps) {
    const block = el('article', 'card task-step');
    block.append(el('h2', null, step.sidecar ? `Sidecar ${step.name}` : step.name));
    const fields = [
      ['image', step.image],
      ['workingDir', step.workingDir],
      ['script', step.script],
      ['command', (step.command ?? []).join(' ')],
      ['args', (step.args ?? []).join(' ')],
      ['env', (step.env ?? []).map((item) => `${item.name}=${item.value ?? ''}`).filter(Boolean).join('\n')],
    ];
    let shown = false;
    for (const [field, text] of fields) {
      if (!text) continue;
      shown = true;
      if (field === 'script') {
        block.append(scriptSection(text, step, task, pipeline, run, detail));
        continue;
      }
      block.append(el('p', 'task-field', field));
      const pre = el('pre', 'task-script');
      appendAnnotated(pre, text, task, pipeline, run, detail, step);
      block.append(pre);
    }
    if (!shown) block.append(el('p', 'empty', 'This step has no image, script, command, or environment to show.'));
    view.append(block);
  }
}

function scriptSection(text, step, task, pipeline, run, detail) {
  const heading = el('div', 'script-heading');
  heading.append(el('p', 'task-field', 'script'));
  const actions = el('div', 'script-actions');
  const parameters = scriptToggle('Show injected parameters', 'Show parameter references', 'script-inject');
  const environment = scriptToggle('Show environment variables', 'Show environment references', 'script-inject script-env');
  actions.append(parameters, environment);
  heading.append(actions);
  const pre = el('pre', 'task-script');
  appendAnnotated(pre, text, task, pipeline, run, detail, step, true);
  if (!pre.querySelector('[data-injected]')) parameters.hidden = true;
  if (!pre.querySelector('[data-env]')) environment.hidden = true;
  parameters.addEventListener('click', () => toggleValues(parameters, pre, '[data-injected]', 'injected'));
  environment.addEventListener('click', () => toggleValues(environment, pre, '[data-env]', 'env'));
  const note = el('p', 'hint script-note', 'Environment variables created by the script and subsequently used are not resolved to a value below.');
  const section = el('div', 'script-section');
  section.append(heading, note, pre);
  return section;
}

function scriptToggle(showLabel, hideLabel, className) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = className;
  button.textContent = showLabel;
  button.dataset.showLabel = showLabel;
  button.dataset.hideLabel = hideLabel;
  return button;
}

function toggleValues(button, pre, selector, datasetKey) {
  const showing = button.dataset.showing === 'values';
  button.dataset.showing = showing ? '' : 'values';
  button.textContent = showing ? button.dataset.showLabel : button.dataset.hideLabel;
  for (const item of pre.querySelectorAll(selector)) {
    item.textContent = showing ? item.dataset.source : item.dataset[datasetKey];
  }
}

function appendAnnotated(parent, text, task, pipeline, run, detail, step, environment = false) {
  for (const part of annotationParts(text)) {
    if (part.type === 'env') {
      const defined = (step?.env ?? []).some((item) => item.name === part.name);
      if (!environment || !defined) {
        parent.append(document.createTextNode(part.text));
        continue;
      }
      parent.append(parameterButton(part.text, describeEnvVar(part.name, step, task, pipeline, run), detail, 'env'));
      continue;
    }
    if (part.type === 'shell') {
      parent.append(parameterButton(part.text, describeShellParam(part.name, step, task, pipeline, run), detail));
      continue;
    }
    if (part.type !== 'ref' || referenceKind(part.raw) === 'other') {
      parent.append(document.createTextNode(part.text));
      continue;
    }
    if (referenceKind(part.raw) === 'param') {
      const described = describeReference(part.raw, task, pipeline, run);
      const reference = popupReference(part.raw, part.text, task);
      parent.append(parameterButton(part.text, { reference, value: described.value }, detail));
      continue;
    }
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'task-ref';
    button.textContent = part.text;
    button.addEventListener('click', () => {
      const described = describeReference(part.raw, task, pipeline, run);
      detail.hidden = false;
      const children = [
        el('h2', null, described.title),
        el('p', 'task-value', described.value),
      ];
      if (described.because) children.push(el('p', 'hint', described.because));
      detail.replaceChildren(...children);
      detail.scrollIntoView({ block: 'nearest' });
    });
    parent.append(button);
  }
}

function parameterButton(source, described, detail, kind = 'param') {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = kind === 'env' ? 'task-ref task-env' : 'task-ref';
  button.textContent = source;
  button.dataset.source = source;
  const injected = described.value && described.value !== 'No value is set.' ? described.value : source;
  if (kind === 'env') button.dataset.env = injected;
  else button.dataset.injected = injected;
  const popup = `${described.reference} ---> ${described.value}`;
  button.addEventListener('click', () => {
    detail.hidden = false;
    detail.replaceChildren(el('p', 'task-value', popup));
    detail.scrollIntoView({ block: 'nearest' });
  });
  return button;
}

function popupReference(raw, originalText, task) {
  const name = paramName(raw);
  const binding = (task.content?.params ?? []).find((param) => param.name === name);
  const source = (binding?.value || binding?.default || '').trim();
  if (/^\$\([^)]*\)$/.test(source) && source.includes('params')) return source;
  return originalText;
}

function paramName(raw) {
  const parts = String(raw)
    .trim()
    .replace(/\[\s*['"]([^'"]+)['"]\s*\]/g, '.$1')
    .split('.')
    .map((part) => part.trim())
    .filter(Boolean);
  return parts[0] === 'params' ? parts[1] : '';
}

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text) node.textContent = text;
  return node;
}
