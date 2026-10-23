#!/usr/bin/env python3
"""Optional self-hosted Belde profile lease service. Python standard library only."""
from __future__ import annotations
import argparse
import hashlib
import hmac
import http.server
import ipaddress
import json
from pathlib import Path
import re
import secrets
import socket
import sqlite3
import ssl
import time

TITLE = 'Multiple Game Instances Detected'
BODY = ('Your game is currently active on another device or platform. Only one active PC '
        'gameplay session and one connected editor session are permitted.')
ACTION = 'Disconnect other session to continue'
TTL_SECONDS = 20
MAX_BODY = 65536
PROFILE_PATTERN = re.compile(r'[A-Za-z0-9_-]{1,64}')
INSTANCE_PATTERN = re.compile(r'[A-Za-z0-9_-]{16,128}')
TOKEN_HASH_PATTERN = re.compile(r'[a-fA-F0-9]{64}')


class CoordinatorState:
    def __init__(self, database, profiles, clock=time.time):
        self.database = str(database)
        self.clock = clock
        self.profiles = {}
        for name, digest in profiles.items():
            if not PROFILE_PATTERN.fullmatch(name) or not isinstance(digest, str) or not TOKEN_HASH_PATTERN.fullmatch(digest):
                raise ValueError('Profiles must map valid profile IDs to SHA-256 token hashes.')
            self.profiles[name] = digest.lower()
        if not self.profiles:
            raise ValueError('At least one profile must be configured.')
        Path(self.database).parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as db:
            db.execute('PRAGMA journal_mode=WAL')
            db.execute('CREATE TABLE IF NOT EXISTS leases ('
                       'profile_id TEXT PRIMARY KEY, instance_id TEXT NOT NULL, '
                       'token_hash TEXT NOT NULL, expires_at REAL NOT NULL, updated_at REAL NOT NULL)')
        Path(self.database).chmod(0o600)

    def connect(self):
        db = sqlite3.connect(self.database, timeout=5, isolation_level=None)
        db.row_factory = sqlite3.Row
        db.execute('PRAGMA busy_timeout=5000')
        return db

    def authenticate(self, profile_id, authorization):
        expected = self.profiles.get(profile_id, '0' * 64)
        token = authorization[7:] if authorization.startswith('Bearer ') else ''
        actual = hashlib.sha256(token.encode('utf-8')).hexdigest()
        matched = hmac.compare_digest(expected, actual)
        return bool(token) and profile_id in self.profiles and matched

    @staticmethod
    def conflict(expires_in=0):
        return 409, {'ok': False, 'status': 'conflict', 'title': TITLE, 'message': BODY,
                     'action': ACTION, 'expires_in': max(0, round(expires_in, 3))}

    def operate(self, operation, body, authorization):
        profile = body.get('profile_id', '')
        if not isinstance(profile, str) or not self.authenticate(profile, authorization):
            return 401, {'ok': False, 'status': 'unauthorized', 'message': 'Profile credentials were rejected.'}
        instance = body.get('instance_id', '')
        if not isinstance(instance, str) or not INSTANCE_PATTERN.fullmatch(instance):
            return 400, {'ok': False, 'status': 'invalid', 'message': 'A valid instance ID is required.'}
        if operation not in ('acquire', 'renew', 'release'):
            return 404, {'ok': False, 'status': 'not_found', 'message': 'Unknown lease operation.'}
        force = body.get('force', False)
        if not isinstance(force, bool):
            return 400, {'ok': False, 'status': 'invalid', 'message': 'Force takeover must be explicitly true or false.'}
        now = self.clock()
        db = self.connect()
        try:
            db.execute('BEGIN IMMEDIATE')
            lease = db.execute('SELECT * FROM leases WHERE profile_id=?', (profile,)).fetchone()
            active = lease is not None and lease['expires_at'] > now
            if operation == 'acquire':
                if active and lease['instance_id'] != instance and not force:
                    db.commit()
                    return self.conflict(lease['expires_at'] - now)
                token = secrets.token_hex(32)
                digest = hashlib.sha256(token.encode()).hexdigest()
                expiry = now + TTL_SECONDS
                db.execute('INSERT INTO leases VALUES (?,?,?,?,?) ON CONFLICT(profile_id) DO UPDATE SET '
                           'instance_id=excluded.instance_id,token_hash=excluded.token_hash,'
                           'expires_at=excluded.expires_at,updated_at=excluded.updated_at',
                           (profile, instance, digest, expiry, now))
                db.commit()
                return 200, {'ok': True, 'status': 'connected', 'lease_token': token,
                             'expires_in': TTL_SECONDS, 'expires_at': expiry}
            supplied = body.get('lease_token', '')
            supplied_hash = hashlib.sha256(supplied.encode()).hexdigest() if isinstance(supplied, str) else ''
            owns = active and lease['instance_id'] == instance and hmac.compare_digest(lease['token_hash'], supplied_hash)
            if not owns:
                if lease is not None and not active:
                    db.execute('DELETE FROM leases WHERE profile_id=?', (profile,))
                db.commit()
                return self.conflict(lease['expires_at'] - now if active else 0)
            if operation == 'renew':
                expiry = now + TTL_SECONDS
                db.execute('UPDATE leases SET expires_at=?,updated_at=? WHERE profile_id=?', (expiry, now, profile))
                db.commit()
                return 200, {'ok': True, 'status': 'connected', 'expires_in': TTL_SECONDS, 'expires_at': expiry}
            db.execute('DELETE FROM leases WHERE profile_id=?', (profile,))
            db.commit()
            return 200, {'ok': True, 'status': 'released'}
        except Exception:
            db.rollback()
            raise
        finally:
            db.close()


class CoordinatorHandler(http.server.BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'

    def setup(self):
        super().setup()
        self.connection.settimeout(5)

    def log_message(self, *args):
        # Never log request bodies, authorization headers, profile IDs or lease tokens.
        pass

    def send_json(self, code, value):
        encoded = json.dumps(value, separators=(',', ':')).encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(encoded)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('Connection', 'close')
        self.end_headers()
        try:
            self.wfile.write(encoded)
        except (BrokenPipeError, ConnectionResetError):
            pass
        self.close_connection = True

    def do_GET(self):
        if self.path == '/health':
            self.send_json(200, {'ok': True, 'service': 'Belde session coordinator', 'version': 1})
        else:
            self.send_json(404, {'ok': False, 'message': 'Not found.'})

    def do_POST(self):
        if self.headers.get('Origin'):
            self.send_json(403, {'ok': False, 'message': 'Browser-origin requests are not accepted.'})
            return
        lengths = self.headers.get_all('Content-Length', [])
        if len(lengths) != 1 or not re.fullmatch(r'[0-9]+', lengths[0]) or self.headers.get('Transfer-Encoding'):
            self.send_json(400, {'ok': False, 'message': 'One valid Content-Length is required.'})
            return
        length = int(lengths[0])
        if not 1 <= length <= MAX_BODY:
            self.send_json(413, {'ok': False, 'message': 'Lease requests must be at most 65536 bytes.'})
            return
        if self.headers.get('Content-Type', '').split(';')[0].strip().lower() != 'application/json':
            self.send_json(415, {'ok': False, 'message': 'Content-Type must be application/json.'})
            return
        prefix = '/v1/lease/'
        if not self.path.startswith(prefix) or self.path[len(prefix):] not in ('acquire', 'renew', 'release'):
            self.send_json(404, {'ok': False, 'message': 'Not found.'})
            return
        try:
            raw = self.rfile.read(length)
            if len(raw) != length:
                raise ValueError
            body = json.loads(raw)
            if not isinstance(body, dict):
                raise ValueError
        except (ValueError, UnicodeError, TimeoutError):
            self.send_json(400, {'ok': False, 'message': 'A complete JSON object is required.'})
            return
        try:
            status, result = self.server.coordinator.operate(self.path[len(prefix):], body,
                                                           self.headers.get('Authorization', ''))
        except sqlite3.Error:
            self.send_json(503, {'ok': False, 'status': 'unavailable', 'message': 'The lease database is temporarily unavailable.'})
            return
        self.send_json(status, result)


def is_loopback(host):
    if host == 'localhost':
        return True
    try:
        return ipaddress.ip_address(host.strip('[]')).is_loopback
    except ValueError:
        return False


def build_server(bind, port, state, certfile=None, keyfile=None):
    if bool(certfile) != bool(keyfile):
        raise ValueError('Supply both TLS certificate and key.')
    if not is_loopback(bind) and not (certfile and keyfile):
        raise ValueError('Non-loopback listeners require TLS: supply --cert and --key.')
    address = '127.0.0.1' if bind == 'localhost' else bind.strip('[]')
    server_class = http.server.ThreadingHTTPServer
    if ':' in address:
        class IPv6Server(http.server.ThreadingHTTPServer):
            address_family = socket.AF_INET6
        server_class = IPv6Server
    server = server_class((address, port), CoordinatorHandler)
    server.coordinator = state
    if certfile:
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.minimum_version = ssl.TLSVersion.TLSv1_2
        context.load_cert_chain(certfile, keyfile)
        server.socket = context.wrap_socket(server.socket, server_side=True)
    return server


def main():
    parser = argparse.ArgumentParser(description='Optional authenticated single-PC-per-profile Belde session coordinator.')
    parser.add_argument('--bind', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=43128)
    parser.add_argument('--profiles', required=True, type=Path, help='JSON mapping profile IDs to SHA-256 token hashes.')
    parser.add_argument('--database', type=Path, default=Path('belde-sessions.sqlite3'))
    parser.add_argument('--cert', type=Path)
    parser.add_argument('--key', type=Path)
    args = parser.parse_args()
    try:
        if not is_loopback(args.bind) and not (args.cert and args.key):
            raise ValueError('Non-loopback listeners require TLS: supply --cert and --key.')
        configured = json.loads(args.profiles.read_text())
        profiles = configured.get('profiles', configured) if isinstance(configured, dict) else None
        if not isinstance(profiles, dict):
            raise ValueError('Profiles file must be a JSON object.')
        state = CoordinatorState(args.database, profiles)
        server = build_server(args.bind, args.port, state, args.cert, args.key)
    except (OSError, ValueError, ssl.SSLError) as error:
        parser.error(str(error))
    scheme = 'https' if args.cert else 'http'
    print(f'Belde profile coordinator listening on {scheme}://{args.bind}:{server.server_port}', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
