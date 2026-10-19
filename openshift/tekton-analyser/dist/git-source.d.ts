export declare function parseRepositoryUrl(input: string): URL;
export declare function resolveContextDir(repoRoot: string, contextDir: string): string;
export declare function redactSecret(text: string, secret: string | undefined): string;
export declare function cloneRepository(repository: string, token?: string): Promise<string>;
