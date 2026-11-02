#!/usr/bin/env python3
"""all_hoth_chain.py <tre> — run the chain check from every client object (shared_*.iff) our Hoth overlays add, so any
asset a Hoth item references but the TRE does not ship shows up (e.g. snow globe component lods, 2026-10-12)."""
import os, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
tre = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'dist', 'bg_custom1.tre')
roots = []
for base in ('build/hoth', 'build/hoth_loot'):
    b = os.path.join(HERE, base)
    for dp, dn, fn in os.walk(b):
        for f in fn:
            rel = os.path.relpath(os.path.join(dp, f), b).replace(chr(92), '/')
            if rel.startswith('object/') and rel.endswith('.iff') and '/shared_' in rel:
                roots.append(rel)
print(len(roots), 'root objects')
out = subprocess.run([sys.executable, os.path.join(HERE, 'chain_check.py'), tre] + roots, capture_output=True, text=True)
print(out.stdout[-6000:], out.stderr[-1500:])
