import { RUN_KEY, SELECTION_KEY, SUMMARY_KEY, readJson } from './analysis-store.js';
import { prepareAnalysis } from './analysis-scope.js';
import { analyseParameters } from './parameter-analysis.js';

const meta = document.querySelector('#parameter-meta');
const view = document.querySelector('#parameter-analysis');
const summary = readJson(SUMMARY_KEY);
const prepared = summary ? prepareAnalysis(summary, readJson(SELECTION_KEY) ?? {}, readJson(RUN_KEY)) : undefined;

if (!summary || !prepared?.summary) {
  meta.textContent = 'Analyse a repository before reviewing parameters.';
  view.append(el('p', 'empty', 'Nothing to analyse yet.'));
} else {
  const digest = prepared.digest;
  const pipelineNames = (prepared.summary.pipelines ?? []).map((pipeline) => pipeline.name).filter(Boolean);
  const scoped = pipelineNames.length && pipelineNames.length !== (summary.pipelines ?? []).length
    ? pipelineNames.join(', ')
    : digest?.pipeline;
  meta.textContent = [summary.repository, summary.contextDir, scoped, digest?.name && digest.name !== scoped ? digest.name : ''].filter(Boolean).join(' · ');
  renderFindings(analyseParameters(prepared.summary, digest));
}

function renderFindings(findings) {
  const consolidated = findings.filter((item) => item.type === 'consolidation');
  const unused = findings.filter((item) => item.type === 'unused');
  const embedded = findings.filter((item) => item.type === 'embedded');
  view.append(section(
    'Duplicated parameters',
    'PipelineRun parameters that share a value and could be consolidated.',
    consolidated,
    'No PipelineRun parameters share a value.',
    consolidationCard,
  ));
  view.append(unusedSection(unused));
  view.append(section(
    'Hard-coded parameter values',
    'Values written into the pipeline instead of referencing another pipeline parameter. PipelineRun and trigger template values are expected to be literal.',
    embedded,
    'No pipeline parameter value is hard-coded inside another pipeline parameter.',
    findingCard,
  ));
}

function section(title, intro, findings, empty, render) {
  const card = el('section', 'card');
  card.append(el('h2', null, title));
  card.append(el('p', 'hint', intro));
  if (!findings.length) {
    card.append(el('p', 'empty', empty));
    return card;
  }
  for (const finding of findings) card.append(render(finding));
  return card;
}

function consolidationCard(finding) {
  const card = el('article', 'finding is-consolidation');
  card.append(el('p', 'finding-kind', 'Shared PipelineRun value'));
  card.append(el('p', 'finding-value finding-highlight', finding.value));
  card.append(el('p', 'hint', 'These parameters could be one parameter.'));
  const names = el('ul', 'consolidation-names');
  for (const param of finding.parameters ?? []) names.append(el('li', 'finding-param', param.name));
  card.append(names);
  return card;
}

function unusedSection(findings) {
  const card = el('section', 'card');
  card.append(el('h2', null, 'Parameters not passed to a task'));
  card.append(el('p', 'hint', 'Declared on the pipeline or PipelineRun, and never given to a task.'));
  if (!findings.length) {
    card.append(el('p', 'empty', 'Every pipeline and PipelineRun parameter is passed to a task.'));
    return card;
  }
  for (const finding of findings) {
    const line = el('p', 'unused-param');
    line.append(el('span', 'finding-param', finding.name));
    if (finding.value) line.append(el('span', 'finding-highlight', finding.value));
    line.append(el('span', 'unused-source', (finding.sources ?? []).join(' · ')));
    card.append(line);
  }
  return card;
}

function findingCard(finding) {
  const card = el('article', 'finding');
  card.append(el('p', 'finding-kind is-embedded', 'Hard-coded value'));
  card.append(el('p', 'finding-value', finding.value));
  card.append(el('h3', null, 'Where'));
  const places = document.createElement('ul');
  for (const place of finding.places) places.append(el('li', null, place));
  card.append(places);
  return card;
}

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text) node.textContent = text;
  return node;
}
