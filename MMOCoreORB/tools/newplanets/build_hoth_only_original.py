#!/usr/bin/env python3
"""build_hoth_only_original.py — rebuild dist/bg_custom1_hoth_only.tre (PR #795 / Test Center) with the ORIGINAL outpost
positions: a temp copy of build/hoth with the pristine Infinity terrain + snapshot and the original radar regions.
The outpost move (move_outposts.py) belongs to the loot branch, not to PR #795."""
import os, shutil, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import dt_tool

ORIG = {'scavenger_outpost': (0.0, -2000.0), 'imperial_outpost': (5927.0, -406.0), 'rebel_outpost': (4525.0, 1164.0),
        'lucky_despot_wreck': (-100.0, -2048.0)}
tmp = tempfile.mkdtemp()
dst = os.path.join(tmp, 'hoth')
shutil.copytree(os.path.join(HERE, 'build', 'hoth'), dst)
shutil.copyfile(os.path.join(HERE, 'extract', 'infinity', 'terrain', 'hoth.trn'), os.path.join(dst, 'terrain', 'hoth.trn'))
shutil.copyfile(os.path.join(HERE, 'extract', 'infinity', 'snapshot', 'hoth.ws'), os.path.join(dst, 'snapshot', 'hoth.ws'))
rp = os.path.join(dst, 'datatables', 'clientregion', 'hoth.iff')
r = dt_tool.read(rp)
for row in r['rows']:
    k = row[0].split(':')[-1]
    if k in ORIG:
        row[1], row[2] = ORIG[k]
dt_tool.write(r, rp)
subprocess.check_call([sys.executable, os.path.join(HERE, 'build_tre.py'),
                       r'C:\BellumGero\Backup\bg_custom1.tre.bak-20260927-prehoth',
                       os.path.join(HERE, 'dist', 'bg_custom1_hoth_only.tre'), dst])
shutil.rmtree(tmp)
