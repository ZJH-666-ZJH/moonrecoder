#!/usr/bin/env python3
"""Reproducible production inventory; no tests/examples/generated content counted."""
from pathlib import Path
import json

root = Path(__file__).resolve().parent.parent
files = []
for p in sorted(root.glob('*.mbt')):
    if p.name.endswith(('_test.mbt', '_wbtest.mbt')):
        continue
    lines = p.read_text(encoding='utf-8').splitlines()
    files.append({'file': p.name, 'physical': len(lines),
                  'nonblank_noncomment': sum(bool(s.strip()) and not s.strip().startswith('//') for s in lines)})
result = {'files': files, 'physical': sum(f['physical'] for f in files),
          'nonblank_noncomment': sum(f['nonblank_noncomment'] for f in files)}
print(json.dumps(result, indent=2))
if result['physical'] < 1500:
    raise SystemExit('production MoonBit physical LOC below 1500')
