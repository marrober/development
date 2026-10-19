import { spawn } from 'node:child_process';
import { mkdtemp, rm } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
const CLONE_TIMEOUT_MS = 90_000;
export function parseRepositoryUrl(input) {
    const trimmed = input.trim();
    let url;
    try {
        url = new URL(trimmed);
    }
    catch {
        throw new Error('Enter an http(s) git repository URL.');
    }
    if (url.protocol !== 'https:' && url.protocol !== 'http:') {
        throw new Error('Repository URL must start with https:// or http://.');
    }
    if (url.username || url.password) {
        throw new Error('Remove credentials from the repository URL and put the token in the token field.');
    }
    if (!url.hostname) {
        throw new Error('Repository URL needs a host.');
    }
    const repositoryPath = githubRepositoryPath(url.hostname, url.pathname);
    if (repositoryPath) {
        url.pathname = repositoryPath;
        url.search = '';
        url.hash = '';
    }
    return url;
}
function githubRepositoryPath(hostname, pathname) {
    if (hostname !== 'github.com' && !hostname.endsWith('.github.com'))
        return undefined;
    const match = pathname.match(/^(\/[^/]+\/[^/]+?)(?:\.git)?\/(?:tree|blob)\/[^/]+(?:\/.*)?\/?$/);
    if (!match)
        return undefined;
    return `${match[1]}.git`;
}
export function resolveContextDir(repoRoot, contextDir) {
    const raw = contextDir.trim() || '.';
    if (raw.includes('\0')) {
        throw new Error('Context directory is not valid.');
    }
    if (path.isAbsolute(raw) || raw.startsWith('~')) {
        throw new Error('Context directory must be a path inside the repository.');
    }
    const root = path.resolve(repoRoot);
    const resolved = path.resolve(root, raw);
    const relative = path.relative(root, resolved);
    if (relative === '..' || relative.startsWith(`..${path.sep}`) || path.isAbsolute(relative)) {
        throw new Error('Context directory must stay inside the repository.');
    }
    return resolved;
}
export function redactSecret(text, secret) {
    if (!secret)
        return text;
    const trimmed = secret.trim();
    if (!trimmed)
        return text;
    return text.split(trimmed).join('***').split(encodeURIComponent(trimmed)).join('***');
}
export async function cloneRepository(repository, token) {
    const url = parseRepositoryUrl(repository);
    const destination = await mkdtemp(path.join(os.tmpdir(), 'tekton-analyser-'));
    const env = { ...process.env, GIT_TERMINAL_PROMPT: '0' };
    delete env.GIT_TRACE;
    delete env.GIT_CURL_VERBOSE;
    delete env.GIT_TRACE_PACKET;
    const secret = token?.trim();
    if (secret) {
        env.GIT_CONFIG_COUNT = '1';
        env.GIT_CONFIG_KEY_0 = 'http.extraHeader';
        env.GIT_CONFIG_VALUE_0 = `AUTHORIZATION: bearer ${secret}`;
    }
    try {
        await runGit(['clone', '--depth', '1', '--', url.toString(), destination], env, secret);
        return destination;
    }
    catch (error) {
        await rm(destination, { recursive: true, force: true });
        throw error;
    }
}
function runGit(args, env, secret) {
    return new Promise((resolve, reject) => {
        const child = spawn('git', args, { env, stdio: ['ignore', 'ignore', 'pipe'] });
        let stderr = '';
        const timer = setTimeout(() => {
            child.kill('SIGTERM');
            reject(new Error('Timed out while cloning the repository.'));
        }, CLONE_TIMEOUT_MS);
        child.stderr.setEncoding('utf8');
        child.stderr.on('data', (chunk) => {
            stderr = (stderr + chunk).slice(-4_000);
        });
        child.on('error', (error) => {
            clearTimeout(timer);
            if (error.code === 'ENOENT') {
                reject(new Error('git is not installed or not on PATH.'));
                return;
            }
            reject(new Error(redactSecret(error.message, secret)));
        });
        child.on('close', (code) => {
            clearTimeout(timer);
            if (code === 0) {
                resolve();
                return;
            }
            reject(new Error(failureMessage(stderr, secret)));
        });
    });
}
function failureMessage(stderr, secret) {
    const redacted = redactSecret(stderr, secret).replace(/\s+/g, ' ').trim();
    if (/authentication failed|terminal prompts disabled|401|403|access denied|could not read username/i.test(redacted)) {
        return 'Git could not authenticate. Check the repository URL and token.';
    }
    if (/repository not found|not found/i.test(redacted)) {
        return 'Repository was not found. Check the URL, and provide a token if it is private.';
    }
    if (!redacted)
        return 'Git clone failed.';
    return `Git clone failed: ${redacted.slice(0, 400)}`;
}
//# sourceMappingURL=git-source.js.map