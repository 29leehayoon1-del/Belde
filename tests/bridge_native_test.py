"""Exercise the real compiled C and portable Python native-host transports."""
import contextlib
import http.server
import json
import os
from pathlib import Path
import socket
import struct
import subprocess
import sys
import tempfile
import threading
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]


def frame(value):
    payload = json.dumps(value, ensure_ascii=False).encode()
    return struct.pack('<I', len(payload)) + payload


def unframe(data):
    result = []
    while data:
        if len(data) < 4:
            raise AssertionError('Native output contains a truncated length or unexpected stdout text')
        n = struct.unpack('<I', data[:4])[0]
        if not 1 <= n <= 1024 * 1024 or len(data) < n + 4:
            raise AssertionError('Native output framing is invalid')
        result.append(json.loads(data[4:4 + n]))
        data = data[4 + n:]
    return result


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'

    def log_message(self, *args):
        pass

    def do_POST(self):
        if self.path != '/native' or self.headers.get('Content-Type') != 'application/json':
            self.send_error(400)
            return
        size = int(self.headers['Content-Length'])
        request = json.loads(self.rfile.read(size))
        self.server.requests.append(request)
        mode = request.get('op', 'echo')
        if mode == 'html':
            payload = b'<h1>Error</h1>'
        else:
            value = {'ok': mode != 'error', 'echo': request, 'message': 'Snow and embers: 雪 ✦'}
            if mode == 'error':
                value.update(status='conflict', message='Revision changed')
            payload = json.dumps(value, ensure_ascii=False).encode()
        self.send_response(409 if mode == 'error' else 200)
        self.send_header('Content-Type', 'application/json')
        if mode != 'missing_length':
            self.send_header('Content-Length', str(len(payload) + (100 if mode == 'truncated' else 0)))
        if mode == 'duplicate_length':
            self.send_header('Content-Length', str(len(payload)))
        if mode == 'chunked':
            self.send_header('Transfer-Encoding', 'chunked')
        self.send_header('Connection', 'close')
        self.end_headers()
        try:
            if mode == 'slow':
                self.wfile.write(payload[:1]);self.wfile.flush();time.sleep(6)
                self.wfile.write(payload[1:]);self.wfile.flush()
            elif mode == 'fragment':
                for i in range(0, len(payload), 7):
                    self.wfile.write(payload[i:i+7]); self.wfile.flush()
            else:
                self.wfile.write(payload); self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            pass
        self.close_connection = True


@contextlib.contextmanager
def server():
    instance = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    instance.requests = []
    thread = threading.Thread(target=instance.serve_forever, daemon=True)
    thread.start()
    try:
        yield instance
    finally:
        instance.shutdown(); instance.server_close(); thread.join()


class NativeHostTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='belde-native-test-')
        cls.binary = Path(cls.temp.name) / 'belde_host'
        subprocess.run(['gcc', '-std=c11', '-O2', '-Wall', '-Wextra', '-Werror',
                        str(ROOT/'native/belde_host.c'), '-o', str(cls.binary)], check=True)
        cls.hosts = {'C': [str(cls.binary)], 'Python': [sys.executable, str(ROOT/'native/belde_host.py')]}

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def run_host(self, command, payload, port):
        process_env = os.environ.copy(); process_env['BELDE_BRIDGE_PORT'] = str(port)
        return subprocess.run(command, input=payload, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              env=process_env, timeout=12)

    def test_multiple_frames_utf8_and_http_path(self):
        with server() as instance:
            for name, command in self.hosts.items():
                with self.subTest(host=name):
                    first = {'op':'state', 'client_id':'test-client', 'token':'synthetic-test-token', 'label':'雪'}
                    second = {'op':'command', 'expected_revision':17, 'command':{'kind':'place_tower','cell':[3,4]}}
                    result = self.run_host(command, frame(first)+frame(second), instance.server_port)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    responses = unframe(result.stdout)
                    self.assertEqual(len(responses), 2)
                    self.assertEqual(responses[0]['echo'], first)
                    self.assertEqual(responses[1]['echo'], second)
                    self.assertTrue(responses[0]['ok'])
                    self.assertIn('雪', responses[0]['message'])
                    self.assertEqual(result.stderr, b'')

    def test_fragmented_stdin_and_http_body(self):
        with server() as instance:
            for name, command in self.hosts.items():
                with self.subTest(host=name):
                    process_env = os.environ.copy();process_env['BELDE_BRIDGE_PORT'] = str(instance.server_port)
                    process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                               stderr=subprocess.PIPE, env=process_env)
                    encoded = frame({'op':'fragment','payload':'a'*5000})
                    for i in range(0, len(encoded), 13):
                        process.stdin.write(encoded[i:i+13]);process.stdin.flush()
                    process.stdin.close();process.stdin=None
                    out, err = process.communicate(timeout=12)
                    self.assertEqual(process.returncode, 0, err)
                    result=unframe(out)
                    self.assertEqual(result[0]['echo']['payload'], 'a'*5000)

    def test_http_conflict_json_is_forwarded(self):
        with server() as instance:
            for name, command in self.hosts.items():
                with self.subTest(host=name):
                    result=self.run_host(command, frame({'op':'error'}), instance.server_port)
                    answer=unframe(result.stdout)[0]
                    self.assertEqual(answer['status'], 'conflict')
                    self.assertFalse(answer['ok'])
                    self.assertEqual(answer['message'], 'Revision changed')

    def test_absent_game_returns_framed_disconnected_response(self):
        with socket.socket() as free:
            free.bind(('127.0.0.1',0));port=free.getsockname()[1]
        for name, command in self.hosts.items():
            with self.subTest(host=name):
                result=self.run_host(command, frame({'op':'state'}), port)
                answer=unframe(result.stdout)[0]
                self.assertFalse(answer['ok']);self.assertEqual(answer['status'],'disconnected')
                self.assertIn('Start Belde',answer['message'])

    def test_zero_oversized_and_truncated_native_frames_rejected(self):
        inputs=[struct.pack('<I',0),struct.pack('<I',65537),b'\x01\x00',struct.pack('<I',8)+b'{}']
        for name, command in self.hosts.items():
            for value in inputs:
                with self.subTest(host=name, length=len(value)):
                    result=self.run_host(command,value,43127)
                    self.assertNotEqual(result.returncode,0)
                    answer=unframe(result.stdout)[0]
                    self.assertFalse(answer['ok'])
                    self.assertEqual(len(unframe(result.stdout)),1)

    def test_non_json_missing_and_truncated_http_body_rejected(self):
        with server() as instance:
            for name, command in self.hosts.items():
                for mode in ['html','missing_length','truncated','duplicate_length','chunked']:
                    with self.subTest(host=name, mode=mode):
                        result=self.run_host(command,frame({'op':mode}),instance.server_port)
                        answer=unframe(result.stdout)[0]
                        self.assertFalse(answer['ok']);self.assertEqual(answer['status'],'disconnected')

    def test_transfer_deadline_does_not_wait_for_slow_body(self):
        with server() as instance:
            for name, command in self.hosts.items():
                with self.subTest(host=name):
                    start = time.monotonic()
                    result = self.run_host(command, frame({'op':'slow'}), instance.server_port)
                    elapsed = time.monotonic() - start
                    self.assertLess(elapsed, 5.9)
                    self.assertGreater(elapsed, 4.5)
                    self.assertFalse(unframe(result.stdout)[0]['ok'])

    def test_invalid_port_rejected_without_network_request(self):
        for name,command in self.hosts.items():
            for port in ['0','65536','example.com','43127/path']:
                with self.subTest(host=name,port=port):
                    result=self.run_host(command,b'',port)
                    self.assertNotEqual(result.returncode,0)
                    self.assertIn('BELDE_BRIDGE_PORT',unframe(result.stdout)[0]['message'])

    def test_clean_eof_has_no_stdout(self):
        for name,command in self.hosts.items():
            with self.subTest(host=name):
                result=self.run_host(command,b'',43127)
                self.assertEqual(result.returncode,0);self.assertEqual(result.stdout,b'')


if __name__ == '__main__':
    unittest.main()
