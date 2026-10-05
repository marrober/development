const STORAGE_KEY = 'tekton-analyser-summary';
const SVG_NS = 'http://www.w3.org/2000/svg';

let resultsNode;
let metaNode;
let summaryData;
let showData = false;
let runDigest;

function boot() {
  resultsNode = document.querySelector('#results');
  metaNode = document.querySelector('#meta');
  if (!resultsNode || !metaNode) return;

  document.querySelector('#data-switch')?.addEventListener('change', (event) => {
    showData = event.target.checked;
    const current = document.querySelector('#pipelines');
    if (!summaryData || !current) return;
    current.replaceWith(renderPipelines(summaryData.pipelines ?? []));
  });

  const stored = sessionStorage.getItem(STORAGE_KEY);
  let summary;
  try {
    summary = stored ? JSON.parse(stored) : null;
  } catch {
    summary = null;
  }
  summaryData = summary;

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
  const counts = summary.counts ?? {};
  metaNode.textContent = `${summary.repository} · ${summary.contextDir}`;
  resultsNode.append(renderRunDrop());
  const bar = el('div', 'summary-bar');
  bar.append(
    count(counts.tasks ?? 0, 'task', 'tasks'),
    count(counts.pipelines ?? 0, 'pipeline', 'pipelines'),
    count(counts.pipelineRuns ?? 0, 'pipeline run', 'pipeline runs'),
    count(counts.taskRuns ?? 0, 'task run', 'task runs'),
  );
  resultsNode.append(bar);

  if (summary.issues?.length) {
    const issues = card('Issues');
    for (const issue of summary.issues) {
      issues.append(el('p', 'task-line', `${issue.severity}: ${issue.message}`));
    }
    resultsNode.append(issues);
  }

  resultsNode.append(renderPipelines(summary.pipelines ?? []));
  resultsNode.append(renderWorkspaces(summary.pipelines ?? []));
  resultsNode.append(renderTasks(summary.tasks ?? []));
  resultsNode.append(renderRuns('Pipeline runs', summary.pipelineRuns ?? [], 'pipeline'));
  resultsNode.append(renderRuns('Task runs', summary.taskRuns ?? [], 'task'));

  const total = (counts.tasks ?? 0) + (counts.pipelines ?? 0) + (counts.pipelineRuns ?? 0) + (counts.taskRuns ?? 0);
  if (total === 0 && !summary.issues?.length) {
    resultsNode.append(el('p', 'empty', 'No Tekton resources were found in that directory.'));
  }
}

function renderRunDrop() {
  const box = el('div', 'run-drop');
  box.id = 'run-drop';
  box.tabIndex = 0;
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
  box.append(el('p', 'run-drop-label', 'Drop a PipelineRun file'));
  const status = el('p', 'run-drop-status', 'YAML or JSON. Parameter values are read from the file.');
  status.id = 'run-drop-status';
  box.append(status);
  const params = el('div', 'run-params');
  params.id = 'run-params';
  box.append(params, input);

  box.addEventListener('click', () => input.click());
  box.addEventListener('keydown', (event) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      input.click();
    }
  });
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
  setRunStatus(`Reading ${file.name}…`);
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
    runDigest = body.digest;
    const status = document.querySelector('#run-drop-status');
    const params = document.querySelector('#run-params');
    if (status) {
      status.textContent = runDigest.params?.length
        ? file.name
        : `${file.name} has no parameters.`;
    }
    params?.replaceChildren(...(runDigest.params ?? []).map((param) => {
      const line = el('p', 'run-param');
      line.append(el('span', 'run-param-name', `${param.name}:`), document.createTextNode(` ${param.value}`));
      return line;
    }));
    refreshWorkspaces();
  } catch {
    setRunStatus('Could not reach the analyser.');
  }
}

function setRunStatus(message) {
  const status = document.querySelector('#run-drop-status');
  if (status) status.textContent = message;
  document.querySelector('#run-params')?.replaceChildren();
  runDigest = undefined;
  refreshWorkspaces();
}

function refreshWorkspaces() {
  const current = document.querySelector('#workspaces');
  if (!current || !summaryData) return;
  const open = current.querySelector('details')?.open ?? true;
  current.replaceWith(renderWorkspaces(summaryData.pipelines ?? [], open));
}

function renderPipelines(pipelines) {
  const section = card('Pipelines');
  section.id = 'pipelines';
  if (!pipelines.length) {
    section.append(el('p', 'empty', 'No pipelines in this directory.'));
    return section;
  }
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

  const names = [...drawnLevels.flat(), ...finallyNames];
  const longest = Math.max(...names.map((name) => {
    const ref = refs.get(name) ?? '';
    const detail = finallyNames.includes(name) && ref ? `finally · ${ref}` : ref;
    const mounted = showData ? mountLines(taskByName.get(name)).reduce((size, line) => Math.max(size, line.length), 0) : 0;
    return Math.max(name.length, detail.length, mounted);
  }));
  const captionHeight = showData
    ? Math.max(0, ...names.map((name) => mountLines(taskByName.get(name)).length)) * 14 + 8
    : 0;
  const model = arrangeTasks(drawnLevels, pipeline.edges ?? [], finallyNames, tasks, {
    nodeWidth: Math.min(280, Math.max(156, longest * 7.2 + 32)),
    captionHeight: captionHeight > 8 ? captionHeight : 0,
  });

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
    title.textContent = ref ? `${name} (${ref})` : name;
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
    if (showData) {
      mountLines(taskByName.get(name)).forEach((line, lineIndex) => {
        const mounted = document.createElementNS(SVG_NS, 'text');
        mounted.setAttribute('x', String(position.x + model.nodeWidth / 2));
        mounted.setAttribute('y', String(position.y + model.nodeHeight + 16 + lineIndex * 14));
        mounted.setAttribute('text-anchor', 'middle');
        mounted.setAttribute('class', 'flow-data');
        mounted.textContent = fit(line, model.nodeWidth);
        group.append(mounted);
      });
    }
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
    height: maxY + pad,
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

function mountLines(task) {
  const mounts = task?.mounts;
  if (!mounts) return [];
  return [
    ...(mounts.workspaces ?? []).filter(Boolean),
    ...(mounts.volumes ?? []).filter(Boolean).map((name) => `volume ${name}`),
    ...(mounts.secrets ?? []).filter(Boolean).map((name) => `secret ${name}`),
  ];
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

function renderTasks(tasks) {
  const section = card('Tasks');
  if (!tasks.length) {
    section.append(el('p', 'empty', 'No tasks in this directory.'));
    return section;
  }
  for (const task of tasks) {
    const block = el('article', 'resource');
    block.append(el('h3', null, titled(task.namespace, task.name)));
    if (task.description) block.append(el('p', null, task.description));
    const chips = el('ul', 'chips');
    for (const step of task.steps ?? []) chips.append(el('li', null, step));
    if (chips.childElementCount) block.append(chips);
    section.append(block);
  }
  return section;
}

function renderRuns(title, runs, refLabel) {
  const section = card(title);
  if (!runs.length) {
    section.append(el('p', 'empty', `No ${title.toLowerCase()} in this directory.`));
    return section;
  }
  for (const run of runs) {
    const block = el('article', 'resource');
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
