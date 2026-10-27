import { RUN_KEY, SUMMARY_KEY, readJson } from './analysis-store.js';
import { analyseParameters } from './parameter-analysis.js';

const meta = document.querySelector('#parameter-meta');
const view = document.querySelector('#parameter-analysis');
const summary = readJson(SUMMARY_KEY);
const runDigest = readJson(RUN_KEY);

if (!summary) {
  meta.textContent = 'Analyse a repository before reviewing parameters.';
  view.append(el('p', 'empty', 'Nothing to analyse yet.'));
} else {
  meta.textContent = [summary.repository, summary.contextDir, runDigest?.name].filter(Boolean).join(' · ');
  renderFindings(analyseParameters(summary, runDigest));
}

function renderFindings(findings) {
  const duplicated = findings.filter((item) => item.type === 'duplication');
  const embedded = findings.filter((item) => item.type === 'embedded');
  view.append(section('Duplicated parameters', duplicated, 'No duplicated parameter values were found.'));
  view.append(section('Hard-coded parameter values', embedded, 'No parameter value is hard-coded inside another parameter.'));
}

function section(title, findings, empty) {
  const card = el('section', 'card');
  card.append(el('h2', null, title));
  if (!findings.length) {
    card.append(el('p', 'empty', empty));
    return card;
  }
  for (const finding of findings) card.append(findingCard(finding));
  return card;
}

function findingCard(finding) {
  const card = el('article', 'finding');
  if (finding.type !== 'duplication') {
    card.append(el('p', 'finding-kind is-embedded', 'Hard-coded value'));
  }
  if (finding.type === 'duplication' && finding.parameters?.length) card.append(parameterValues(finding.parameters));
  else card.append(el('p', 'finding-value', finding.value));
  card.append(el('h3', null, 'Where'));
  const places = document.createElement('ul');
  for (const place of finding.places) places.append(el('li', null, place));
  card.append(places);
  return card;
}

function parameterValues(parameters) {
  const list = el('div', 'finding-params');
  for (const param of parameters) {
    const line = el('p', 'finding-param');
    line.append(document.createTextNode(param.name));
    if (param.value) {
      const suffix = document.createElement('span');
      suffix.append(document.createTextNode(' : '), el('span', 'finding-param-value', param.value));
      line.append(suffix);
    }
    list.append(line);
  }
  return list;
}

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text) node.textContent = text;
  return node;
}
