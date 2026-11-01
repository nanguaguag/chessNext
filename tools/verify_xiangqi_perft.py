#!/usr/bin/env python3
"""Compare original Dart rules with the pinned, local Pikafish legal move trees."""
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / '.local/pikafish/Pikafish-MacOS-universal'
CASES = [(3, ''), (2, 'h2e2'),
         (2, 'h2e2 b9c7 b0c2 h9g7 a0b0 a9b9'), (3, 'h2h9 i9h9')]

def main():
    records = []
    for depth, history in CASES:
        dart = subprocess.run(['dart', 'run', 'bin/perft.dart', str(depth), history],
                              cwd=ROOT / 'packages/xiangqi_core', capture_output=True,
                              text=True, check=True, timeout=120)
        actual = json.loads(dart.stdout)
        command = 'position startpos' + (' moves ' + history if history else '')
        engine = subprocess.run([str(ENGINE)], cwd=ENGINE.parent,
                                input=f'{command}\ngo perft {depth}\nquit\n',
                                text=True, capture_output=True, check=True, timeout=30)
        divide = {m: int(n) for m, n in re.findall(r'^([a-i][0-9][a-i][0-9]): (\d+)$', engine.stdout, re.M)}
        match = re.search(r'Nodes searched: (\d+)', engine.stdout)
        if match is None or actual['nodes'] != int(match[1]) or actual['divide'] != divide:
            raise AssertionError({'dart': actual, 'engine': engine.stdout})
        records.append({'history': history, **actual, 'matched': True,
                        'pikafish_stdout': engine.stdout})
        print(f'PASS depth={depth}, nodes={actual["nodes"]}, history={history or "startpos"}', flush=True)
    destination = ROOT / 'docs/engine/evidence/xiangqi-perft.json'
    destination.write_text(json.dumps({'date': '2026-11-01',
        'engine_commit': '4c17cee11f888ae1d48a9494f2e2239f019f0a1f',
        'cases': records}, indent=2) + '\n')

if __name__ == '__main__':
    main()
