#!/usr/bin/env python3
"""Portable native-host fallback for macOS/Linux; no external Python packages."""
import json
import os
import re
import struct
import socket
import time
import sys

MAX_REQUEST = 65536
MAX_RESPONSE = 1024 * 1024


def emit(value):
    encoded = json.dumps(value, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
    sys.stdout.buffer.write(struct.pack('<I', len(encoded)))
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()


def error(message):
    emit({'ok': False, 'status': 'disconnected', 'message': message})


def read_exact(length):
    chunks = []
    received = 0
    while received < length:
        chunk = sys.stdin.buffer.read(length - received)
        if not chunk:
            if received == 0:
                return None
            raise EOFError
        chunks.append(chunk)
        received += len(chunk)
    return b''.join(chunks)


def exchange(payload, port):
    with socket.create_connection(('127.0.0.1', port), timeout=2) as connection:
        deadline = time.monotonic() + 5
        request = (f'POST /native HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\n'
                   f'Content-Type: application/json\r\nContent-Length: {len(payload)}\r\n'
                   'Connection: close\r\n\r\n').encode('ascii') + payload
        connection.settimeout(5)
        connection.sendall(request)
        data = bytearray()
        header_end = None
        body_length = None
        while len(data) <= MAX_RESPONSE + 16384:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError
            connection.settimeout(remaining)
            block = connection.recv(min(65536, MAX_RESPONSE + 16384 + 1 - len(data)))
            if not block:
                raise ValueError
            data.extend(block)
            if header_end is None:
                marker = data.find(b'\r\n\r\n')
                if marker == -1:
                    if len(data) >= 16384:
                        raise ValueError
                    continue
                header_end = marker + 4
                if header_end > 16384:
                    raise ValueError
                lines = data[:marker].decode('ascii').split('\r\n')
                if not re.fullmatch(r'HTTP/1\.[01] [1-5][0-9]{2}( .*)?', lines[0]):
                    raise ValueError
                headers = {}
                for line in lines[1:]:
                    key, sep, value = line.partition(':')
                    if not sep:
                        raise ValueError
                    key = key.lower()
                    if key in headers:
                        raise ValueError
                    headers[key] = value.strip()
                length = headers.get('content-length', '')
                if 'transfer-encoding' in headers or not re.fullmatch(r'[0-9]+', length):
                    raise ValueError
                body_length = int(length)
                if not 1 <= body_length <= MAX_RESPONSE:
                    raise ValueError
            if len(data) - header_end >= body_length:
                value = json.loads(data[header_end:header_end + body_length])
                if not isinstance(value, dict):
                    raise ValueError
                return value
        raise ValueError


def main():
    configured = os.environ.get('BELDE_BRIDGE_PORT', '43127')
    if not re.fullmatch(r'[0-9]+', configured) or not 1024 <= int(configured) <= 65535:
        error('BELDE_BRIDGE_PORT must be an integer from 1024 to 65535.')
        return 1
    port = int(configured)
    while True:
        try:
            prefix = read_exact(4)
        except EOFError:
            error('The native message length was incomplete.')
            return 1
        if prefix is None:
            return 0
        length = struct.unpack('<I', prefix)[0]
        if not 1 <= length <= MAX_REQUEST:
            error('Native editor messages must contain 1 to 65536 bytes.')
            return 1
        try:
            payload = read_exact(length)
        except EOFError:
            payload = None
        if payload is None:
            error('The native editor message was incomplete.')
            return 1
        try:
            result = exchange(payload, port)
        except (ConnectionRefusedError, ConnectionResetError, TimeoutError, OSError):
            error('Start Belde before connecting the editor, then reconnect.')
        except (ValueError, UnicodeError):
            error('Belde returned an incomplete or unsupported editor response. Reconnect and try again.')
        else:
            emit(result)


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except BrokenPipeError:
        raise SystemExit(1)
