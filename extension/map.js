import {position} from './client.js';
export const GRID_W = 32, GRID_H = 20;
export function gridSize(sim) { const g = sim.map?.grid_tiles || [GRID_W, GRID_H]; return [Number(g[0]) || GRID_W, Number(g[1]) || GRID_H]; }
export function pointOnTrack(x, y, points, margin = .55) {
  for (let i = 1; i < points.length; i++) {
    const [ax, ay] = points[i - 1], [bx, by] = points[i], dx = bx - ax, dy = by - ay;
    const t = Math.max(0, Math.min(1, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy || 1)));
    if (Math.hypot(x - ax - t * dx, y - ay - t * dy) <= margin) return true;
  }
  return false;
}
export function previewValidity(sim, tool, cell, movingUid = '') {
  const [width, height] = gridSize(sim), [x, y] = cell;
  if (x < 0 || y < 0 || x >= width || y >= height) return 'Outside the battlefield';
  if (['tower', 'trap', 'unit'].includes(tool)) {
    const near = (entity, margin) => Math.hypot(position(entity)[0] - x, position(entity)[1] - y) < margin;
    if ((sim.map?.blocked_cells || []).some(p => Math.hypot(p[0] - x, p[1] - y) < .7)) return 'Terrain blocks this tile';
    if ((sim.towers || []).some(e => Number(e.hp ?? 1) > 0 && near(e, .8))) return 'A tower occupies this tile';
    if ((sim.units || []).some(e => e.uid !== movingUid && Number(e.hp ?? 1) > 0 && near(e, .75))) return 'An ally occupies this tile';
    if ((sim.traps || []).some(e => e.state === 'armed' && near(e, .65))) return 'A trap occupies this tile';
  }
  if (tool === 'tower') {
    if ((sim.map?.enemy_tracks || []).some(t => pointOnTrack(x, y, t.points || [], .95))) return 'Enemy route must stay open';
    const pads = sim.map?.tower_pad_centers || [];
    if (pads.length && !pads.some(p => Math.hypot(p[0] - x, p[1] - y) < .8)) return 'Build towers on a marked stone pad';
  }
  return '';
}
export function drawMap(canvas, sim, options = {}) {
  const ctx = canvas.getContext('2d'), [gw, gh] = gridSize(sim);
  const sx = canvas.width / gw, sy = canvas.height / gh;
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = '#21343b'; ctx.fillRect(0, 0, canvas.width, canvas.height);
  for (let y = 0; y < gh; y++) for (let x = 0; x < gw; x++) {
    ctx.fillStyle = (x + y) % 2 ? '#253a3e' : '#23363b'; ctx.fillRect(x * sx, y * sy, sx, sy);
  }
  if (options.grid !== false) {
    ctx.strokeStyle = '#d6d6ad18'; ctx.lineWidth = 1;
    for (let x = 0; x <= gw; x++) { ctx.beginPath(); ctx.moveTo(x * sx, 0); ctx.lineTo(x * sx, canvas.height); ctx.stroke(); }
    for (let y = 0; y <= gh; y++) { ctx.beginPath(); ctx.moveTo(0, y * sy); ctx.lineTo(canvas.width, y * sy); ctx.stroke(); }
  }
  function path(points, color, thickness, dashed = false) {
    if (points.length < 2) return;
    ctx.strokeStyle = color; ctx.lineWidth = thickness; ctx.lineCap = 'round'; ctx.lineJoin = 'round'; ctx.setLineDash(dashed ? [sx * .32, sx * .2] : []);
    ctx.beginPath(); points.forEach(([x, y], i) => i ? ctx.lineTo(x * sx + sx / 2, y * sy + sy / 2) : ctx.moveTo(x * sx + sx / 2, y * sy + sy / 2)); ctx.stroke(); ctx.setLineDash([]);
  }
  for (const track of sim.map?.enemy_tracks || []) { path(track.points || [], '#6a5445', Math.min(sx, sy) * 1.1); path(track.points || [], '#c39369', Math.min(sx, sy) * .5); }
  const patrols = sim.ally_patrol_tracks || sim.tracks || sim.map?.ally_patrol_tracks || [];
  for (const track of patrols) path(track.points || track, '#65c6d0', Math.max(2, sx * .1), true);
  for (const pad of sim.map?.tower_pad_centers || []) { ctx.strokeStyle = '#f1c27688'; ctx.lineWidth = 2; ctx.strokeRect(pad[0] * sx + 3, pad[1] * sy + 3, sx - 6, sy - 6); }
  const all = [...(sim.towers || []).map(e => [e, 'tower']), ...(sim.traps || []).map(e => [e, 'trap']), ...(sim.units || []).map(e => [e, 'unit']), ...(sim.enemies || []).map(e => [e, 'enemy'])];
  for (const [entity, kind] of all) {
    const [x, y] = position(entity), px = (x + .5) * sx, py = (y + .5) * sy, radius = Math.min(sx, sy) * .33;
    if (Number(entity.hp ?? 1) <= 0 && kind !== 'trap') continue;
    const chosen = options.selected && entity.uid === options.selected;
    if (chosen) {
      ctx.strokeStyle = '#fff0c6'; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(px, py, radius + 5, 0, Math.PI * 2); ctx.stroke();
      const range = Number(entity.range || entity.stats?.basic_attack?.range_tiles || 0);
      if (range) { ctx.strokeStyle = '#efe4b64d'; ctx.lineWidth = 1; ctx.beginPath(); ctx.ellipse(px, py, range * sx, range * sy, 0, 0, 2 * Math.PI); ctx.stroke(); }
    }
    const role = entity.class || entity.role || '';
    const roleColor = ({Healer:'#9be1cc',DPS:'#eac17b',Tanker:'#91bbd6',Strategist:'#b6a1d2'})[role] || '#a5c996';
    ctx.fillStyle = kind === 'enemy' ? (entity.hostile === false || entity.state === 'surrendered' ? '#eadab7' : '#d87978') : kind === 'tower' ? '#dbb273' : kind === 'trap' ? '#e6bd65' : roleColor;
    ctx.strokeStyle = '#101724'; ctx.lineWidth = 2;
    ctx.beginPath();
    if (kind === 'tower') ctx.rect(px - radius, py - radius, radius * 2, radius * 2);
    else if (kind === 'trap') { for (let i = 0; i < 6; i++) { const a = i * Math.PI / 3; i ? ctx.lineTo(px + Math.cos(a) * radius, py + Math.sin(a) * radius) : ctx.moveTo(px + radius, py); } ctx.closePath(); }
    else if (kind === 'enemy') { ctx.moveTo(px, py - radius); ctx.lineTo(px + radius, py); ctx.lineTo(px, py + radius); ctx.lineTo(px - radius, py); ctx.closePath(); }
    else if (role === 'DPS') { ctx.moveTo(px, py-radius); ctx.lineTo(px+radius,py+radius); ctx.lineTo(px-radius,py+radius); ctx.closePath(); }
    else if (role === 'Tanker') { ctx.moveTo(px-radius,py-radius); ctx.lineTo(px+radius,py-radius); ctx.lineTo(px+radius*.8,py+radius*.5); ctx.lineTo(px,py+radius); ctx.lineTo(px-radius*.8,py+radius*.5); ctx.closePath(); }
    else if (role === 'Strategist') { for(let i=0;i<6;i++){const a=i*Math.PI/3;i?ctx.lineTo(px+Math.cos(a)*radius,py+Math.sin(a)*radius):ctx.moveTo(px+radius,py);}ctx.closePath(); }
    else if (role === 'Healer') { const s=radius*.36;const points=[[-s,-radius],[s,-radius],[s,-s],[radius,-s],[radius,s],[s,s],[s,radius],[-s,radius],[-s,s],[-radius,s],[-radius,-s],[-s,-s]];points.forEach(([x,y],i)=>i?ctx.lineTo(px+x,py+y):ctx.moveTo(px+x,py+y));ctx.closePath(); }
    else ctx.arc(px, py, radius, 0, Math.PI * 2);
    ctx.fill(); ctx.stroke();
    if (entity.max_hp && entity.hp < entity.max_hp) { ctx.fillStyle = '#101724'; ctx.fillRect(px - radius, py - radius - 5, radius * 2, 3); ctx.fillStyle = '#8ed0a1'; ctx.fillRect(px - radius, py - radius - 5, radius * 2 * Math.max(0, entity.hp / entity.max_hp), 3); }
  }
  if (options.trackPoints?.length) path(options.trackPoints, '#f9d38c', 3, true);
  if (options.ghost) {
    const {cell: [x, y], invalid} = options.ghost;
    ctx.fillStyle = invalid ? '#d9787870' : '#7bd4ca60'; ctx.fillRect(x * sx, y * sy, sx, sy);
    ctx.strokeStyle = invalid ? '#ffb7a8' : '#b4fff1'; ctx.lineWidth = 2; ctx.strokeRect(x * sx + 1, y * sy + 1, sx - 2, sy - 2);
    if (invalid) { ctx.beginPath(); ctx.moveTo(x * sx, y * sy); ctx.lineTo((x + 1) * sx, (y + 1) * sy); ctx.moveTo((x + 1) * sx, y * sy); ctx.lineTo(x * sx, (y + 1) * sy); ctx.stroke(); }
  }
}
