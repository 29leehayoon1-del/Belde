import {connectView, statusLabel, simulation} from './client.js';
import {drawMap} from './map.js';
const $ = id => document.getElementById(id);
let paired = false;
const send = connectView(data => {
  paired = data.connected;
  $('status').dataset.status = data.status;
  $('status').textContent = statusLabel(data.status);
  $('message').textContent = data.message || '';
  $('pair-panel').hidden = paired;
  $('connected-panel').hidden = !paired;
  $('session-conflict').hidden = data.status !== 'session_conflict';
  if (data.state) {
    const sim = simulation(data.state);
    $('act').textContent = data.state.campaign?.act || 1;
    $('gate').textContent = Math.ceil(sim.gate_hp ?? 100);
    $('coins').textContent = sim.coins ?? 0;
    $('map-name').textContent = `${sim.map?.name || 'Battlefield'} · ${sim.phase || 'planning'}${data.pendingCount ? ` · ${data.pendingCount} pending` : ''}`;
    drawMap($('map'), sim, {grid: false});
    $('undo').disabled = sim.phase === 'combat';
    $('redo').disabled = sim.phase === 'combat';
  }
}, data => { if (!data.ok && data.message) $('message').textContent = data.message; });
$('connect').onclick = () => send('pair', {code: $('code').value});
$('takeover').onclick = () => send('pair', {code: $('code').value, force: true});
$('code').addEventListener('input', () => { $('code').value = $('code').value.replace(/\D/g, '').slice(0, 6); });
$('code').addEventListener('keydown', e => { if (e.key === 'Enter') send('pair', {code: $('code').value}); });
$('open-editor').onclick = () => send('open_editor');
$('disconnect').onclick = () => send('disconnect');
$('refresh').onclick = () => send('refresh');
$('undo').onclick = () => send('command', {command: {kind: 'undo'}});
$('redo').onclick = () => send('command', {command: {kind: 'redo'}});
$('help').onclick = () => send('help');
