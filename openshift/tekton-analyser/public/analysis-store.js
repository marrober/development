export const SUMMARY_KEY = 'tekton-analyser-summary';
export const RUN_KEY = 'tekton-analyser-run';
export const SELECTION_KEY = 'tekton-analyser-selection';
export const TOKEN_KEY = 'tekton-analyser-token';

export function readSessionToken() {
  try {
    localStorage.removeItem(TOKEN_KEY);
  } catch {
    // Permanent storage can be blocked. The session value is the only copy we keep.
  }
  try {
    return sessionStorage.getItem(TOKEN_KEY) ?? '';
  } catch {
    return '';
  }
}

export function writeSessionToken(token) {
  const value = typeof token === 'string' ? token : '';
  try {
    if (value) sessionStorage.setItem(TOKEN_KEY, value);
    else sessionStorage.removeItem(TOKEN_KEY);
  } catch {
    // Session storage can be unavailable. The token is then used only for this request.
  }
  try {
    localStorage.removeItem(TOKEN_KEY);
  } catch {
    // Permanent storage can be blocked.
  }
}

export function readJson(key) {
  const shared = parseStore(localStorage, key);
  if (shared.found) {
    mirror(sessionStorage, key, shared.raw);
    return shared.value;
  }
  const local = parseStore(sessionStorage, key);
  if (local.found) {
    mirror(localStorage, key, local.raw);
    return local.value;
  }
  return null;
}

export function writeJson(key, value) {
  const raw = JSON.stringify(value);
  sessionStorage.setItem(key, raw);
  localStorage.setItem(key, raw);
}

export function removeKey(key) {
  sessionStorage.removeItem(key);
  localStorage.removeItem(key);
}

function parseStore(store, key) {
  try {
    const raw = store.getItem(key);
    if (!raw) return { found: false };
    return { found: true, raw, value: JSON.parse(raw) };
  } catch {
    return { found: false };
  }
}

function mirror(store, key, raw) {
  try {
    if (store.getItem(key) !== raw) store.setItem(key, raw);
  } catch {
    // Storage can be unavailable in a private window. The other store still holds the analysis.
  }
}
