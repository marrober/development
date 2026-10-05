const STORAGE_KEY = 'tekton-analyser-summary';
const form = document.querySelector('#source-form');
const repositoryInput = document.querySelector('#repository');
const contextInput = document.querySelector('#context-dir');
const tokenInput = document.querySelector('#token');
const submitButton = document.querySelector('#submit');
const statusNode = document.querySelector('#status');
const errorNode = document.querySelector('#error');

form.addEventListener('submit', (event) => {
  event.preventDefault();
  void analyse();
});

form.addEventListener('dragover', (event) => {
  event.preventDefault();
  form.classList.add('is-dropping');
});

form.addEventListener('dragleave', (event) => {
  if (!form.contains(event.relatedTarget)) form.classList.remove('is-dropping');
});

form.addEventListener('drop', (event) => {
  event.preventDefault();
  form.classList.remove('is-dropping');
  const dropped = event.dataTransfer?.getData('text/uri-list') || event.dataTransfer?.getData('text/plain') || '';
  const candidate = dropped.trim().split(/\s+/)[0] ?? '';
  if (candidate.startsWith('https://') || candidate.startsWith('http://')) {
    repositoryInput.value = candidate;
    contextInput.focus();
  }
});

async function analyse() {
  hide(errorNode);
  setBusy(true, 'Cloning repository…');

  const payload = {
    repository: repositoryInput.value.trim(),
    contextDir: contextInput.value.trim(),
    token: tokenInput.value,
  };

  try {
    const response = await fetch('/api/analyse', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const body = await response.json();
    if (!response.ok || !body.ok) {
      showError(body.error || 'Could not analyse that repository.');
      return;
    }
    tokenInput.value = '';
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(body.summary));
    window.location.assign('/results');
  } catch {
    showError('Could not reach the analyser.');
  } finally {
    setBusy(false);
  }
}

function showError(message) {
  errorNode.hidden = false;
  errorNode.textContent = message;
}

function setBusy(busy, message) {
  submitButton.disabled = busy;
  statusNode.hidden = !busy;
  statusNode.textContent = message ?? '';
  form.setAttribute('aria-busy', busy ? 'true' : 'false');
}

function hide(node) {
  node.hidden = true;
  node.textContent = '';
}
