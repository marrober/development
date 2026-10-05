import { readdir, readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { parseManifest } from './parse.js';
import { errorMessage } from './util.js';
const SKIP_DIRECTORIES = new Set(['node_modules', 'dist', 'coverage']);
const MANIFEST_EXTENSIONS = new Set(['.yaml', '.yml', '.json']);
export async function loadResources(paths) {
    const loaded = { resources: [], others: [], issues: [] };
    for (const input of paths) {
        if (input === '-') {
            const text = await readStdin();
            merge(loaded, parseManifest(text, 'stdin', 'yaml'));
            continue;
        }
        let files;
        try {
            files = await collectFiles(input);
        }
        catch (error) {
            loaded.issues.push({
                severity: 'error',
                code: 'unreadable-path',
                message: errorMessage(error),
                source: input,
            });
            continue;
        }
        files.sort();
        if (files.length === 0) {
            loaded.issues.push({
                severity: 'warning',
                code: 'no-manifests',
                message: 'No YAML or JSON manifests found in this directory.',
                source: input,
            });
            continue;
        }
        for (const file of files) {
            const text = await readFile(file, 'utf8');
            const format = path.extname(file) === '.json' ? 'json' : 'yaml';
            merge(loaded, parseManifest(text, file, format));
        }
    }
    return loaded;
}
async function collectFiles(input) {
    const info = await stat(input);
    if (info.isFile())
        return [input];
    if (!info.isDirectory())
        return [];
    const found = [];
    const entries = await readdir(input, { withFileTypes: true });
    for (const entry of entries) {
        if (entry.name === '.git' || SKIP_DIRECTORIES.has(entry.name))
            continue;
        const full = path.join(input, entry.name);
        if (entry.isDirectory())
            found.push(...(await collectFiles(full)));
        else if (entry.isFile() && MANIFEST_EXTENSIONS.has(path.extname(entry.name)))
            found.push(full);
    }
    return found;
}
function merge(target, parsed) {
    target.resources.push(...parsed.resources);
    target.others.push(...parsed.others);
    target.issues.push(...parsed.issues);
}
async function readStdin() {
    const chunks = [];
    for await (const chunk of process.stdin) {
        chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    }
    return Buffer.concat(chunks).toString('utf8');
}
//# sourceMappingURL=load.js.map