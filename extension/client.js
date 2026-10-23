export function connectView(onState, onResult = () => {}) {
  const port = chrome.runtime.connect({name: 'belde-editor-ui'});
  let nextId = 0;
  const waiting = new Map();
  port.onMessage.addListener(data => {
    if (data.event === 'state') onState(data);
    else if (data.event === 'result') {
      if (waiting.has(data.requestId)) { waiting.get(data.requestId)(data); waiting.delete(data.requestId); }
      onResult(data);
    }
  });
  port.onDisconnect.addListener(() => onState({connected: false, status: 'disconnected', message: 'The browser editor closed its connection. Reopen this window.'}));
  return (action, fields = {}) => new Promise(resolve => {
    const requestId = ++nextId;
    waiting.set(requestId, resolve);
    port.postMessage({action, requestId, ...fields});
  });
}
export function statusLabel(status) {
  return ({synced: 'Synced', pending: 'Pending', conflict: 'Conflict', disconnected: 'Disconnected', session_conflict: 'Session conflict'})[status] || 'Disconnected';
}
export function position(entity) {
  const value = entity.pos || entity.cell || entity.position || [0, 0];
  return Array.isArray(value) ? value : [value.x || 0, value.y || 0];
}
export function simulation(state) { return state?.simulation || {}; }
