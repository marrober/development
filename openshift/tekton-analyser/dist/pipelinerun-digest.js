import { parseAllDocuments } from 'yaml';
import { asRecord, asString, formatInline, recordsOf } from './util.js';
export function digestPipelineRun(text) {
    let documents;
    try {
        documents = parseAllDocuments(text);
    }
    catch {
        throw new Error('Could not read that file as YAML or JSON.');
    }
    const runs = [];
    for (const document of documents) {
        if (document.errors.length > 0)
            throw new Error('Could not read that file as YAML or JSON.');
        runs.push(...pipelineRunsFrom(document.toJS()));
    }
    const run = runs[0];
    if (!run)
        throw new Error('Drop a PipelineRun manifest.');
    const metadata = asRecord(run.metadata) ?? {};
    const spec = asRecord(run.spec) ?? {};
    const params = recordsOf(spec.params)
        .map((param) => {
        const name = asString(param.name);
        if (!name)
            return undefined;
        return { name, value: formatInline(param.value) };
    })
        .filter((param) => param != null);
    const values = new Map(params.map((param) => [param.name, param.value]));
    const pipelineRef = asRecord(spec.pipelineRef);
    return {
        name: asString(metadata.name) ?? asString(metadata.generateName) ?? 'PipelineRun',
        pipeline: asString(pipelineRef?.name),
        params,
        workspaces: recordsOf(spec.workspaces).flatMap((workspace) => workspaceFiles(workspace, values)),
    };
}
function pipelineRunsFrom(value) {
    if (Array.isArray(value))
        return value.flatMap((item) => pipelineRunsFrom(item));
    const record = asRecord(value);
    if (!record)
        return [];
    if (asString(record.kind) === 'PipelineRun')
        return [record];
    if (asString(record.kind) === 'List') {
        return recordsOf(record.items).filter((item) => asString(item.kind) === 'PipelineRun');
    }
    return [];
}
function workspaceFiles(raw, params) {
    const name = asString(raw.name);
    if (!name)
        return [];
    const files = [];
    const notes = [];
    const subPath = asString(raw.subPath);
    collectSource(asRecord(raw.secret), 'secret', secretLabel, files, notes);
    collectSource(asRecord(raw.configMap), 'configmap', (source) => asString(source.name), files, notes);
    const projected = asRecord(raw.projected);
    for (const source of recordsOf(projected?.sources)) {
        collectSource(asRecord(source.secret), 'secret', secretLabel, files, notes);
        collectSource(asRecord(source.configMap), 'configmap', (item) => asString(item.name), files, notes);
    }
    if (files.length === 0 && notes.length === 0)
        return [];
    const prefix = subPath ? `${subPath.replace(/\/+$/, '')}/` : '';
    return [{
            name,
            files: files.map((file) => ({ ...file, path: applyParams(`${prefix}${file.path}`, params) })),
            notes: notes.map((note) => applyParams(subPath ? `${note} The workspace uses subpath ${subPath}.` : note, params)),
        }];
}
function collectSource(source, kind, labelOf, files, notes) {
    if (!source)
        return;
    const label = `${kind} ${labelOf(source) ?? kind}`;
    const items = recordsOf(source.items);
    if (items.length === 0) {
        notes.push(`A file is created for each key in ${label}.`);
        return;
    }
    for (const item of items) {
        const key = asString(item.key);
        const path = asString(item.path) ?? key;
        if (path)
            files.push({ path, source: label });
    }
}
function secretLabel(source) {
    return asString(source.secretName) ?? asString(source.name);
}
function applyParams(text, params) {
    return text.replace(/\$\(params\.([^)]+)\)/g, (match, name) => params.get(name.trim()) ?? match);
}
//# sourceMappingURL=pipelinerun-digest.js.map