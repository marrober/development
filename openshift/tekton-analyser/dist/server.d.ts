import { type IncomingMessage, type ServerResponse } from 'node:http';
import { type Summary } from './summarise.js';
export declare class HttpError extends Error {
    readonly status: number;
    constructor(status: number, message: string);
}
export declare function analyseSource(input: {
    repository?: unknown;
    contextDir?: unknown;
    token?: unknown;
}): Promise<Summary>;
export declare function createApp(): import("http").Server<typeof IncomingMessage, typeof ServerResponse>;
