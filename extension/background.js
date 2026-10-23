const HOST = 'com.belde.editor';
const views = new Set();
let nativePort = null;
let token = '';
let clientId = crypto.randomUUID();
let latest = null;
let status = 'disconnected';
let message = 'Start Belde, then enter the six-digit code shown in the PC game.';
let pendingCount = 0;
let sequence = 0;
let fullEditorWindow = null;
let polling = false;
const requests = new Map();

function publicState() {
  return {event: 'state', connected: Boolean(token && nativePort), status, message,
    state: latest, pendingCount, extensionId: chrome.runtime.id};
}
function publish() {
  const data = publicState();
  for (const view of views) {
    try { view.postMessage(data); } catch { views.delete(view); }
  }
}
function failPending(reason) {
  for (const [id, request] of requests) {
    clearTimeout(request.timer);
    request.reject(new Error(reason));
    requests.delete(id);
  }
}
function connectHost() {
  if (nativePort) return;
  try {
    nativePort = chrome.runtime.connectNative(HOST);
    nativePort.onMessage.addListener(response => {
      const id = response?.request_id;
      const match = requests.has(id) ? id : requests.keys().next().value;
      if (match === undefined) return;
      const request = requests.get(match);
      clearTimeout(request.timer);
      requests.delete(match);
      request.resolve(response);
    });
    nativePort.onDisconnect.addListener(() => {
      const error = chrome.runtime.lastError?.message || 'The native host disconnected.';
      nativePort = null;
      token = '';
      status = 'disconnected';
      message = error.includes('not found') || error.includes('forbidden')
        ? 'Install the Belde native host for this extension ID. Open Help for the exact steps.'
        : 'The game connection closed. Start Belde and pair again.';
      failPending(message);
      publish();
    });
  } catch {
    nativePort = null;
    throw new Error('Chrome could not start the Belde native host. Open Help to install it.');
  }
}
function rpc(payload) {
  connectHost();
  const id = ++sequence;
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      requests.delete(id);
      reject(new Error('Belde did not respond. Check that the PC game is still open.'));
    }, 10000);
    requests.set(id, {resolve, reject, timer});
    try { nativePort.postMessage({...payload, request_id: id}); }
    catch (error) { clearTimeout(timer); requests.delete(id); reject(error); }
  });
}
function authorized(op, fields = {}) {
  if (!token) throw new Error('Pair with the PC game before editing.');
  return rpc({op, client_id: clientId, token, ...fields});
}
async function refresh() {
  if (!token || polling) return;
  polling = true;
  try {
    const result = await authorized('state');
    if (!result.ok) {
      if (result.status === 'disconnected') { token = ''; status = 'disconnected'; }
      message = result.message || 'The PC game could not share its state.';
    } else {
      latest = result.state;
      if (Array.isArray(latest?.pending_edits)) pendingCount = latest.pending_edits.length;
      else if (latest?.simulation?.phase !== 'combat') pendingCount = 0;
      if (status !== 'conflict') status = pendingCount ? 'pending' : 'synced';
      if (status === 'synced') message = 'One PC game and this authorized editor are connected.';
    }
    publish();
  } finally { polling = false; }
}
async function act(payload) {
  switch (payload.action) {
    case 'pair': {
      const code = String(payload.code || '').trim();
      if (!/^\d{6}$/.test(code)) throw new Error('Enter the six-digit code shown in Belde.');
      const result = await rpc({op: 'pair', client_id: clientId, code, force: payload.force === true});
      if (!result.ok) {
        status = result.status || 'disconnected';
        message = result.message || 'Pairing failed.';
        publish();
        return result;
      }
      token = result.token;
      status = 'synced';
      message = result.message;
      await refresh();
      return {ok: true, message};
    }
    case 'disconnect': {
      try { if (token) await authorized('disconnect'); } finally {
        token = ''; latest = null; pendingCount = 0; status = 'disconnected';
        message = 'Editor disconnected. The PC game can continue.';
        publish();
      }
      return {ok: true};
    }
    case 'refresh': status = pendingCount ? 'pending' : 'synced'; await refresh(); return {ok: true};
    case 'command': {
      if (!latest) throw new Error('Wait for the PC layout before editing.');
      const revision = Number(latest.revision ?? latest.simulation?.revision ?? 0);
      const result = await authorized('command', {command: payload.command, expected_revision: revision});
      if (!result.ok) {
        status = result.conflict ? 'conflict' : (pendingCount ? 'pending' : 'synced');
        message = result.message || 'The PC rejected this edit.';
      } else {
        if (result.queued || result.status === 'queued' || result.status === 'pending') pendingCount += 1;
        status = pendingCount ? 'pending' : 'synced';
        message = result.message || (pendingCount ? 'Edit queued for a safe planning phase.' : 'Edit applied by the PC game.');
      }
      publish();
      await refresh();
      return result;
    }
    case 'open_editor': {
      if (fullEditorWindow !== null) {
        try { await chrome.windows.update(fullEditorWindow, {focused: true}); return {ok: true}; }
        catch { fullEditorWindow = null; }
      }
      const window = await chrome.windows.create({url: chrome.runtime.getURL('editor.html'), type: 'popup', width: 1280, height: 900});
      fullEditorWindow = window.id;
      return {ok: true};
    }
    case 'help': await chrome.tabs.create({url: chrome.runtime.getURL('help.html')}); return {ok: true};
    case 'get_state': return publicState();
    default: throw new Error('Unknown editor action.');
  }
}
chrome.runtime.onConnect.addListener(view => {
  if (view.name !== 'belde-editor-ui') return;
  views.add(view);
  view.postMessage(publicState());
  view.onDisconnect.addListener(() => views.delete(view));
  view.onMessage.addListener(async payload => {
    try {
      const result = await act(payload);
      view.postMessage({event: 'result', requestId: payload.requestId, ...result});
    } catch (error) {
      message = error.message || 'The editor request failed.';
      if (!nativePort) status = 'disconnected';
      publish();
      try { view.postMessage({event: 'result', requestId: payload.requestId, ok: false, message}); } catch { /* view closed */ }
    }
  });
});
chrome.windows.onRemoved.addListener(id => { if (id === fullEditorWindow) fullEditorWindow = null; });
setInterval(() => { if (token) refresh().catch(error => { message = error.message; publish(); }); }, 500);
setInterval(() => {
  if (token) authorized('heartbeat').then(result => {
    if (!result.ok) { token = ''; status = 'disconnected'; message = result.message; publish(); }
  }).catch(error => { message = error.message; publish(); });
}, 5000);
