// Actual MV3 background.js logic + C native host + real Godot server.
// Chrome's runtime Port API is adapted in Node; this is not a Chrome install test.
import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import {webcrypto} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const [port,code,mode]=process.argv.slice(2);
const actualGame=mode==='actual';let staleNext=false;
class Event { constructor(){this.listeners=[];} addListener(fn){this.listeners.push(fn);} emit(...args){for(const fn of this.listeners)fn(...args);} }
const hosts=[],timers=[];
function nativeHost(){
  const process=spawn(path.join(root,'native/bin/belde_host'),[],{env:{...globalThis.process.env,BELDE_BRIDGE_PORT:port},stdio:['pipe','pipe','pipe']});
  let buffer=Buffer.alloc(0);
  const host={onMessage:new Event(),onDisconnect:new Event(),postMessage(message){if(staleNext&&message.op==='command'){message={...message,expected_revision:Math.max(0,message.expected_revision-1)};staleNext=false;}const bytes=Buffer.from(JSON.stringify(message)),header=Buffer.alloc(4);header.writeUInt32LE(bytes.length);process.stdin.write(Buffer.concat([header,bytes]));},disconnect(){process.kill();},process};
  process.stdout.on('data',chunk=>{buffer=Buffer.concat([buffer,chunk]);while(buffer.length>=4){const n=buffer.readUInt32LE(0);if(buffer.length<4+n)break;const message=JSON.parse(buffer.subarray(4,4+n).toString());buffer=buffer.subarray(4+n);host.onMessage.emit(message);}});
  process.on('exit',()=>host.onDisconnect.emit());hosts.push(host);return host;
}
const chrome={runtime:{id:'ngolglhaedkpheljgabbfafifbimmlle',onConnect:new Event(),connectNative:nativeHost,getURL:value=>`chrome-extension://test/${value}`,lastError:null},windows:{onRemoved:new Event(),async create(){return{id:1}},async update(){return{id:1}}},tabs:{async create(){return{id:1}}}};
const context=vm.createContext({chrome,crypto:webcrypto,console,setTimeout,clearTimeout,setInterval(fn,ms){const id=setInterval(fn,ms);timers.push(id);return id;},clearInterval});
vm.runInContext(fs.readFileSync(path.join(root,'extension/background.js'),'utf8'),context,{filename:'background.js'});
let sequence=0;
function view(){
  const ui={onMessage:new Event(),onDisconnect:new Event(),name:'belde-editor-ui'},bg={onMessage:new Event(),onDisconnect:new Event(),name:'belde-editor-ui'};
  ui.postMessage=value=>queueMicrotask(()=>bg.onMessage.emit(value));bg.postMessage=value=>queueMicrotask(()=>ui.onMessage.emit(value));
  const waiting=new Map(),states=[];
  ui.onMessage.addListener(value=>{if(value.event==='state')states.push(value);if(value.event==='result'&&waiting.has(value.requestId)){waiting.get(value.requestId)(value);waiting.delete(value.requestId);}});
  chrome.runtime.onConnect.emit(bg);
  return{states,async send(action,fields={}){const requestId=++sequence;return new Promise((resolve,reject)=>{const timer=setTimeout(()=>reject(new Error('Worker test timed out')),12000);waiting.set(requestId,response=>{clearTimeout(timer);resolve(response)});ui.postMessage({action,requestId,...fields});});}};
}
const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms));
async function until(fn){for(let n=0;n<80;n++){if(fn())return;await delay(100);}throw new Error('Worker state did not converge');}
try{
  const popup=view();
  await delay(10);assert.equal(popup.states.at(-1).connected,false);
  const paired=await popup.send('pair',{code});assert.equal(paired.ok,true);
  await until(()=>popup.states.at(-1)?.connected===true);
  assert.equal(popup.states.at(-1).state.campaign.act,1);
  assert.equal(Object.hasOwn(popup.states.at(-1),'token'),false);
  const editor=view();await until(()=>editor.states.at(-1)?.connected===true);
  const before=editor.states.at(-1).state.revision;
  const placedCell=actualGame?[8,6]:[4,6];
  const edited=await editor.send('command',{command:{kind:'place_tower',tower_id:'TOWER01',cell:placedCell}});assert.equal(edited.ok,true);
  await until(()=>popup.states.at(-1).state.revision===before+1&&editor.states.at(-1).state.revision===before+1);
  const state=editor.states.at(-1).state;
  if(actualGame)assert.equal(state.simulation.towers.some(t=>t.id==='TOWER01'&&t.pos[0]===8&&t.pos[1]===6),true);
  else assert.deepEqual(state.commands.at(-1).cell,[4,6]);
  // Deliberately deliver an older authored revision to model a concurrent PC edit.
  staleNext=true;
  const rejected=await editor.send('command',{command:{kind:'place_tower',tower_id:'TOWER04',cell:[14,6]}});assert.equal(rejected.ok,false);assert.equal(rejected.conflict,true);
  await until(()=>editor.states.at(-1).status==='conflict');
  await editor.send('refresh');await until(()=>editor.states.at(-1).status==='synced');
  if(actualGame){
    // Match the editor's placement rules to actual game commands, including
    // mobile allies engaging on lanes while towers remain on marked pads.
    const ally=editor.states.at(-1).state.simulation.units.find(u=>u.hp>0&&u.ranged);
    assert.ok(ally,'Battle preview needs one ranged party ally');
    const moved=await editor.send('command',{command:{kind:'move_unit',uid:ally.uid,cell:[4,8]}});assert.equal(moved.ok,true);
    assert.deepEqual(editor.states.at(-1).state.simulation.units.find(u=>u.uid===ally.uid).pos,[4,8]);
    const roost=editor.states.at(-1).state.simulation.towers.find(t=>t.id==='TOWER01');
    const assigned=await editor.send('command',{command:{kind:'assign_tower',uid:ally.uid,tower_uid:roost.uid}});assert.equal(assigned.ok,true);
    assert.equal(editor.states.at(-1).state.simulation.units.find(u=>u.uid===ally.uid).tower_uid,roost.uid);
    const mode=await editor.send('command',{command:{kind:'set_mode',uid:ally.uid,mode:'Patrol'}});assert.equal(mode.ok,true);
    const route=await editor.send('command',{command:{kind:'set_track',track_id:'patrol-north',points:[[5,5],[6,5],[7,5]]}});assert.equal(route.ok,true);
    const beforeInvalid=editor.states.at(-1).state.revision;
    const overlong=await editor.send('command',{command:{kind:'set_track',track_id:'patrol-north',points:Array.from({length:65},(_,i)=>[5+i%2,5])}});
    assert.equal(overlong.ok,false);assert.equal(editor.states.at(-1).state.revision,beforeInvalid);
    assert.equal((await editor.send('command',{command:{kind:'undo'}})).ok,true);
    assert.equal((await editor.send('command',{command:{kind:'redo'}})).ok,true);
    const wave=await editor.send('command',{command:{kind:'start_wave'}});assert.equal(wave.ok,true);
    await until(()=>editor.states.at(-1).state.simulation.phase==='combat');
    const queued=await editor.send('command',{command:{kind:'place_trap',trap_id:'TRAP01',cell:[9,8]}});
    assert.equal(queued.ok,true);assert.equal(queued.status,'queued');
    await until(()=>editor.states.at(-1).pendingCount===1);
    assert.equal(editor.states.at(-1).state.simulation.traps.length,0);
    const duplicateWave=await editor.send('command',{command:{kind:'start_wave'}});
    assert.equal(duplicateWave.ok,false);
    assert.equal(editor.states.at(-1).pendingCount,1,'A rejected duplicate start must retain queued layout edits');
    assert.equal(editor.states.at(-1).state.simulation.traps.length,0);
  }
  // Run longer than the fixture's 1.2-second lease: polling/heartbeat keep it alive.
  await delay(1700);assert.equal(editor.states.at(-1).connected,true);
  await popup.send('disconnect');await until(()=>editor.states.at(-1).connected===false&&popup.states.at(-1).connected===false);
  console.log((actualGame?'ACTUAL GAME ':'')+'PASS: actual background.js pairing, shared popup/editor lease, authoritative edit, conflict/review, keepalive and disconnect through C host + Godot HTTP. Chrome Port API adapted in Node.');
}finally{for(const id of timers)clearInterval(id);for(const host of hosts)host.disconnect();}
