#!/usr/bin/env python3
"""Build and run a sandboxed diagnostic bundle; no machine security settings change."""
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PROBE = ROOT / 'research/spikes/flutter_engine_probe'
APP = PROBE / 'build/macos/Build/Products/Debug/engine_probe.app'

def main():
    subprocess.run(['flutter', 'build', 'macos', '--debug', '--dart-define=PROBE_AUTO_EXIT=true'], cwd=PROBE, check=True)
    target = APP / 'Contents/Resources/pikafish'
    target.mkdir(parents=True, exist_ok=True)
    for name in ['Pikafish-MacOS-universal', 'pikafish.nnue', 'Copying.txt', 'NNUE-License.md', 'AUTHORS']:
        shutil.copy2(ROOT / '.local/pikafish' / name, target / name)
    entitlements = ROOT / 'research/spikes/flutter_engine_probe/macos/engine-helper.entitlements'
    subprocess.run(['codesign', '--force', '--sign', '-', '--entitlements', str(entitlements), str(target / 'Pikafish-MacOS-universal')], check=True)
    subprocess.run(['codesign', '--force', '--sign', '-', '--entitlements', str(PROBE / 'macos/Runner/DebugProfile.entitlements'), str(APP)], check=True)
    result = subprocess.run([str(APP / 'Contents/MacOS/engine_probe')], capture_output=True, text=True, timeout=45)
    # VM-service URL is a transient debug credential, not useful evidence.
    output = '\n'.join(line for line in result.stdout.splitlines() if 'Dart VM service' not in line)
    log = output + '\nSTDERR:\n' + result.stderr + f'\nEXIT={result.returncode}\n'
    (ROOT / 'docs/engine/evidence/macos-app-uci.log').write_text(log)
    print(log[-1200:])
    if result.returncode or '3 stop cycles, exit=0' not in output:
        raise SystemExit('Native app probe failed; inspect evidence log')

if __name__ == '__main__':
    main()
