"""Actual game/campaign/simulation callbacks through worker logic and the C host.

Chrome Port API is adapted in Node because the managed browser blocks unpacked
extensions. This runs the real game scene, not the Godot mock-callback fixture.
"""
from pathlib import Path
import os,queue,shutil,socket,subprocess,tempfile,threading,time
ROOT=Path(__file__).resolve().parents[1]
def main():
 with tempfile.TemporaryDirectory(prefix='belde-game-bridge-') as tmp:
  env=os.environ.copy()
  for key in ['BELDE_SESSION_URL','BELDE_PROFILE_ID','BELDE_PROFILE_TOKEN']:env.pop(key,None)
  for key,folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:env[key]=str(Path(tmp)/folder)
  with socket.socket() as sock:sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
  env['BELDE_BRIDGE_PORT']=str(port);env['BELDE_PORT']=str(port)
  process=subprocess.Popen([shutil.which('godot') or 'godot','--headless','--path',str(ROOT/'game'),'--script','res://tests/bridge_game_server.gd','--','--battle-preview'],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,bufsize=1)
  output=queue.Queue();logs=[]
  def read():
   for line in process.stdout:output.put(line);logs.append(line)
  reader=threading.Thread(target=read,daemon=True);reader.start()
  code=None
  try:
   deadline=time.monotonic()+30
   while time.monotonic()<deadline:
    try:line=output.get(timeout=.2)
    except queue.Empty:
     if process.poll() is not None:break
     continue
    if line.startswith('BRIDGE_GAME_READY '):code=line.split()[-1];break
    if 'BRIDGE_GAME_START_FAILED' in line:break
   if not code:raise RuntimeError('Actual game bridge startup failed:\n'+''.join(logs))
   result=subprocess.run(['node',str(ROOT/'tests/bridge_worker_test.mjs'),str(port),code,'actual'],timeout=35)
   if result.returncode:raise RuntimeError('Actual game bridge test failed.\n'+''.join(logs[-25:]))
   bad=[line for line in logs if 'SCRIPT ERROR:' in line or 'Parse Error:' in line]
   assert not bad,''.join(bad)
   print('PASS: real game scene/simulation, authoritative tower edit, stale-revision rejection, start wave, queued combat edit and shared editor disconnect through actual background.js + C host. Chrome Port API adapted in Node.')
  finally:
   process.terminate()
   try:process.wait(timeout=5)
   except subprocess.TimeoutExpired:process.kill();process.wait()
   reader.join(timeout=2);process.stdout.close()
if __name__=='__main__':main()
