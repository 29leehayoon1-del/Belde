"""Exercise the actual Godot loopback bridge, including leases and HTTP boundaries."""
from __future__ import annotations
import http.client
import json
import os
from pathlib import Path
import queue
import shutil
import socket
import subprocess
import tempfile
import threading
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]

class GodotBridgeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='belde-bridge-')
        cls.project = Path(cls.temp.name)
        (cls.project/'scripts').mkdir(); (cls.project/'tests').mkdir()
        shutil.copy2(ROOT/'game/scripts/local_bridge.gd',cls.project/'scripts/local_bridge.gd')
        shutil.copy2(ROOT/'game/tests/bridge_server.gd',cls.project/'tests/bridge_server.gd')
        (cls.project/'project.godot').write_text('config_version=5\n[application]\nconfig/name="BeldeBridgeTest"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
        with socket.socket() as sock:
            sock.bind(('127.0.0.1',0)); cls.port=sock.getsockname()[1]
        env=os.environ.copy()
        env.pop('BELDE_BRIDGE_PORT',None)
        for key,folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
            env[key]=str(cls.project/folder)
        cls.proc=subprocess.Popen([shutil.which('godot') or 'godot','--headless','--path',str(cls.project),'--script','res://tests/bridge_server.gd','--',str(cls.port)],env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,bufsize=1)
        cls.output=queue.Queue(); cls.logs=[]
        def read():
            for line in cls.proc.stdout:
                cls.output.put(line); cls.logs.append(line)
        cls.reader=threading.Thread(target=read,daemon=True);cls.reader.start()
        until=time.monotonic()+15
        cls.code=None
        while time.monotonic()<until:
            try:line=cls.output.get(timeout=.2)
            except queue.Empty:
                if cls.proc.poll() is not None:break
                continue
            if line.startswith('BRIDGE_TEST_READY '):cls.code=line.split()[-1];break
        if not cls.code:
            cls.proc.terminate();raise RuntimeError('Godot bridge failed to start:\n'+''.join(cls.logs))

    @classmethod
    def tearDownClass(cls):
        cls.proc.terminate()
        try:cls.proc.wait(timeout=5)
        except subprocess.TimeoutExpired:cls.proc.kill();cls.proc.wait()
        cls.reader.join(timeout=1)
        cls.temp.cleanup()

    def rpc(self,payload,headers=None):
        conn=http.client.HTTPConnection('127.0.0.1',self.port,timeout=5)
        body=json.dumps(payload,ensure_ascii=False).encode()
        conn.request('POST','/native',body,{'Content-Type':'application/json',**(headers or {})})
        response=conn.getresponse();status=response.status;result=json.loads(response.read());conn.close()
        return status,result

    def setUp(self):
        self.client='test-client-0001'
        status,result=self.rpc({'op':'pair','code':self.code,'client_id':self.client,'force':True})
        self.assertEqual(status,200,result);self.token=result['token']

    def authorized(self,op,**extra):
        return self.rpc({'op':op,'client_id':self.client,'token':self.token,**extra})

    def raw(self,request,fragments=None):
        with socket.create_connection(('127.0.0.1',self.port),timeout=5) as sock:
            sock.settimeout(5)
            if fragments:
                cursor=0
                for size in fragments:
                    sock.sendall(request[cursor:cursor+size]);cursor+=size;time.sleep(.002)
                sock.sendall(request[cursor:])
            else:sock.sendall(request)
            result=b''
            while True:
                part=sock.recv(65536)
                if not part:break
                result+=part
        head,body=result.split(b'\r\n\r\n',1)
        return int(head.split(b' ')[1]),json.loads(body),head

    def test_health_has_no_pairing_secret(self):
        conn=http.client.HTTPConnection('127.0.0.1',self.port,timeout=5)
        conn.request('GET','/health');response=conn.getresponse();body=json.loads(response.read());conn.close()
        self.assertEqual(response.status,200);self.assertEqual(body['application'],'Belde')
        self.assertNotIn('token',body);self.assertNotIn('code',body)

    def test_authentication_and_client_binding(self):
        self.assertEqual(self.rpc({'op':'state'})[0],401)
        self.assertEqual(self.rpc({'op':'state','token':self.token,'client_id':'other-client-0002'})[0],401)
        status,result=self.authorized('state',request_id=42)
        self.assertEqual(status,200);self.assertEqual(result['request_id'],42);self.assertIn('simulation',result['state'])
        self.assertEqual(len(self.token),64)

    def test_second_editor_requires_explicit_takeover(self):
        payload={'op':'pair','code':self.code,'client_id':'other-client-0002'}
        status,result=self.rpc(payload)
        self.assertEqual(status,409);self.assertEqual(result['title'],'Multiple Game Instances Detected')
        self.assertEqual(result['action'],'Disconnect other session to continue')
        status,result=self.rpc({**payload,'force':True})
        self.assertEqual(status,200);self.assertNotEqual(result['token'],self.token)
        self.assertEqual(self.authorized('state')[0],401)

    def test_revision_conflict_never_applies_command(self):
        state=self.authorized('state')[1]['state'];revision=state['revision'];before=len(state['commands'])
        status,result=self.authorized('command',command={'kind':'place_tower','cell':[3,5]},expected_revision=revision+1)
        self.assertEqual(status,409);self.assertTrue(result['conflict'])
        self.assertEqual(len(self.authorized('state')[1]['state']['commands']),before)
        status,result=self.authorized('command',command={'kind':'place_tower','cell':[3,5]},expected_revision=revision)
        self.assertEqual(status,200);self.assertEqual(result['revision'],revision+1)
        applied=self.authorized('state')[1]['state']['commands'][-1]
        self.assertEqual(applied['cell'],[3,5]);self.assertEqual(applied['expected_revision'],revision)

    def test_disconnect_releases_slot(self):
        self.assertEqual(self.authorized('disconnect')[0],200)
        self.assertEqual(self.authorized('state')[0],401)
        self.assertEqual(self.rpc({'op':'pair','code':self.code,'client_id':'new-client-0003'})[0],200)

    def test_heartbeat_and_expiry(self):
        time.sleep(.75);self.assertEqual(self.authorized('heartbeat')[0],200)
        time.sleep(.75);self.assertEqual(self.authorized('state')[0],200)
        time.sleep(1.4);self.assertEqual(self.authorized('state')[0],401)
        self.assertEqual(self.rpc({'op':'pair','code':self.code,'client_id':'new-client-0003'})[0],200)

    def test_browser_origin_and_rebinding_rejected(self):
        self.assertEqual(self.rpc({'op':'state'},headers={'Origin':'https://example.com'})[0],403)
        body=b'{}'
        request=b'POST /native HTTP/1.1\r\nHost: attacker.example\r\nContent-Type: application/json\r\nContent-Length: 2\r\n\r\n'+body
        status,result,headers=self.raw(request);self.assertEqual(status,403)
        self.assertNotIn(b'Access-Control-Allow-Origin',headers)

    def test_fragmented_utf8_body(self):
        state=self.authorized('state')[1]['state']
        payload={'op':'command','token':self.token,'client_id':self.client,'expected_revision':state['revision'],'command':{'kind':'inspect','note':'Mira — 빛'}}
        body=json.dumps(payload,ensure_ascii=False).encode()
        header=(f'POST /native HTTP/1.1\r\nHost: 127.0.0.1:{self.port}\r\nContent-Type: application/json\r\nContent-Length: {len(body)}\r\n\r\n').encode()
        status,result,_=self.raw(header+body,[10,len(header)-10,len(body)-2,1])
        self.assertEqual(status,200,result)
        self.assertEqual(self.authorized('state')[1]['state']['commands'][-1]['note'],'Mira — 빛')

    def test_bad_http_and_oversize_rejected(self):
        prefix=f'POST /native HTTP/1.1\r\nHost: 127.0.0.1:{self.port}\r\nContent-Type: application/json\r\n'.encode()
        status,_,_=self.raw(prefix+b'Content-Length: 65537\r\n\r\n');self.assertEqual(status,413)
        status,_,_=self.raw(prefix+b'Content-Length: 2\r\nContent-Length: 2\r\n\r\n{}');self.assertEqual(status,400)
        status,_,_=self.raw(prefix+b'Transfer-Encoding: chunked\r\n\r\n0\r\n\r\n');self.assertEqual(status,403)
        status,_,_=self.raw(prefix+b'Content-Length: 2\r\n\r\n[]');self.assertEqual(status,400)
        status,_,_=self.raw(prefix+b'Content-Length: 2\r\n\r\n{}junk');self.assertEqual(status,400)

    def test_second_pc_instance_cannot_bind(self):
        env=os.environ.copy()
        env.pop("BELDE_BRIDGE_PORT",None)
        for key,folder in [("XDG_DATA_HOME","data"),("XDG_CONFIG_HOME","config"),("XDG_CACHE_HOME","cache")]:env[key]=str(self.project/folder)
        run=subprocess.run([shutil.which("godot") or "godot","--headless","--path",str(self.project),"--script","res://tests/bridge_server.gd","--",str(self.port)],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=10)
        self.assertEqual(run.returncode,1,run.stdout)
        self.assertIn("BRIDGE_TEST_START_FAILED",run.stdout)
        self.assertEqual(self.authorized("state")[0],200)

    def test_z_pair_rate_limit(self):
        for _ in range(5):self.assertEqual(self.rpc({'op':'pair','code':'bad','client_id':self.client})[0],401)
        self.assertEqual(self.rpc({'op':'pair','code':self.code,'client_id':self.client})[0],429)
        # Existing valid editor can still disconnect; test process is torn down after this test.
        self.assertEqual(self.authorized('state')[0],200)

if __name__=='__main__':unittest.main(verbosity=2)
