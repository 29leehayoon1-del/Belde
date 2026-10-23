"""Actual editor/popup modules in Chromium with an explicit mock Chrome Port transport.

This validates UI interaction, not browser Native Messaging installation. The worker,
native transport and Godot bridge have separate real-protocol integration checks.
"""
from pathlib import Path
import functools,http.server,json,os,tempfile,threading
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]
STATE={'revision':1,'campaign':{'act':1,'party':['BAR01','BAR02']},'characters':[{'id':'BAR01','name':'Tornel Ashhand','class':'DPS','tower_eligible':True},{'id':'BAR02','name':'Maela Rootglass','class':'Healer'}],'simulation':{'revision':1,'map':{'name':'Hinge Gate','grid_tiles':[32,20],'enemy_tracks':[{'id':'enemy','points':[[0,10],[31,10]]}],'ally_patrol_tracks':[{'id':'patrol-north','points':[[2,3],[12,3]]}],'tower_pad_centers':[[4,6]]},'units':[{'id':'BAR01','uid':'u1','name':'Tornel','pos':[5,5],'hp':90,'max_hp':90,'range':3,'mode':'Guard','cooldowns':[0,0]},{'id':'BAR02','uid':'u2','name':'Maela','pos':[7,5],'hp':100,'max_hp':100,'range':3,'mode':'Guard','cooldowns':[0,0]}],'enemies':[],'towers':[],'traps':[],'coins':150,'gate_hp':100,'phase':'planning','wave':0,'max_waves':4}}
MOCK=r'''
(() => {
 const state=__STATE__,listeners=[],commands=[];let paired=true,status='synced',pendingCount=0;
 function emit(){const value={event:'state',connected:paired,status,message:paired?'One connected pair.':'Disconnected',state:paired?structuredClone(state):null,pendingCount};for(const fn of listeners)fn(value)}
 window.__beldeHarness={commands,state,setPhase(phase){state.simulation.phase=phase;emit()},setStatus(value){status=value;emit()}};
 window.chrome={runtime:{id:'ngolglhaedkpheljgabbfafifbimmlle',connect(){
  const port={onMessage:{addListener(fn){listeners.push(fn);queueMicrotask(emit)}},onDisconnect:{addListener(){}},postMessage(request){
   let result={ok:true,message:'Applied by the test PC'};
   if(request.action==='pair'){paired=true;status='synced'}
   if(request.action==='disconnect'){paired=false;status='disconnected'}
   if(request.action==='command'){
    const cmd=structuredClone(request.command);commands.push(cmd);state.revision++;state.simulation.revision=state.revision;
    if(cmd.kind==='move_unit'){const u=state.simulation.units.find(u=>u.uid===cmd.uid);if(u)u.pos=cmd.cell;}
    if(cmd.kind==='assign_tower'){const u=state.simulation.units.find(u=>u.uid===cmd.uid),t=state.simulation.towers.find(t=>t.uid===cmd.tower_uid);if(u&&t){u.tower_uid=t.uid;u.pos=t.pos;}}
    if(cmd.kind==='remove_tower'){state.simulation.towers=state.simulation.towers.filter(t=>t.uid!==cmd.uid);for(const u of state.simulation.units)if(u.tower_uid===cmd.uid)u.tower_uid='';}
    if(cmd.kind==='set_mode'){const u=state.simulation.units.find(u=>u.uid===cmd.uid);if(u)u.mode=cmd.mode;}
    if(cmd.kind==='place_tower')state.simulation.towers.push({id:cmd.tower_id,uid:'t'+state.revision,pos:cmd.cell,hp:100,max_hp:100,level:1});
    if(cmd.kind==='place_trap')state.simulation.traps.push({id:cmd.trap_id,uid:'r'+state.revision,pos:cmd.cell});
   }
   queueMicrotask(()=>{for(const fn of listeners)fn({event:'result',requestId:request.requestId,...result});emit()});
  }};return port;
 }}};
})();
'''.replace('__STATE__',json.dumps(STATE))
class Quiet(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*args):pass

def main():
 server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(Quiet,directory=str(ROOT/'extension')))
 thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start()
 with tempfile.TemporaryDirectory(prefix='belde-ui-') as tmp:
  env=os.environ.copy();env['XDG_CONFIG_HOME']=tmp+'/config';env['XDG_CACHE_HOME']=tmp+'/cache';env['XDG_DATA_HOME']=tmp+'/data'
  try:
   with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,env=env,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1280,'height':900});page.add_init_script(MOCK)
    errors=[];page.on('pageerror',lambda error:errors.append(str(error)))
    page.goto(f'http://127.0.0.1:{server.server_port}/editor.html')
    page.wait_for_function('document.getElementById("pair-overlay").hidden')
    assert page.locator('#status').inner_text()=='Synced'
    # Exercise the shipped preview rules against the same types of constraints
    # supplied by the real Godot snapshot; units may engage on enemy lanes.
    previews=page.evaluate('''async () => {
      const {previewValidity}=await import('./map.js');
      const sim=structuredClone(window.__beldeHarness.state.simulation);
      sim.map.blocked_cells=[[12,8]];
      sim.units.push({uid:'fallen',pos:[10,8],hp:0});
      sim.traps.push({uid:'spent',pos:[11,8],state:'spent'});
      return {laneUnit:previewValidity(sim,'unit',[4,10]),laneTower:previewValidity(sim,'tower',[4,10]),
        offPad:previewValidity(sim,'tower',[5,6]),blocked:previewValidity(sim,'trap',[12,8]),
        fallen:previewValidity(sim,'unit',[10,8]),spent:previewValidity(sim,'unit',[11,8])};
    }''')
    assert previews=={'laneUnit':'','laneTower':'Enemy route must stay open','offPad':'Build towers on a marked stone pad','blocked':'Terrain blocks this tile','fallen':'','spent':''},previews
    canvas=page.locator('#map')
    def at(x,y):
     r=canvas.bounding_box();ratio=1024/640;width=r['width'];height=r['height'];left=r['x'];top=r['y']
     if width/height>ratio:
      actual=height*ratio;left+=(width-actual)/2;width=actual
     else:
      actual=width/ratio;top+=(height-actual)/2;height=actual
     return left+(x+.5)*width/32,top+(y+.5)*height/20
    def click(x,y):page.mouse.click(*at(x,y))
    page.locator('[data-tool=tower]').click();click(4,6)
    page.wait_for_function('window.__beldeHarness.commands.length===1')
    assert page.evaluate('window.__beldeHarness.commands[0]')=={'kind':'place_tower','tower_id':'TOWER01','cell':[4,6]}
    click(4,10)
    assert 'Enemy route' in page.locator('#preview-reason').inner_text()
    assert page.evaluate('window.__beldeHarness.commands.length')==1
    page.locator('[data-tool=select]').click();click(5,5)
    assert 'Tornel Ashhand' in page.locator('#selection').inner_text()
    page.mouse.move(*at(5,5));page.mouse.down();page.mouse.move(*at(8,10),steps=10)
    assert 'Valid preview' in page.locator('#preview-reason').inner_text()
    page.mouse.move(*at(8,7),steps=10);page.mouse.up()
    page.wait_for_function('window.__beldeHarness.commands.length===2')
    assert page.evaluate('window.__beldeHarness.commands[1]')=={'kind':'move_unit','uid':'u1','cell':[8,7]}
    page.locator('#mode').select_option('Patrol');page.wait_for_function('window.__beldeHarness.commands.length===3')
    assert page.evaluate('window.__beldeHarness.commands[2].mode')=='Patrol'
    page.locator('[data-tool=track]').click();click(2,2);click(5,2);click(5,4);page.locator('#apply-track').click()
    page.wait_for_function('window.__beldeHarness.commands.length===4')
    track=page.evaluate('window.__beldeHarness.commands[3]');assert track['kind']=='set_track' and len(track['points'])==6
    assert all(abs(a[0]-b[0])+abs(a[1]-b[1])==1 for a,b in zip(track['points'],track['points'][1:]))
    page.locator('[data-tool=trap]').click()
    r=canvas.bounding_box();target=at(12,7)
    page.locator('#palette [data-id=TRAP01]').drag_to(canvas,target_position={'x':target[0]-r['x'],'y':target[1]-r['y']})
    page.wait_for_function('window.__beldeHarness.commands.length===5')
    assert page.evaluate('window.__beldeHarness.commands[4]')=={'kind':'place_trap','trap_id':'TRAP01','cell':[12,7]}
    page.locator('#undo').click();page.locator('#redo').click();page.wait_for_function('window.__beldeHarness.commands.length===7')
    assert page.evaluate('window.__beldeHarness.commands.slice(-2).map(c=>c.kind)')==['undo','redo']
    page.locator('[data-tool=select]').click();click(8,7)
    page.mouse.move(*at(8,7));page.mouse.down();page.mouse.move(*at(4,6),steps=10);page.mouse.up()
    page.wait_for_function('window.__beldeHarness.commands.length===8')
    assert page.evaluate('window.__beldeHarness.commands[7]')=={'kind':'assign_tower','uid':'u1','tower_uid':'t2'}
    assert page.locator('#inspect-roost').is_visible();page.locator('#inspect-roost').click()
    assert page.locator('#salvage').is_visible();page.locator('#salvage').click()
    page.wait_for_function('window.__beldeHarness.commands.length===9')
    assert page.evaluate('window.__beldeHarness.commands[8]')=={'kind':'remove_tower','uid':'t2'}
    click(4,6)
    page.evaluate('window.__beldeHarness.setPhase("combat")');assert page.locator('#undo').is_disabled()
    page.locator('#ability-a').click();page.wait_for_function('window.__beldeHarness.commands.length===10')
    assert page.evaluate('window.__beldeHarness.commands[9]')=={'kind':'cast','uid':'u1','slot':0}
    page.evaluate('window.__beldeHarness.setStatus("conflict")');assert page.locator('#status').inner_text()=='Conflict'
    page.screenshot(path='/tmp/belde-editor-ui-review.png')
    page.goto(f'http://127.0.0.1:{server.server_port}/popup.html');page.wait_for_function('!document.getElementById("connected-panel").hidden')
    assert page.locator('#act').inner_text()=='1';assert page.locator('#map-name').inner_text().startswith('Hinge Gate')
    page.locator('#disconnect').click();page.wait_for_function('!document.getElementById("pair-panel").hidden')
    page.locator('#code').fill('123456');page.locator('#connect').click();page.wait_for_function('!document.getElementById("connected-panel").hidden')
    assert not errors,errors
    browser.close()
   print('PASS: actual Chromium editor/popup modules: paired layout, grid placement, route collision preview, unit drag, mode, connected tracks, HTML drag/drop trap, roost assignment/inspection/salvage, undo/redo, combat ability, conflict, reconnect. Chrome Port transport mocked explicitly.')
  finally:server.shutdown();server.server_close();thread.join(timeout=2)
if __name__=='__main__':main()
