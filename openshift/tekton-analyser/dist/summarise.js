import path from 'node:path';
import { buildTaskGraph } from './graph.js';
import { resourceName } from './model.js';
import { isPipeline, isPipelineRun, isTask, isTaskRun } from './parse.js';
import { extractSubstitutions } from './substitutions.js';
import { collectStrings } from './util.js';
export function summarise(loaded, options) {
    const taskResources = loaded.resources.filter(isTask);
    const tasks = taskResources.map((task) => taskView(task, options.root));
    const pipelines = loaded.resources.filter(isPipeline).map((pipeline) => pipelineView(pipeline, options.root, taskResources));
    const pipelineRuns = loaded.resources.filter(isPipelineRun).map((run) => pipelineRunView(run, options.root));
    const taskRuns = loaded.resources.filter(isTaskRun).map((run) => taskRunView(run, options.root));
    const issues = loaded.issues.map((issue) => ({
        ...issue,
        message: scrubPath(issue.message, options.root),
        source: displaySource(issue.source, options.root),
    }));
    return {
        repository: options.repository,
        contextDir: options.contextDir || '.',
        counts: {
            tasks: tasks.length,
            pipelines: pipelines.length,
            pipelineRuns: pipelineRuns.length,
            taskRuns: taskRuns.length,
        },
        tasks,
        pipelines,
        pipelineRuns,
        taskRuns,
        issues,
    };
}
function taskView(task, root) {
    return {
        kind: task.kind,
        name: resourceName(task.metadata),
        namespace: task.metadata.namespace,
        source: displaySource(task.source, root),
        description: task.spec.description,
        params: task.spec.params.map((param) => param.name).filter(Boolean),
        workspaces: task.spec.workspaces.map((workspace) => workspace.name).filter(Boolean),
        results: task.spec.results.map((result) => result.name).filter(Boolean),
        steps: task.spec.steps.map((step, index) => step.name || `step-${index + 1}`),
    };
}
function pipelineView(pipeline, root, catalog) {
    const tasks = pipeline.spec.tasks.map((task) => pipelineTaskView(task, catalog, pipeline.metadata.namespace));
    const finallyTasks = pipeline.spec.finally.map((task) => pipelineTaskView(task, catalog, pipeline.metadata.namespace));
    const graph = buildTaskGraph(pipeline.spec.tasks.map((task) => ({
        name: task.name,
        dependencies: dependenciesOf(task),
    })));
    return {
        name: resourceName(pipeline.metadata),
        namespace: pipeline.metadata.namespace,
        source: displaySource(pipeline.source, root),
        description: pipeline.spec.description,
        params: pipeline.spec.params.map((param) => param.name).filter(Boolean),
        workspaces: pipeline.spec.workspaces.map((workspace) => workspace.name).filter(Boolean),
        tasks,
        finally: finallyTasks,
        order: graph.levels,
        edges: graph.edges,
    };
}
function pipelineTaskView(task, catalog, namespace) {
    const spec = task.taskSpec ?? taskSpecFromCatalog(task, catalog, namespace);
    const volumes = (spec?.volumes ?? []).filter((volume) => volume.name);
    return {
        name: task.name || '<unnamed>',
        ref: taskReference(task),
        runAfter: task.runAfter,
        mounts: {
            workspaces: workspaceLabels(task),
            volumes: volumes.map((volume) => volume.name),
            secrets: [...new Set(volumes.flatMap((volume) => volume.secrets))],
        },
    };
}
function workspaceLabels(task) {
    return task.workspaces
        .filter((binding) => binding.name && binding.workspace)
        .map((binding) => `${binding.name} -> ${binding.workspace}`);
}
function taskSpecFromCatalog(task, catalog, namespace) {
    const name = task.taskRef?.name;
    if (!name)
        return undefined;
    const matches = catalog.filter((item) => resourceName(item.metadata) === name);
    return (matches.find((item) => namespace && item.metadata.namespace === namespace) ?? matches[0])?.spec;
}
function taskReference(task) {
    if (task.taskSpec)
        return 'inline task';
    if (task.pipelineSpec)
        return 'inline pipeline';
    if (task.pipelineRef?.resolver)
        return `pipeline resolver ${task.pipelineRef.resolver}`;
    if (task.pipelineRef?.name)
        return `pipeline ${task.pipelineRef.name}`;
    if (task.taskRef?.resolver)
        return `resolver ${task.taskRef.resolver}`;
    if (task.taskRef?.apiVersion && task.taskRef.kind && task.taskRef.kind !== 'Task') {
        const name = task.taskRef.name ? `/${task.taskRef.name}` : '';
        return `custom ${task.taskRef.apiVersion} ${task.taskRef.kind}${name}`;
    }
    if (task.taskRef?.name)
        return `task ${task.taskRef.name}`;
    return 'unresolved';
}
function dependenciesOf(task) {
    const dependencies = [];
    const seen = new Set();
    const add = (name, via) => {
        const key = `${name}:${via}`;
        if (seen.has(key))
            return;
        seen.add(key);
        dependencies.push({ name, via });
    };
    for (const name of task.runAfter)
        add(name, 'runAfter');
    const strings = [];
    if (task.displayName)
        strings.push(task.displayName);
    for (const param of [...task.params, ...(task.matrix?.params ?? [])])
        collectStrings(param.value, strings);
    for (const expression of task.when) {
        if (expression.input)
            strings.push(expression.input);
        if (expression.cel)
            strings.push(expression.cel);
        strings.push(...expression.values);
    }
    for (const value of strings) {
        for (const substitution of extractSubstitutions(value)) {
            if (substitution.kind === 'taskResult')
                add(substitution.task, 'result');
        }
    }
    return dependencies;
}
function pipelineRunView(run, root) {
    const observed = phaseOf(run.status?.conditions);
    const spec = run.status?.pipelineSpec ?? run.spec.pipelineSpec;
    const phases = new Map();
    for (const skipped of run.status?.skippedTasks ?? []) {
        if (!skipped.name)
            continue;
        phases.set(skipped.name, { name: skipped.name, phase: 'Skipped', reason: skipped.reason });
    }
    for (const [taskRunName, entry] of Object.entries(run.status?.taskRuns ?? {})) {
        if (!entry.pipelineTaskName || phases.has(entry.pipelineTaskName))
            continue;
        const taskPhase = phaseOf(entry.status?.conditions);
        phases.set(entry.pipelineTaskName, { name: entry.pipelineTaskName, phase: taskPhase.phase, reason: taskPhase.reason ?? taskRunName });
    }
    for (const child of run.status?.childReferences ?? []) {
        if (!child.pipelineTaskName || phases.has(child.pipelineTaskName))
            continue;
        phases.set(child.pipelineTaskName, { name: child.pipelineTaskName, phase: 'Referenced', reason: child.name });
    }
    const orderedNames = spec
        ? [...spec.tasks.map((task) => task.name), ...spec.finally.map((task) => task.name)]
        : [...phases.keys()];
    const tasks = orderedNames.map((name) => phases.get(name) ?? { name, phase: observed.phase === 'Pending' ? 'Pending' : 'NotRun' });
    return {
        name: resourceName(run.metadata),
        namespace: run.metadata.namespace,
        source: displaySource(run.source, root),
        pipeline: run.spec.pipelineRef?.name ?? (run.spec.pipelineSpec ? '(inline)' : undefined),
        phase: observed.phase,
        reason: observed.reason,
        tasks,
    };
}
function taskRunView(run, root) {
    const observed = phaseOf(run.status?.conditions);
    return {
        name: resourceName(run.metadata),
        namespace: run.metadata.namespace,
        source: displaySource(run.source, root),
        pipeline: run.spec.taskRef?.name,
        phase: observed.phase,
        reason: observed.reason,
        tasks: run.status?.steps.map((step, index) => ({
            name: step.name || `step-${index + 1}`,
            phase: step.terminated ? (step.terminated.exitCode === 0 ? 'Succeeded' : 'Failed') : step.running ? 'Running' : 'Pending',
            reason: step.terminated?.reason ?? step.waitingReason,
        })) ?? [],
    };
}
function phaseOf(conditions) {
    const condition = conditions?.find((item) => item.type === 'Succeeded');
    if (!condition)
        return { phase: 'Pending' };
    if (condition.status === 'True') {
        return { phase: condition.reason === 'Completed' ? 'Completed' : 'Succeeded', reason: condition.reason };
    }
    if (condition.status === 'False') {
        if (condition.reason && /cancel/i.test(condition.reason))
            return { phase: 'Cancelled', reason: condition.reason };
        if (condition.reason && /timeout/i.test(condition.reason))
            return { phase: 'TimedOut', reason: condition.reason };
        return { phase: 'Failed', reason: condition.reason };
    }
    if (condition.reason && /pending/i.test(condition.reason))
        return { phase: 'Pending', reason: condition.reason };
    return { phase: 'Running', reason: condition.reason };
}
function scrubPath(text, root) {
    const prefix = root.endsWith(path.sep) ? root : `${root}${path.sep}`;
    return text.split(prefix).join('').split(root).join('.');
}
function displaySource(source, root) {
    if (!source)
        return undefined;
    const marker = source.indexOf('#');
    const file = marker === -1 ? source : source.slice(0, marker);
    const suffix = marker === -1 ? '' : source.slice(marker);
    const relative = path.relative(root, file);
    if (!relative || relative === '.')
        return `.${suffix}`;
    if (relative.startsWith('..') || path.isAbsolute(relative))
        return source;
    return relative + suffix;
}
export function resourceCounts(resources) {
    return {
        tasks: resources.filter(isTask).length,
        pipelines: resources.filter(isPipeline).length,
        pipelineRuns: resources.filter(isPipelineRun).length,
        taskRuns: resources.filter(isTaskRun).length,
    };
}
//# sourceMappingURL=summarise.js.map