export const SUMMARY_KEY = 'tekton-analyser-summary';
export const RUN_KEY = 'tekton-analyser-run';

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
