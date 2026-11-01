#!/usr/bin/env python3
"""Bundle verified local engine assets into the macOS development app."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--destination', required=True)
    args = parser.parse_args()
    source = ROOT / '.local/pikafish'
    destination = Path(args.destination)
    destination = destination.resolve()
    if not destination.is_relative_to(ROOT / 'build') or destination.name != 'pikafish' or destination.parent.name != 'Resources':
        raise ValueError('Destination must be the generated app build Resources/pikafish directory')
    binary = 'Pikafish-MacOS-universal'
    if not (source / binary).exists() or not (source / 'pikafish.nnue').exists():
        print('Pikafish not installed locally: building board-only application.')
        # Do not accidentally ship stale engine assets from an earlier build.
        if destination.exists():
            shutil.rmtree(destination)
        return
    manifest = json.loads((ROOT / 'docs/engine/pikafish.lock.json').read_text())
    for name, expected in [(binary, manifest['macos_binary_sha256']), ('pikafish.nnue', manifest['network_sha256'])]:
        if hashlib.sha256((source / name).read_bytes()).hexdigest() != expected:
            raise RuntimeError(f'Local artifact changed: {name}; run verified setup')
    destination.mkdir(parents=True, exist_ok=True)
    for name in [binary, 'pikafish.nnue', 'Copying.txt', 'NNUE-License.md', 'AUTHORS']:
        shutil.copy2(source / name, destination / name)
    (destination / binary).chmod(0o755)
    entitlements = '''<?xml version="1.0"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>com.apple.security.app-sandbox</key><true/><key>com.apple.security.inherit</key><true/></dict></plist>'''
    with tempfile.TemporaryDirectory(prefix='chessnext-sign-') as directory:
        path = Path(directory) / 'engine.entitlements'
        path.write_text(entitlements)
        subprocess.run(['codesign', '--force', '--sign', '-', '--identifier', 'dev.chessnext.pikafish',
                        '--requirements', '=designated => identifier "dev.chessnext.pikafish"',
                        '--entitlements', str(path), str(destination / binary)], check=True)
    identity = {
        'schema': 1,
        'release': manifest['release'],
        'commit': manifest['commit'],
        'sourceBinarySha256': manifest['macos_binary_sha256'],
        'binarySha256': hashlib.sha256((destination / binary).read_bytes()).hexdigest(),
        'networkSha256': manifest['network_sha256'],
        'target': 'macos-universal',
    }
    (destination / 'identity.json').write_text(json.dumps(identity, sort_keys=True, indent=2) + '\n')
    print('Bundled verified local Pikafish and NNUE (development signing).')

if __name__ == '__main__':
    main()
