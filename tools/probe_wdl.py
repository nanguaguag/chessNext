#!/usr/bin/env python3
"""Probe pinned local macOS Pikafish WDL; protocol evidence, not app UI."""
from pathlib import Path
import hashlib
import json
import os
import select
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]

def main():
    lock = json.loads((ROOT / 'docs/engine/pikafish.lock.json').read_text())
    folder = ROOT / '.local/pikafish'
    executable = folder / 'Pikafish-MacOS-universal'
    for file, expected in [(executable, lock['macos_binary_sha256']),
                           (folder / 'pikafish.nnue', lock['network_sha256'])]:
        if hashlib.sha256(file.read_bytes()).hexdigest() != expected:
            raise RuntimeError('Pinned artifact checksum mismatch')
    process = subprocess.Popen([str(executable)], cwd=folder, stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, bufsize=0)
    pending = bytearray()
    lines = ['# ' + json.dumps({'release': lock['release'], 'commit': lock['commit'],
                              'binary_sha256': lock['macos_binary_sha256'],
                              'network_sha256': lock['network_sha256']})]
    def send(command):
        lines.append('> ' + command)
        process.stdin.write((command + '\n').encode())
        process.stdin.flush()
    def read_until(prefix):
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if b'\n' not in pending:
                ready, _, _ = select.select([process.stdout], [], [], max(0, deadline - time.monotonic()))
                if not ready:
                    raise TimeoutError(prefix)
                chunk = os.read(process.stdout.fileno(), 65536)
                if not chunk:
                    raise RuntimeError('Unexpected engine EOF')
                pending.extend(chunk)
                continue
            raw, _, remainder = pending.partition(b'\n')
            pending[:] = remainder
            line = raw.decode('utf-8').rstrip('\r')
            lines.append(line)
            if len(lines) > 10000:
                raise RuntimeError('Unexpectedly large protocol output')
            if line.startswith(prefix):
                return
        raise TimeoutError(prefix)
    try:
        send('uci')
        read_until('uciok')
        if not any('option name UCI_ShowWDL type check' in line for line in lines):
            raise RuntimeError('WDL option missing')
        send('setoption name UCI_ShowWDL value true')
        send('isready')
        read_until('readyok')
        for position in ['position startpos', 'position startpos moves h2e2']:
            send(position)
            send('go depth 4')
            read_until('bestmove ')
        send('quit')
        process.wait(timeout=5)
        if process.returncode != 0:
            raise RuntimeError('Engine failed to exit cleanly')
        rows = [line for line in lines if line.startswith('info depth') and ' wdl ' in line]
        if not rows:
            raise RuntimeError('No WDL data received')
        for row in rows:
            fields = row.split()
            index = fields.index('wdl')
            values = list(map(int, fields[index + 1:index + 4]))
            if len(values) != 3 or sum(values) != 1000 or any(v < 0 or v > 1000 for v in values):
                raise RuntimeError('Invalid WDL data')
        destination = ROOT / 'docs/engine/validation/wdl-protocol-2026-11-02.txt'
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text('\n'.join(lines) + '\n')
        print(json.dumps({'wdl_lines': len(rows), 'last': rows[-1], 'exit_code': process.returncode}))
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()

if __name__ == '__main__':
    main()
