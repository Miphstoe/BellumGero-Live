#!/usr/bin/env python3
"""shader_ab.py — A/B test for the glowing vehicles: writes build/shader_ab with the ported a_envmask_specmap_cbmp
shaders pointed at the stock non-bump effect a_envmask_specmap.eft. Build a test TRE with
  python build_tre.py dist/devbg/bg_custom1.tre dist/test/bg_custom1_ab.tre build/shader_ab"""
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from iff_clone import clone_raw

SHADERS = ['ric_920_speeder_aesc22', 'xj6_air_speeder_aesc22', 'single_pod_airspeeder_aesc22',
           'republic_gunship_itv_b_asc13', 'republic_gunship_itv_c_asc13']
SRC = os.path.join(HERE, 'build', 'hoth_loot', 'shader')
OUT = os.path.join(HERE, 'build', 'shader_ab')
shutil.rmtree(OUT, ignore_errors=True)
for s in SHADERS:
    clone_raw(os.path.join(SRC, s + '.sht'), os.path.join(OUT, 'shader', s + '.sht'),
              {'effect\\a_envmask_specmap_cbmp.eft': 'effect\\a_envmask_specmap.eft'})
    print('wrote', s)
