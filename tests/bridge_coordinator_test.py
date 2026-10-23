"""Atomic profile leases and actual Godot coordinator-client integration."""
from __future__ import annotations
import concurrent.futures,hashlib,http.client,importlib.util,json,os,pathlib,queue,secrets,shutil,socket,subprocess,tempfile,threading,time,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('belde_coordinator',ROOT/'native/session_coordinator.py')
coordinator=importlib.util.module_from_spec(spec);spec.loader.exec_module(coordinator)

class CoordinatorTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(prefix='belde-coordinator-');self.root=pathlib.Path(self.tmp.name)
  self.token=secrets.token_hex(32);self.auth='Bearer '+self.token;self.clock=[1000.0]
  self.state=coordinator.CoordinatorState(self.root/'leases.sqlite3',{'player-one':hashlib.sha256(self.token.encode()).hexdigest()},clock=lambda:self.clock[0])
 def tearDown(self):self.tmp.cleanup()
 def request(self,operation,instance='instance-0000000000000001',**fields):
  return self.state.operate(operation,{'profile_id':'player-one','instance_id':instance,**fields},self.auth)
 def test_atomic_one_winner_under_concurrent_acquisition(self):
  with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
   responses=list(pool.map(lambda i:self.request('acquire',f'instance-{i:016}'),range(12)))
  self.assertEqual(sum(status==200 for status,_ in responses),1)
  self.assertEqual(sum(status==409 for status,_ in responses),11)
 def test_second_device_and_explicit_takeover(self):
  first=self.request('acquire')[1]['lease_token']
  status,blocked=self.request('acquire','instance-0000000000000002')
  self.assertEqual(status,409);self.assertEqual(blocked['title'],'Multiple Game Instances Detected')
  second=self.request('acquire','instance-0000000000000002',force=True)[1]['lease_token']
  self.assertNotEqual(first,second)
  self.assertEqual(self.request('renew',lease_token=first)[0],409)
  self.assertEqual(self.request('renew','instance-0000000000000002',lease_token=second)[0],200)
 def test_expiry_after_crash_and_release(self):
  token=self.request('acquire')[1]['lease_token'];self.clock[0]+=21
  self.assertEqual(self.request('renew',lease_token=token)[0],409)
  token=self.request('acquire','instance-0000000000000002')[1]['lease_token']
  self.assertEqual(self.request('release','instance-0000000000000002',lease_token=token)[0],200)
  self.assertEqual(self.request('acquire')[0],200)
 def test_invalid_credentials_and_schema(self):
  data={'profile_id':'player-one','instance_id':'instance-0000000000000001','force':True}
  self.assertEqual(self.state.operate('acquire',data,'Bearer invalid')[0],401)
  self.assertEqual(self.state.operate('acquire',{**data,'profile_id':'missing'},self.auth)[0],401)
  self.assertEqual(self.request('acquire',force='true')[0],400)
  self.assertEqual(self.request('acquire','short')[0],400)
  self.assertEqual(self.request('other')[0],404)
 def test_database_stores_hashes_not_lease_credentials(self):
  token=self.request('acquire')[1]['lease_token']
  with self.state.connect() as db:row=db.execute('SELECT * FROM leases').fetchone()
  self.assertEqual(row['token_hash'],hashlib.sha256(token.encode()).hexdigest());self.assertNotEqual(row['token_hash'],token)
 def test_nonloopback_listener_requires_tls(self):
  with self.assertRaisesRegex(ValueError,'require TLS'):coordinator.build_server('0.0.0.0',0,self.state)
  with self.assertRaisesRegex(ValueError,'both TLS'):coordinator.build_server('127.0.0.1',0,self.state,certfile='missing')
 def test_http_real_requests_auth_origin_and_body_limits(self):
  server=coordinator.build_server('127.0.0.1',0,self.state);thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start()
  def call(body,headers=None):
   connection=http.client.HTTPConnection('127.0.0.1',server.server_port,timeout=5)
   connection.request('POST','/v1/lease/acquire',json.dumps(body).encode(),{'Content-Type':'application/json','Authorization':self.auth,**(headers or {})})
   response=connection.getresponse();result=json.loads(response.read());connection.close();return response.status,result
  try:
   payload={'profile_id':'player-one','instance_id':'instance-0000000000000001'}
   self.assertEqual(call(payload)[0],200)
   self.assertEqual(call(payload,{'Origin':'https://example.com'})[0],403)
   self.assertEqual(call(payload,{'Authorization':'Bearer invalid'})[0],401)
   with socket.create_connection(('127.0.0.1',server.server_port),timeout=5) as sock:
    sock.sendall(b'POST /v1/lease/acquire HTTP/1.1\r\nHost: 127.0.0.1\r\nContent-Type: application/json\r\nContent-Length: 65537\r\n\r\n')
    self.assertIn(b' 413 ',sock.recv(1024))
  finally:server.shutdown();server.server_close();thread.join(timeout=2)
 def prepare_client(self):
  project=self.root/'project';(project/'scripts').mkdir(parents=True);(project/'tests').mkdir()
  shutil.copy2(ROOT/'game/scripts/global_session.gd',project/'scripts/global_session.gd')
  shutil.copy2(ROOT/'game/tests/bridge_global_client.gd',project/'tests/bridge_global_client.gd')
  (project/'project.godot').write_text('config_version=5\n[application]\nconfig/name="BeldeGlobalClientTest"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
  env=os.environ.copy()
  for name in ['BELDE_SESSION_URL','BELDE_PROFILE_ID','BELDE_PROFILE_TOKEN']:env.pop(name,None)
  for name,path in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:env[name]=str(project/path)
  command=[shutil.which('godot') or 'godot','--headless','--path',str(project),'--script','res://tests/bridge_global_client.gd','--']
  return command,env
 def test_godot_configuration_and_failed_connection(self):
  command,env=self.prepare_client()
  run=subprocess.run(command+['configuration'],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=12)
  self.assertEqual(run.returncode,0,run.stdout);self.assertIn('GLOBAL_CLIENT_CONFIGURATION_PASS',run.stdout)
  with socket.socket() as sock:sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
  env.update({'BELDE_SESSION_URL':f'http://127.0.0.1:{port}','BELDE_PROFILE_ID':'player-one','BELDE_PROFILE_TOKEN':self.token})
  run=subprocess.run(command+['unavailable'],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=12)
  self.assertEqual(run.returncode,0,run.stdout);self.assertIn('GLOBAL_CLIENT_UNAVAILABLE_PASS',run.stdout)
 def test_real_godot_acquire_takeover_renew_release_and_outage(self):
  command,env=self.prepare_client()
  actual=coordinator.CoordinatorState(self.root/'actual.sqlite3',{'player-one':hashlib.sha256(self.token.encode()).hexdigest()})
  server=coordinator.build_server('127.0.0.1',0,actual);thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start()
  env.update({'BELDE_SESSION_URL':f'http://127.0.0.1:{server.server_port}','BELDE_PROFILE_ID':'player-one','BELDE_PROFILE_TOKEN':self.token})
  process=subprocess.Popen(command+['lease'],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,bufsize=1)
  output=queue.Queue();logs=[]
  def read():
   for line in process.stdout:logs.append(line);output.put(line)
  reader=threading.Thread(target=read,daemon=True);reader.start();stopped=False
  try:
   until=time.monotonic()+27
   while time.monotonic()<until and process.poll() is None:
    try:line=output.get(timeout=.15)
    except queue.Empty:continue
    if line.startswith('GLOBAL_CLIENT_REACQUIRED'):
     server.shutdown();server.server_close();thread.join(timeout=2);stopped=True
   if process.poll() is None:process.kill()
   code=process.wait(timeout=3);reader.join(timeout=2);process.stdout.close()
   self.assertEqual(code,0,''.join(logs));self.assertIn('GLOBAL_CLIENT_LEASE_PASS',''.join(logs));self.assertTrue(stopped)
  finally:
   if process.poll() is None:process.kill();process.wait()
   if not stopped:server.shutdown();server.server_close();thread.join(timeout=2)

if __name__=='__main__':unittest.main(verbosity=2)
