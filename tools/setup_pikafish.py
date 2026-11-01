#!/usr/bin/env python3
"""Fetch pinned official artifacts for local macOS research, not redistribution."""
import hashlib
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
URL = 'https://github.com/official-pikafish/Pikafish/releases/download/Pikafish-2026-09-06/Pikafish.2026-09-06.7z'
ARCHIVE_SHA = '41952bbfe2520faceb5902c69e6ab4845cc999841d2b49a95cc1be7867a25e5b'
FILES = {
    'Pikafish-MacOS-universal': '3a11f9034ef723bb4068e4cf88a79a12d99507474ba118fa916ec2cecd4f4abe',
    'pikafish.nnue': '7d13d73569a9b571ba0eb20cf1596247bc2a42738967e61afef6482b231e900e',
}

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    destination = ROOT / '.local/pikafish'
    if not all((destination / name).exists() and digest(destination / name) == sha
               for name, sha in FILES.items()):
        with tempfile.TemporaryDirectory(prefix='chessnext-') as directory:
            archive = Path(directory) / 'pikafish.7z'
            subprocess.run(['curl', '-L', '--fail', '--retry', '2', URL, '-o', str(archive)], check=True)
            if digest(archive) != ARCHIVE_SHA:
                raise RuntimeError('Official archive changed; review version and licenses before updating hashes')
            unpacked = Path(directory) / 'unpacked'
            subprocess.run(['7z', 'x', '-y', f'-o{unpacked}', str(archive)], check=True, capture_output=True)
            destination.mkdir(parents=True, exist_ok=True)
            for name, sha in FILES.items():
                data = unpacked / name
                if digest(data) != sha:
                    raise RuntimeError(f'Hash mismatch: {name}')
                (destination / name).write_bytes(data.read_bytes())
            for name in ['Copying.txt', 'NNUE-License.md', 'AUTHORS']:
                (destination / name).write_bytes((unpacked / name).read_bytes())
    (destination / 'Pikafish-MacOS-universal').chmod(0o755)
    print('Verified local artifacts:', destination)
    print('NNUE forbids commercial use without permission; see docs/legal/pikafish-2026-09-06/NNUE-License.md')

if __name__ == '__main__':
    main()
