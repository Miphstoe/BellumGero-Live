#!/usr/bin/env python3
"""tune_hoth_loot.py <bin/scripts dir> [loot_factor] [credits_multiplier]

Regular (non-boss) Hoth mobs dropped too much (2026-10-13). For every mobile/hoth/*.lua whose lootGroups carry a
lootChance (bosses have an empty block and are skipped):
  * every lootChance is multiplied by loot_factor (default 0.5, minimum 1)
  * the generic armor_all / weapons_all / wearables_all junk group is removed (raider, probe droid)
  * `creditsMultiplier = N` (default 3) is set, read by CreatureTemplate (new field) and applied to the kill credits
Idempotent: a marker comment is written above lootGroups and files that carry it are left alone. Run after
gen_hoth_mobiles.py regenerates the mobiles."""
import glob, os, re, sys

scripts = sys.argv[1]
factor = float(sys.argv[2]) if len(sys.argv) > 2 else 0.5
credits = sys.argv[3] if len(sys.argv) > 3 else '3'
MARK = '-- loot tuned (tune_hoth_loot.py): lootChance x%g, creditsMultiplier %s' % (factor, credits)
JUNK = re.compile(r'[ \t]*\{\s*groups = \{\s*\{group = "armor_all", chance = 3000000\},\s*\{group = "weapons_all", chance = 3500000\},\s*\{group = "wearables_all", chance = 3500000\}\s*\},\s*lootChance = \d+\s*\},?[ \t]*\r?\n?', re.S)

done = skipped = 0
for f in sorted(glob.glob(os.path.join(scripts, 'mobile', 'hoth', '*.lua'))):
    if os.path.basename(f) == 'serverobjects.lua':
        continue
    s = open(f, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    if 'tune_hoth_loot.py' in s:
        skipped += 1; continue
    if 'lootGroups = {' not in s or 'lootChance' not in s:
        continue  # boss (per-player rewards) or no loot
    s = JUNK.sub('', s)
    s = re.sub(r'lootChance = (\d+)', lambda m: 'lootChance = %d' % max(1, round(int(m.group(1)) * factor)), s)
    s = re.sub(r'^(\tlevel = \d+,)$', lambda m: m.group(1) + nl + '\tcreditsMultiplier = ' + credits + ',', s, count=1, flags=re.M)
    assert 'creditsMultiplier' in s, f
    s = s.replace('\tlootGroups = {', '\t' + MARK + nl + '\tlootGroups = {', 1)
    open(f, 'w', encoding='utf-8', newline='').write(s)
    done += 1
    chances = re.findall(r'lootChance = (\d+)', s)
    print('%-32s credits x%s  lootChance: %s' % (os.path.basename(f)[:-4], credits, ' '.join('%.2f%%' % (int(c) / 100000) for c in chances)))
print(f'{done} mobiles tuned, {skipped} already tuned')
