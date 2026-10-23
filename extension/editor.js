import {connectView, statusLabel, simulation, position} from './client.js';
import {drawMap, gridSize, previewValidity} from './map.js';
const $ = id => document.getElementById(id), canvas = $('map');
const TOWERS = [['TOWER01', 'Palisade Roost', 'Ranged cover'], ['TOWER02', 'Waybell Beacon', 'Route support'], ['TOWER03', 'Hearthward', 'Limited recovery'], ['TOWER04', 'Bolt Cradle', 'Anti-siege']];
const TRAPS = [['TRAP01', 'Snare Stitch', 'Slow'], ['TRAP02', 'Cinder Pot', 'Area damage'], ['TRAP03', 'Decoy Standard', 'Distract']];
let state = null, sim = {}, connected = false, tool = 'select', chosen = null, selected = '', ghost = null, trackPoints = [], drag = null, pointerStart = null, history = [];
const send = connectView(update, result => { if (!result.ok && result.message) $('preview-reason').textContent = result.message; });
function update(data) {
  connected = data.connected;
  $('status').textContent = statusLabel(data.status); $('status').dataset.status = data.status;
  $('message').textContent = data.message || '';
  $('pair-overlay').hidden = connected;
  $('session-conflict').hidden = data.status !== 'session_conflict';
  if (!data.state) return;
  const priorParty = JSON.stringify(state?.campaign?.party || []);
  state = data.state; sim = simulation(state);
  $('map-name').textContent = sim.map?.name || 'Battlefield';
  $('gate').textContent = Math.ceil(sim.gate_hp ?? 100); $('coins').textContent = sim.coins ?? 0; $('wave').textContent = `${sim.wave ?? 0}/${sim.max_waves ?? 4}`;
  $('phase').textContent = `${sim.phase || 'planning'}${data.pendingCount ? ` · ${data.pendingCount} queued edits` : ''}`;
  $('revision').textContent = `Layout ${state.revision ?? sim.revision ?? 0} · ${statusLabel(data.status)}`;
  $('undo').disabled = sim.phase === 'combat'; $('redo').disabled = sim.phase === 'combat';
  if (priorParty !== JSON.stringify(state.campaign?.party || []) || !$('palette').childElementCount) buildPalette();
  updateTrackSelector(); updateSelection(); render();
}
function render() { drawMap(canvas, sim, {selected, ghost, trackPoints}); }
function allEntities() { return [...(sim.units || []).map(e => ({...e, type: 'unit'})), ...(sim.towers || []).map(e => ({...e, type: 'tower'})), ...(sim.traps || []).map(e => ({...e, type: 'trap'}))]; }
function character(id) {
  const source = state?.characters || [];
  return Array.isArray(source) ? (source.find(c => c.id === id) || {}) : (source[id] || {});
}
function buildPalette() {
  const palette = $('palette'); palette.replaceChildren(); $('track-controls').hidden = tool !== 'track';
  $('palette-label').textContent = ({select: 'Your formation', unit: 'Deploy or reposition', tower: 'Defensive structures', trap: 'Field tools', track: 'Connected waypoints'})[tool];
  let items = [];
  if (tool === 'tower') items = TOWERS.map(([id, name, detail]) => ({id, name, detail, type: 'tower'}));
  else if (tool === 'trap') items = TRAPS.map(([id, name, detail]) => ({id, name, detail, type: 'trap'}));
  else if (tool !== 'track') {
    const ids = state?.campaign?.party || (sim.units || []).map(u => u.id);
    items = ids.map(value => {
      const id = typeof value === 'string' ? value : value.id;
      const model = character(id), deployed = (sim.units || []).find(u => u.id === id && u.hp > 0);
      return {id, uid: deployed?.uid, name: model.name || deployed?.name || id, detail: model.class || deployed?.class || 'Ally', type: 'unit'};
    });
  }
  for (const item of items) {
    const button = document.createElement('button'); button.draggable = true; button.dataset.id = item.id;
    const label = document.createElement('strong'); label.textContent = item.name;
    const detail = document.createElement('small'); detail.textContent = item.detail; detail.style.display = 'block';
    button.append(label, detail);
    button.onclick = () => {
      chosen = item;
      if (tool === 'select' && item.uid) { selected = item.uid; updateSelection(); }
      else if (tool === 'select') setTool('unit');
      for (const child of palette.children) child.classList.toggle('selected', child === button);
      render();
    };
    button.addEventListener('dragstart', e => {
      drag = item; chosen = item;
      e.dataTransfer.setData('application/x-belde-object', JSON.stringify(item)); e.dataTransfer.effectAllowed = 'copyMove';
    });
    button.addEventListener('dragend', () => { drag = null; ghost = null; render(); });
    palette.append(button);
  }
  if (!chosen || !items.some(i => i.id === chosen.id)) chosen = items[0] || null;
}
function setTool(next) {
  tool = next; ghost = null; pointerStart = null;
  for (const button of document.querySelectorAll('[data-tool]')) button.classList.toggle('active', button.dataset.tool === tool);
  buildPalette(); render();
}
function cellAt(event) {
  const rect = canvas.getBoundingClientRect(), ratio = canvas.width / canvas.height;
  let width = rect.width, height = rect.height, left = rect.left, top = rect.top;
  if (width / height > ratio) { const actual = height * ratio; left += (width - actual) / 2; width = actual; }
  else { const actual = width / ratio; top += (height - actual) / 2; height = actual; }
  const [gw, gh] = gridSize(sim);
  return [Math.floor((event.clientX - left) / width * gw), Math.floor((event.clientY - top) / height * gh)];
}
function roostAt(cell) { return (sim.towers || []).find(t => t.id === 'TOWER01' && Number(t.hp ?? 1) > 0 && Math.hypot(position(t)[0] - cell[0], position(t)[1] - cell[1]) < .7); }
function showGhost(cell, item = chosen) {
  const type = item?.type || tool;
  let invalid = previewValidity(sim, type, cell, item?.uid || '');
  const roost = type === 'unit' ? roostAt(cell) : null;
  if (roost && item?.uid) {
    const unit = (sim.units || []).find(u => u.uid === item.uid);
    const ranged = character(item.id || unit?.id).tower_eligible || unit?.ranged;
    invalid = !ranged ? 'Melee allies cannot fire from a roost' : (sim.units || []).some(u => u.tower_uid === roost.uid && u.uid !== item.uid) ? 'This roost already has an occupant' : '';
  }
  ghost = {cell, invalid}; $('coordinates').textContent = `Tile ${cell[0]}, ${cell[1]} · ${gridSize(sim).join(' × ')}`;
  $('preview-reason').textContent = invalid || (type === 'track' ? 'Click to extend a connected patrol route.' : 'Valid preview. The PC will confirm the edit.');
  render(); return invalid;
}
async function command(cmd, label) {
  if (!connected) return;
  const result = await send('command', {command: cmd});
  if (result.ok) { history.unshift(`${result.queued || ['queued', 'pending'].includes(result.status) ? 'Pending · ' : ''}${label}`); history = history.slice(0, 8); }
  const list = $('history'); list.replaceChildren();
  for (const line of history) { const li = document.createElement('li'); li.textContent = line; list.append(li); }
  if (result.message) $('preview-reason').textContent = result.message;
  ghost = null; render();
  return result;
}
function place(item, cell) {
  if (!item || showGhost(cell, item)) return;
  if (item.type === 'unit' && item.uid && roostAt(cell)) return command({kind: 'assign_tower', uid: item.uid, tower_uid: roostAt(cell).uid}, `Assign ${item.name} to roost`);
  if (item.type === 'unit') return command(item.uid ? {kind: 'move_unit', uid: item.uid, cell} : {kind: 'place_unit', id: item.id, cell, mode: 'Guard'}, `${item.uid ? 'Move' : 'Deploy'} ${item.name}`);
  if (item.type === 'tower') return command({kind: 'place_tower', tower_id: item.id, cell}, `Build ${item.name}`);
  if (item.type === 'trap') return command({kind: 'place_trap', trap_id: item.id, cell}, `Place ${item.name}`);
}
function nearest(cell) {
  return allEntities().map(e => ({...e, distance: Math.hypot(position(e)[0] - cell[0], position(e)[1] - cell[1])})).filter(e => e.distance < 1).sort((a, b) => a.distance - b.distance)[0];
}
function addTrackPoint(cell) {
  const [gw, gh] = gridSize(sim);
  if (cell[0] < 0 || cell[1] < 0 || cell[0] >= gw || cell[1] >= gh) return;
  if (!trackPoints.length) trackPoints.push(cell);
  else {
    let [x, y] = trackPoints.at(-1);
    while ((x !== cell[0] || y !== cell[1]) && trackPoints.length < 64) {
      if (x !== cell[0]) x += Math.sign(cell[0] - x); else y += Math.sign(cell[1] - y);
      if (trackPoints.slice(0, -1).some(p => p[0] === x && p[1] === y)) { $('preview-reason').textContent = 'A patrol path cannot loop over an existing preview tile.'; break; }
      trackPoints.push([x, y]);
    }
  }
  $('apply-track').disabled = trackPoints.length < 2;
  $('preview-reason').textContent = `${trackPoints.length} connected patrol nodes. Apply to ask the PC to validate them.`;
  render();
}
function updateTrackSelector() {
  const tracks = sim.ally_patrol_tracks || sim.tracks || sim.map?.ally_patrol_tracks || [];
  const current = $('track-id').value;
  const ids = tracks.filter(t => t.id).map(t => t.id);
  if (!ids.length) ids.push('patrol-editor');
  if (JSON.stringify([...$('track-id').options].map(o => o.value)) === JSON.stringify(ids)) return;
  $('track-id').replaceChildren();
  for (const id of ids) { const option = document.createElement('option'); option.value = id; option.textContent = id; $('track-id').append(option); }
  if (ids.includes(current)) $('track-id').value = current;
}
function updateSelection() {
  const entity = allEntities().find(e => e.uid === selected), section = $('selection'); section.replaceChildren();
  $('unit-properties').hidden = !entity || entity.type !== 'unit'; $('upgrade').hidden = !entity || entity.type !== 'tower'; $('salvage').hidden = !entity || !['tower', 'trap'].includes(entity.type);
  if (!entity) { const p = document.createElement('p'); p.className = 'muted'; p.textContent = 'Select a unit, tower or trap to inspect it.'; section.append(p); return; }
  const model = character(entity.id), title = document.createElement('h3'); title.textContent = model.name || entity.name || entity.id || entity.uid;
  const info = document.createElement('p'); info.className = 'muted'; info.textContent = `${entity.type} · Tile ${position(entity).map(n => Number(n).toFixed(1)).join(', ')}${entity.hp !== undefined ? ` · HP ${Math.ceil(entity.hp)}/${entity.max_hp || entity.hp}` : ''}`;
  section.append(title, info);
  if (entity.type === 'unit') { $('inspect-roost').hidden = !entity.tower_uid; $('mode').value = entity.mode || 'Guard'; $('ability-a').disabled = sim.phase !== 'combat' || Number(entity.cooldowns?.[0] || 0) > 0; $('ability-b').disabled = sim.phase !== 'combat' || Number(entity.cooldowns?.[1] || 0) > 0; }
  if (entity.type === 'tower') { $('upgrade').textContent = `Upgrade tower · ${entity.level || 1}/3`; $('upgrade').disabled = Number(entity.level || 1) >= 3; }
}
canvas.addEventListener('pointerdown', event => {
  if (!connected || event.button !== 0) return;
  const cell = cellAt(event);
  if (tool === 'track') { addTrackPoint(cell); return; }
  if (tool !== 'select') { place(chosen, cell); return; }
  const entity = nearest(cell); selected = entity?.uid || ''; updateSelection(); render();
  if (entity?.type === 'unit') { pointerStart = {x: event.clientX, y: event.clientY, entity}; canvas.setPointerCapture(event.pointerId); }
});
canvas.addEventListener('pointermove', event => {
  if (!connected) return;
  const cell = cellAt(event);
  if (pointerStart) showGhost(cell, {type: 'unit', uid: pointerStart.entity.uid});
  else if (tool !== 'select') showGhost(cell);
  else $('coordinates').textContent = `Tile ${cell.join(', ')} · ${gridSize(sim).join(' × ')}`;
});
canvas.addEventListener('pointerup', event => {
  if (!pointerStart) return;
  const saved = pointerStart; pointerStart = null;
  if (Math.hypot(event.clientX - saved.x, event.clientY - saved.y) > 4) {
    const cell = cellAt(event); const item = {type: 'unit', id: saved.entity.id, uid: saved.entity.uid, name: character(saved.entity.id).name || saved.entity.id}; place(item, cell);
  } else { ghost = null; render(); }
});
canvas.addEventListener('pointercancel', () => { pointerStart = null; ghost = null; render(); });
canvas.addEventListener('pointerleave', () => { if (!pointerStart && !drag) { ghost = null; render(); } });
canvas.addEventListener('dragover', event => { if (!connected || !drag) return; event.preventDefault(); event.dataTransfer.dropEffect = drag.uid ? 'move' : 'copy'; showGhost(cellAt(event), drag); });
canvas.addEventListener('drop', event => {
  event.preventDefault();
  let item = drag;
  if (!item) { try { item = JSON.parse(event.dataTransfer.getData('application/x-belde-object')); } catch { return; } }
  if (item && ['unit', 'tower', 'trap'].includes(item.type)) place(item, cellAt(event));
  drag = null;
});
for (const button of document.querySelectorAll('[data-tool]')) button.onclick = () => setTool(button.dataset.tool);
$('connect').onclick = () => send('pair', {code: $('code').value}); $('takeover').onclick = () => send('pair', {code: $('code').value, force: true});
$('code').oninput = () => { $('code').value = $('code').value.replace(/\D/g, '').slice(0, 6); };
$('refresh').onclick = () => send('refresh'); $('help').onclick = () => send('help'); $('disconnect').onclick = () => send('disconnect');
$('undo').onclick = () => command({kind: 'undo'}, 'Undo layout'); $('redo').onclick = () => command({kind: 'redo'}, 'Redo layout');
$('inspect-roost').onclick = () => { const e = allEntities().find(e => e.uid === selected); if (e?.tower_uid) { selected = e.tower_uid; updateSelection(); render(); } };
$('mode').onchange = () => command({kind: 'set_mode', uid: selected, mode: $('mode').value}, `Set ${$('mode').value}`);
$('ability-a').onclick = () => command({kind: 'cast', uid: selected, slot: 0}, 'Use ability I'); $('ability-b').onclick = () => command({kind: 'cast', uid: selected, slot: 1}, 'Use ability II');
$('upgrade').onclick = () => command({kind: 'upgrade_tower', uid: selected}, 'Upgrade tower');
$('salvage').onclick = () => { const e = allEntities().find(e => e.uid === selected); if (e && ['tower', 'trap'].includes(e.type)) command({kind: e.type === 'tower' ? 'remove_tower' : 'remove_trap', uid: selected}, 'Salvage defense'); };
$('clear-track').onclick = () => { trackPoints = []; $('apply-track').disabled = true; ghost = null; render(); };
$('apply-track').onclick = async () => { if (trackPoints.length < 2) return; const result = await command({kind: 'set_track', track_id: $('track-id').value || 'patrol-editor', points: trackPoints}, 'Update patrol track'); if (result?.ok) { trackPoints = []; $('apply-track').disabled = true; render(); } };
document.addEventListener('keydown', event => {
  if (['INPUT', 'SELECT', 'TEXTAREA'].includes(event.target.tagName)) { if (event.key === 'Enter' && event.target === $('code')) send('pair', {code: $('code').value}); return; }
  if (event.key === 'Escape') { pointerStart = null; drag = null; ghost = null; trackPoints = []; $('apply-track').disabled = true; render(); }
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'z') { event.preventDefault(); if (connected && sim.phase !== 'combat') command({kind: event.shiftKey ? 'redo' : 'undo'}, event.shiftKey ? 'Redo layout' : 'Undo layout'); }
  if (event.key === 'Enter' && tool === 'track') $('apply-track').click();
});
render();
