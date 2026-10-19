import { createReadStream } from 'node:fs';
import { stat, rm } from 'node:fs/promises';
import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { cloneRepository, parseRepositoryUrl, redactSecret, resolveContextDir } from './git-source.js';
import { loadResources } from './load.js';
import { summarise, type Summary } from './summarise.js';
import { digestPipelineRun } from './pipelinerun-digest.js';

const publicDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../public');
const MAX_BODY = 32_768;
const MAX_RUN_BODY = 512_000;

const MIME: Record<string, string> = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
};

export class HttpError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}

export async function analyseSource(input: { repository?: unknown; contextDir?: unknown; token?: unknown }): Promise<Summary> {
  const repository = typeof input.repository === 'string' ? input.repository.trim() : '';
  const contextDir = typeof input.contextDir === 'string' ? input.contextDir.trim() : '';
  const token = typeof input.token === 'string' ? input.token : '';
  if (!repository) throw new HttpError(400, 'Enter a git repository URL.');

  let checkout: string | undefined;
  try {
    const cleanUrl = parseRepositoryUrl(repository).toString();
    resolveContextDir(os.tmpdir(), contextDir);
    checkout = await cloneRepository(repository, token || undefined);
    const target = resolveContextDir(checkout, contextDir);
    const info = await stat(target).catch(() => undefined);
    if (!info) throw new HttpError(400, 'Context directory was not found in the repository.');
    if (!info.isDirectory()) throw new HttpError(400, 'Context directory must be a directory inside the repository.');
    const loaded = await loadResources([target]);
    return summarise(loaded, { root: checkout, repository: cleanUrl, contextDir: contextDir || '.' });
  } catch (error) {
    if (error instanceof HttpError) throw error;
    const message = error instanceof Error ? error.message : 'Could not analyse the repository.';
    throw new HttpError(400, redactSecret(message, token));
  } finally {
    if (checkout) await rm(checkout, { recursive: true, force: true });
  }
}

export function createApp() {
  return createServer((request, response) => {
    void handle(request, response);
  });
}

async function handle(request: IncomingMessage, response: ServerResponse): Promise<void> {
  try {
    const url = new URL(request.url ?? '/', 'http://localhost');
    if (request.method === 'POST' && url.pathname === '/api/analyse') {
      const body = await readJson(request, MAX_BODY);
      const summary = await analyseSource(body);
      sendJson(response, 200, { ok: true, summary });
      return;
    }
    if (request.method === 'POST' && url.pathname === '/api/pipelinerun') {
      const body = await readJson(request, MAX_RUN_BODY);
      const manifest = typeof body.manifest === 'string' ? body.manifest : '';
      if (!manifest.trim()) throw new HttpError(400, 'Drop a PipelineRun manifest.');
      try {
        sendJson(response, 200, { ok: true, digest: digestPipelineRun(manifest) });
      } catch (error) {
        throw new HttpError(400, error instanceof Error ? error.message : 'Could not read that PipelineRun.');
      }
      return;
    }
    if (request.method === 'GET') {
      await sendStatic(url.pathname, response);
      return;
    }
    sendJson(response, 405, { ok: false, error: 'Method not allowed.' });
  } catch (error) {
    const status = error instanceof HttpError ? error.status : 500;
    const message = error instanceof Error ? error.message : 'Request failed.';
    sendJson(response, status, { ok: false, error: message });
  }
}

function readJson(request: IncomingMessage, limit: number): Promise<Record<string, unknown>> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    let size = 0;
    let settled = false;
    const fail = (error: Error) => {
      if (settled) return;
      settled = true;
      reject(error);
    };
    const succeed = (value: Record<string, unknown>) => {
      if (settled) return;
      settled = true;
      resolve(value);
    };
    request.on('data', (chunk: Buffer) => {
      size += chunk.length;
      if (size > limit) {
        fail(new HttpError(413, 'Request is too large.'));
        request.destroy();
        return;
      }
      chunks.push(chunk);
    });
    request.on('end', () => {
      try {
        const parsed = JSON.parse(Buffer.concat(chunks).toString('utf8')) as unknown;
        if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
          fail(new HttpError(400, 'Expected a JSON object.'));
          return;
        }
        succeed(parsed as Record<string, unknown>);
      } catch {
        fail(new HttpError(400, 'Expected JSON.'));
      }
    });
    request.on('error', () => fail(new HttpError(400, 'Could not read the request.')));
  });
}

async function sendStatic(pathname: string, response: ServerResponse): Promise<void> {
  const requested = pathname === '/' ? 'index.html' : pathname === '/results' ? 'results.html' : pathname.replace(/^\/+/, '');
  const resolved = path.resolve(publicDir, requested);
  const relative = path.relative(publicDir, resolved);
  if (relative.startsWith('..') || path.isAbsolute(relative)) {
    sendJson(response, 404, { ok: false, error: 'Not found.' });
    return;
  }
  const info = await stat(resolved).catch(() => undefined);
  if (!info?.isFile()) {
    sendJson(response, 404, { ok: false, error: 'Not found.' });
    return;
  }
  response.writeHead(200, {
    'content-type': MIME[path.extname(resolved)] ?? 'application/octet-stream',
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff',
  });
  createReadStream(resolved).pipe(response);
}

function sendJson(response: ServerResponse, status: number, body: unknown): void {
  const payload = JSON.stringify(body);
  response.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff',
  });
  response.end(payload);
}

const invokedDirectly = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invokedDirectly) {
  const port = Number(process.env.PORT) || 3000;
  createApp().listen(port, () => {
    process.stdout.write(`Tekton analyser listening on http://localhost:${port}\n`);
  });
}
