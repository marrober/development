export function asRecord(value) {
    if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
        return value;
    }
    return undefined;
}
export function asString(value) {
    return typeof value === 'string' ? value : undefined;
}
export function asNumber(value) {
    return typeof value === 'number' && Number.isFinite(value) ? value : undefined;
}
export function asBoolean(value) {
    return typeof value === 'boolean' ? value : undefined;
}
export function asDuration(value) {
    if (typeof value === 'string' && value.length > 0)
        return value;
    if (typeof value === 'number' && Number.isFinite(value))
        return String(value);
    return undefined;
}
export function asStringMap(value) {
    const record = asRecord(value);
    if (!record)
        return undefined;
    const out = {};
    for (const [key, item] of Object.entries(record)) {
        if (typeof item === 'string')
            out[key] = item;
    }
    return out;
}
export function recordsOf(value) {
    if (!Array.isArray(value))
        return [];
    return value.map((item) => asRecord(item) ?? {});
}
export function hasOwn(record, key) {
    return Object.prototype.hasOwnProperty.call(record, key);
}
export function errorMessage(error) {
    return error instanceof Error ? error.message : String(error);
}
export function collectStrings(value, out = []) {
    if (typeof value === 'string') {
        out.push(value);
    }
    else if (typeof value === 'number' || typeof value === 'boolean') {
        out.push(String(value));
    }
    else if (Array.isArray(value)) {
        for (const item of value)
            collectStrings(item, out);
    }
    else if (value && typeof value === 'object') {
        for (const item of Object.values(value))
            collectStrings(item, out);
    }
    return out;
}
export function containsSubstitution(value) {
    return collectStrings(value).some((item) => item.includes('$('));
}
export function valueShape(value) {
    if (value === undefined || value === null)
        return 'empty';
    if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean')
        return 'string';
    if (Array.isArray(value))
        return 'array';
    if (typeof value === 'object')
        return 'object';
    return 'other';
}
export function formatInline(value) {
    if (typeof value === 'string')
        return value;
    if (value === undefined)
        return '';
    return JSON.stringify(value);
}
export function durationMs(start, end) {
    if (!start || !end)
        return undefined;
    const from = Date.parse(start);
    const to = Date.parse(end);
    if (Number.isNaN(from) || Number.isNaN(to))
        return undefined;
    return to - from;
}
export function formatDuration(ms) {
    const sign = ms < 0 ? '-' : '';
    let seconds = Math.round(Math.abs(ms) / 1000);
    const hours = Math.floor(seconds / 3600);
    seconds %= 3600;
    const minutes = Math.floor(seconds / 60);
    seconds %= 60;
    if (hours > 0)
        return `${sign}${hours}h${minutes}m${seconds}s`;
    if (minutes > 0)
        return `${sign}${minutes}m${seconds}s`;
    return `${sign}${seconds}s`;
}
export function quote(value) {
    return value.includes(' ') ? JSON.stringify(value) : value;
}
export function plural(count, noun, pluralForm = `${noun}s`) {
    return `${count} ${count === 1 ? noun : pluralForm}`;
}
//# sourceMappingURL=util.js.map