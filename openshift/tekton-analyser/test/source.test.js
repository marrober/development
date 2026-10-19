import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { arrangeTasks } from '../public/results.js';
import { describeEnvVar, describeReference, describeShellParam, parameterUses } from '../public/task-view.js';
import { digestPipelineRun } from '../dist/pipelinerun-digest.js';
import { parseRepositoryUrl, redactSecret, resolveContextDir } from '../dist/git-source.js';
import { loadResources } from '../dist/load.js';
import { createApp } from '../dist/server.js';
import { summarise } from '../dist/summarise.js';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');

test('a PipelineRun file yields parameter values and workspace files', () => {
  const digest = digestPipelineRun(`
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: example
spec:
  pipelineRef:
    name: build-and-test
  params:
    - name: url
      value: https://example.com/app.git
    - name: path
      value: config/app.yaml
  workspaces:
    - name: shared
      secret:
        secretName: git-auth
        items:
          - key: config
            path: $(params.path)
    - name: cache
      configMap:
        name: build-config
    - name: work
      emptyDir: {}
`);
  assert.equal(digest.pipeline, 'build-and-test');
  assert.deepEqual(digest.params, [
    { name: 'url', value: 'https://example.com/app.git' },
    { name: 'path', value: 'config/app.yaml' },
  ]);
  assert.deepEqual(digest.workspaces, [
    {
      name: 'shared',
      files: [{ path: 'config/app.yaml', source: 'secret git-auth' }],
      notes: [],
    },
    {
      name: 'cache',
      files: [],
      notes: ['A file is created for each key in configmap build-config.'],
    },
  ]);
  const pipeline = {
    name: 'build-and-test',
    paramDefaults: [],
    tasks: [{
      name: 'fetch',
      content: {
        params: [{ name: 'url', value: '$(params.url)' }],
        workspaces: [{ name: 'source', pipeline: 'shared' }],
        steps: [{ name: 'clone', script: 'echo "$(params.url)" > $(workspaces.source.path)/repo' }],
      },
    }],
    finally: [],
  };
  const uses = parameterUses([pipeline], digest.params);
  assert.deepEqual(uses[0].uses, [{ pipeline: 'build-and-test', task: 'fetch', step: 'clone', field: 'script' }]);
  const described = describeReference('params.url', pipeline.tasks[0], pipeline, digest);
  assert.equal(described.value, 'https://example.com/app.git');
  const workspace = describeReference('workspaces.source.path', pipeline.tasks[0], pipeline, digest);
  assert.equal(workspace.value, '/workspace/source');
  assert.match(workspace.because, /shared/);
  assert.match(workspace.because, /config\/app\.yaml/);

  const linked = {
    name: 'build-and-test',
    paramDefaults: [{ name: 'GIT_REPO', default: 'https://default.example/app.git' }],
    tasks: [{
      name: 'fetch',
      content: {
        params: [{ name: 'url', value: "$(params['GIT_REPO'])" }],
        steps: [{ name: 'clone', image: 'example.com/clone:latest', script: 'git clone "$(params.url)"' }],
      },
    }],
    finally: [],
  };
  const linkedRun = {
    params: [{ name: 'GIT_REPO', value: 'https://github.com/example/app.git' }],
    workspaces: [],
  };
  const linkedUses = parameterUses([linked], linkedRun.params);
  assert.deepEqual(linkedUses[0].uses, [{ pipeline: 'build-and-test', task: 'fetch', step: 'clone', field: 'script' }]);
  const fromTask = describeReference('params.url', linked.tasks[0], linked, linkedRun);
  assert.equal(fromTask.value, 'https://github.com/example/app.git');
  assert.match(fromTask.because, /GIT_REPO/);
  const fromRun = describeReference('params["GIT_REPO"]', linked.tasks[0], linked, linkedRun);
  assert.equal(fromRun.value, 'https://github.com/example/app.git');
  assert.match(fromRun.because, /PipelineRun sets GIT_REPO/);
  const shell = describeShellParam('PARAM_URL', {
    env: [{ name: 'PARAM_URL', value: '$(params.url)' }],
    script: 'git clone "${PARAM_URL}"',
  }, linked.tasks[0], linked, linkedRun);
  assert.equal(shell.reference, "$(params['GIT_REPO'])");
  assert.equal(shell.value, 'https://github.com/example/app.git');
  const shellUses = parameterUses([{
    ...linked,
    tasks: [{
      ...linked.tasks[0],
      content: {
        ...linked.tasks[0].content,
        steps: [{
          name: 'clone',
          env: [{ name: 'PARAM_URL', value: '$(params.url)' }],
          script: 'git clone "${PARAM_URL}"',
        }],
      },
    }],
  }], linkedRun.params);
  assert.equal(shellUses[0].uses.some((use) => use.field === 'script'), true);
  const env = describeEnvVar('WORKSPACE_OUTPUT_PATH', {
    env: [{ name: 'WORKSPACE_OUTPUT_PATH', value: '$(workspaces.source.path)' }],
  }, linked.tasks[0], linked, linkedRun);
  assert.equal(env.reference, '${WORKSPACE_OUTPUT_PATH}');
  assert.equal(env.value, '/workspace/source');
  const revision = describeEnvVar('GIT_REV', {
    env: [{ name: 'GIT_REV', value: '$(params.GIT_REPO)' }],
  }, linked.tasks[0], linked, linkedRun);
  assert.equal(revision.value, 'https://github.com/example/app.git');
});

test('repository URL rejects embedded credentials', () => {
  assert.throws(
    () => parseRepositoryUrl('https://user:secret-token@github.com/org/repo.git'),
    /token field/,
  );
  const url = parseRepositoryUrl('https://github.com/org/repo.git');
  assert.equal(url.hostname, 'github.com');
  assert.equal(url.username, '');
  assert.equal(parseRepositoryUrl('https://github.com/marrober/pacman/tree/main').toString(), 'https://github.com/marrober/pacman.git');
});

test('context directory cannot escape the checkout', () => {
  const checkout = path.join(os.tmpdir(), 'tekton-checkout');
  assert.equal(resolveContextDir(checkout, '.tekton'), path.join(checkout, '.tekton'));
  assert.equal(resolveContextDir(checkout, ''), checkout);
  assert.throws(() => resolveContextDir(checkout, '../outside'), /inside the repository/);
  assert.throws(() => resolveContextDir(checkout, '/etc'), /inside the repository/);
});

test('secrets are removed from git errors', () => {
  const message = redactSecret('fatal: auth failed for bearer ghp_exampletokenvalue', 'ghp_exampletokenvalue');
  assert.equal(message.includes('ghp_exampletokenvalue'), false);
  assert.match(message, /\*\*\*/);
});

test('a checkout summarises pipelines, tasks, and ordering', async () => {
  const fixture = path.join(root, 'test/fixtures');
  const loaded = await loadResources([fixture]);
  const summary = summarise(loaded, {
    root: fixture,
    repository: 'https://example.com/repo.git',
    contextDir: '.',
  });
  assert.equal(summary.counts.tasks, 1);
  assert.equal(summary.counts.pipelines, 1);
  assert.deepEqual(summary.pipelines[0].order, [['fetch'], ['test']]);
  assert.deepEqual(summary.pipelines[0].edges, [{ from: 'fetch', to: 'test', via: ['runAfter', 'result'] }]);
  assert.equal(summary.pipelines[0].finally[0].name, 'notify');
  assert.deepEqual(summary.pipelines[0].tasks[0].mounts, { workspaces: ['source -> shared'], volumes: ['ssh-key', 'cache'], secrets: ['git-ssh'] });
  assert.deepEqual(summary.pipelines[0].tasks[1].mounts, { workspaces: [], volumes: [], secrets: [] });
  assert.equal(summary.pipelines[0].tasks[0].content.steps[0].script, 'echo "$(params.url)"');
  assert.equal(summary.pipelines[0].tasks[0].content.params[0].value, '$(params.url)');
  assert.equal(summary.tasks[0].steps[0], 'clone');
  assert.equal(JSON.stringify(summary).includes('bearer'), false);
});

test('analysis does not reveal the temporary checkout path', async () => {
  const directory = await mkdtemp(path.join(os.tmpdir(), 'tekton-analyser-empty-'));
  try {
    const loaded = await loadResources([directory]);
    const summary = summarise(loaded, {
      root: directory,
      repository: 'https://example.com/repo.git',
      contextDir: '.',
    });
    assert.equal(JSON.stringify(summary).includes(directory), false);
    assert.match(summary.issues[0].message, /No YAML or JSON manifests/);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test('the main page starts with repository, context directory, and a masked token', async () => {
  const server = createApp();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  try {
    const page = await fetch(`http://127.0.0.1:${port}/`);
    const html = await page.text();
    assert.equal(page.status, 200);
    assert.match(html, /id="repository"/);
    assert.match(html, /id="context-dir"/);
    assert.match(html, /id="token"[^>]*type="password"/);
    assert.match(html, /Context directory/);

    const results = await fetch(`http://127.0.0.1:${port}/results`);
    const resultsHtml = await results.text();
    assert.equal(results.status, 200);
    assert.match(resultsHtml, /id="results"/);
    assert.match(resultsHtml, /results\.js/);
    const script = await fetch(`http://127.0.0.1:${port}/results.js`);
    const scriptText = await script.text();
    assert.match(scriptText, /pipeline-flow/);
    assert.match(scriptText, /id = 'data-switch'/);
    assert.match(scriptText, /Workspaces/);
    assert.equal(scriptText.includes('→ ${task.ref}'), false);

    const rejected = await fetch(`http://127.0.0.1:${port}/api/analyse`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ repository: 'https://user:s3cret@github.com/org/repo.git', token: 's3cret', contextDir: '..' }),
    });
    const body = await rejected.json();
    assert.equal(rejected.status, 400);
    assert.equal(JSON.stringify(body).includes('s3cret'), false);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
  }
});

test('pipeline diagram aligns parallel tasks with their dependencies', () => {
  const model = arrangeTasks(
    [['fetch'], ['base', 'verify'], ['build'], ['push'], ['check'], ['compare', 'quay'], ['update'], ['sync']],
    [
      { from: 'fetch', to: 'base' },
      { from: 'fetch', to: 'verify' },
      { from: 'base', to: 'build' },
      { from: 'verify', to: 'build' },
      { from: 'build', to: 'push' },
      { from: 'push', to: 'check' },
      { from: 'check', to: 'compare' },
      { from: 'check', to: 'quay' },
      { from: 'compare', to: 'update' },
      { from: 'quay', to: 'update' },
      { from: 'update', to: 'sync' },
      { from: 'fetch', to: 'push', via: ['result'] },
      { from: 'push', to: 'quay', via: ['result'] },
      { from: 'push', to: 'update', via: ['result'] },
    ],
    ['notify'],
  );
  const at = (name) => model.positions.get(name);
  assert.ok(Math.abs(at('base').y - at('verify').y) >= model.nodeHeight + 24);
  assert.ok(Math.abs(at('fetch').y - (at('base').y + at('verify').y) / 2) < 1);
  assert.ok(Math.abs(at('build').y - (at('base').y + at('verify').y) / 2) < 1);
  assert.ok(Math.abs(at('compare').y - at('quay').y) >= model.nodeHeight + 24);
  assert.ok(Math.abs(at('update').y - (at('compare').y + at('quay').y) / 2) < 1);
  assert.equal(at('build').y, at('push').y);
  assert.equal(at('push').y, at('check').y);

  assert.equal(model.routes.some((route) => route.from === 'fetch' && route.to === 'push'), false);
  assert.equal(model.routes.some((route) => route.from === 'push' && route.to === 'quay'), false);
  assert.equal(model.routes.some((route) => route.from === 'push' && route.to === 'update'), false);
  const branch = model.routes.find((route) => route.from === 'fetch' && route.to === 'base');
  assert.match(branch.d, / C /);
  assert.equal(branch.d.includes(' L '), false);
  assert.ok(Math.abs(at('notify').y - (at('sync').y)) < 1);

  const chains = arrangeTasks([['a', 'c'], ['b', 'd']], [{ from: 'a', to: 'b' }, { from: 'c', to: 'd' }]);
  assert.equal(chains.positions.get('a').y, chains.positions.get('b').y);
  assert.equal(chains.positions.get('c').y, chains.positions.get('d').y);
  assert.ok(chains.positions.get('a').y !== chains.positions.get('c').y);
});
