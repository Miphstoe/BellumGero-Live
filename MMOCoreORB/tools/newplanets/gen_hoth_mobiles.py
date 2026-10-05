#!/usr/bin/env python3
"""gen_hoth_mobiles.py — generate Hoth creature/NPC/lair/spawn Lua into the Ender_Hoth worktree.

Re-runnable: every generated file is fully rewritten, and registration lines are
only appended when missing. Edit the tables below and re-run to rebalance.
"""
import math
import os

ROOT = r'\\wsl.localhost\Debian\home\EnderWookie\workspace\BellumGero-Hoth\MMOCoreORB\bin\scripts'
MOB = os.path.join(ROOT, 'mobile')


def write(rel, text):
    path = os.path.join(ROOT, *rel.split('/'))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    return rel


def register(rel_list_file, line, after_prefix=None):
    """Append an includeFile line to a serverobjects list if it is not there yet."""
    path = os.path.join(ROOT, *rel_list_file.split('/'))
    s = open(path, encoding='utf-8', newline='').read()
    if line in s:
        return False
    nl = '\r\n' if '\r\n' in s else '\n'
    if after_prefix:
        lines = s.split(nl)
        idx = max(i for i, l in enumerate(lines) if l.startswith(after_prefix))
        lines.insert(idx + 1, line)
        s = nl.join(lines)
    else:
        s = s.rstrip('\r\n') + nl + line + nl
    open(path, 'w', encoding='utf-8', newline='').write(s)
    return True


# --------------------------------------------------------------------------
# Creatures. ham/dmg/xp follow the Dathomir rancor -> Lok kimogila curve.
# --------------------------------------------------------------------------
LOOT_BEAST = """{
		{
			groups = {
				{group = "armor_all", chance = 3000000},
				{group = "weapons_all", chance = 3500000},
				{group = "wearables_all", chance = 3500000}
			},
			lootChance = %d
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 250000
		}
	}"""


def HOOK(group, chance):
    """Extra lootGroups entry (with leading comma), rolled independently of the other entries. Groups come from gen_hoth_loot.py."""
    return f''',
		{{
			groups = {{
				{{group = "{group}", chance = 10000000}}
			}},
			lootChance = {chance}
		}}'''


CREATURES = [
    dict(key='hoth_tauntaun', name='a Hoth tauntaun', social='tauntaun', mob='MOB_HERBIVORE', level=60,
         hit=0.55, dmg=(430, 560), xp=5830, ham=(11000, 13000), armor=1, res='{120,120,20,150,20,150,20,20,-1}',
         meat=('meat_herbivore', 700), hide=('hide_wooly', 600), bone=('bone_mammal', 500), milk=300,
         pvp='ATTACKABLE', cbits='HERD', diet='HERBIVORE', tmpl='object/mobile/tauntaun_hue.iff',
         hues='{ 16, 17, 18, 19, 20, 21, 22, 23 }', scale=1.0, loot=0,
         attacks='{ {"knockdownattack",""}, {"dizzyattack",""} }'),
    dict(key='hoth_tauntaun_bull', name='a tauntaun bull', social='tauntaun', mob='MOB_HERBIVORE', level=66,
         hit=0.62, dmg=(460, 630), xp=6380, ham=(11500, 14000), armor=1, res='{130,130,25,160,25,160,25,25,-1}',
         meat=('meat_herbivore', 850), hide=('hide_wooly', 750), bone=('bone_mammal', 600), milk=0,
         pvp='AGGRESSIVE + ATTACKABLE + ENEMY', cbits='PACK + HERD', diet='HERBIVORE', tmpl='object/mobile/tauntaun_hue.iff',
         hues='{ 24, 25, 26, 27, 28, 29, 30, 31 }', scale=1.15, loot=0,
         attacks='{ {"knockdownattack",""}, {"creatureareaknockdown",""} }'),
    dict(key='hoth_ice_mynock', name='an ice mynock', social='mynock', mob='MOB_CARNIVORE', level=62,
         hit=0.58, dmg=(440, 590), xp=6010, ham=(10000, 12000), armor=1, res='{110,110,20,20,170,110,20,20,-1}',
         meat=('meat_carnivore', 60), hide=('hide_leathery', 80), bone=('bone_mammal', 30), milk=0,
         pvp='AGGRESSIVE + ATTACKABLE + ENEMY', cbits='PACK', diet='CARNIVORE', tmpl='object/mobile/salt_mynock_hue.iff',
         hues='{ 0, 1, 2, 3, 4, 5, 6, 7 }', scale=1.1, loot=0,
         attacks='{ {"blindattack",""}, {"knockdownattack",""} }'),
    dict(key='hoth_greater_ice_mynock', name='a greater ice mynock', social='mynock', mob='MOB_CARNIVORE', level=70,
         hit=0.68, dmg=(500, 700), xp=6750, ham=(11500, 14000), armor=1, res='{130,130,25,25,190,130,25,25,-1}',
         meat=('meat_carnivore', 90), hide=('hide_leathery', 110), bone=('bone_mammal', 50), milk=0,
         pvp='AGGRESSIVE + ATTACKABLE + ENEMY', cbits='PACK + KILLER', diet='CARNIVORE', tmpl='object/mobile/salt_mynock_hue.iff',
         hues='{ 8, 9, 10, 11, 12, 13, 14, 15 }', scale=1.35, loot=0,
         attacks='{ {"blindattack",""}, {"creatureareaknockdown",""} }'),
    dict(key='hoth_wampa', name='a wampa', social='wampa', mob='MOB_CARNIVORE', level=80,
         hit=0.78, dmg=(570, 850), xp=7668, ham=(12000, 15000), armor=1, res='{140,160,30,200,30,200,30,30,-1}',
         meat=('meat_carnivore', 900), hide=('hide_wooly', 900), bone=('bone_mammal', 750), milk=0,
         pvp='AGGRESSIVE + ATTACKABLE + ENEMY', cbits='KILLER + STALKER', diet='CARNIVORE', tmpl='object/mobile/wampa.iff',
         hues=None, scale=1.0, loot=2300000, extra=HOOK('hoth_ice_decor', 500000) + HOOK('hoth_decor_common', 300000),
         attacks='{ {"intimidationattack",""}, {"knockdownattack",""} }'),
    dict(key='hoth_elder_wampa', name='an elder wampa', social='wampa', mob='MOB_CARNIVORE', level=88,
         hit=0.85, dmg=(600, 900), xp=8408, ham=(13000, 16000), armor=1, res='{150,170,40,210,40,210,40,40,-1}',
         meat=('meat_carnivore', 1000), hide=('hide_wooly', 1000), bone=('bone_mammal', 850), milk=0,
         pvp='AGGRESSIVE + ATTACKABLE + ENEMY', cbits='KILLER + STALKER', diet='CARNIVORE', tmpl='object/mobile/wampa.iff',
         hues=None, scale=1.15, loot=2780000, extra=HOOK('hoth_ice_decor', 700000) + HOOK('hoth_decor_common', 400000),
         attacks='{ {"stunattack",""}, {"creatureareaknockdown",""} }'),
    dict(key='hoth_wampa_matriarch', name='the wampa matriarch', social='wampa', mob='MOB_CARNIVORE', level=95,
         hit=0.92, dmg=(650, 1000), xp=9057, ham=(36000, 40000), armor=2, res='{160,180,45,220,45,220,45,45,-1}',
         meat=('meat_carnivore', 1200), hide=('hide_wooly', 1200), bone=('bone_mammal', 1000), milk=0,
         pvp='AGGRESSIVE + ATTACKABLE + ENEMY', cbits='KILLER', diet='CARNIVORE', tmpl='object/mobile/wampa.iff',
         hues=None, scale=1.45, loot=0, lootstr=None,
         attacks='{ {"stunattack",""}, {"creatureareaknockdown",""}, {"intimidationattack",""} }'),
]


LOOT_BOSS = """{
		{
			groups = {
				{group = "armor_all", chance = 3000000},
				{group = "weapons_all", chance = 3500000},
				{group = "wearables_all", chance = 3500000}
			},
			lootChance = 8000000
		},
		{
			groups = {
				{group = "armor_all", chance = 3000000},
				{group = "weapons_all", chance = 3500000},
				{group = "wearables_all", chance = 3500000}
			},
			lootChance = 6000000
		},
		{
			groups = {
				{group = "endgame_weapon_schematics", chance = 10000000}
			},
			lootChance = 1000000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 2500000
		},
		{
			groups = {
				{group = "hoth_paintings", chance = 10000000}
			},
			lootChance = 2500000
		},
		{
			groups = {
				{group = "hoth_decor_rare", chance = 10000000}
			},
			lootChance = 1500000
		},
		{
			groups = {
				{group = "hoth_ice_decor", chance = 10000000}
			},
			lootChance = 2000000
		},
		{
			groups = {
				{group = "hoth_art_rare", chance = 10000000}
			},
			lootChance = 1000000
		},
		{
			groups = {
				{group = "hoth_vehicle_schematics", chance = 10000000}
			},
			lootChance = 500000
		},
		{
			groups = {
				{group = "hoth_vehicle_deeds", chance = 10000000}
			},
			lootChance = 200000
		}
	}"""

# Custom boss paintings (gen_hoth_art.py): bosses roll hoth_art_rare at 10% (LOOT_BOSS above); every other Hoth
# mobile gets this trickle chance.
ART_TRICKLE = 50000  # 0.5%


def _boss(key, name, level, ham, dmg, scale, social='wampa', tmpl='object/mobile/wampa.iff', attacks=None, hues=None,
          meat=('meat_carnivore', 1400), hide=('hide_wooly', 1400), bone=('bone_mammal', 1200)):
    return dict(key=key, name=name, social=social, mob='MOB_CARNIVORE', level=level,
                hit=round(0.85 + (level - 85) * 0.012, 2), dmg=dmg, xp=int(level * 96), ham=ham, armor=2,
                res='{160,180,45,220,45,220,45,45,-1}', meat=meat, hide=hide, bone=bone, milk=0,
                pvp='AGGRESSIVE + ATTACKABLE + ENEMY', cbits='KILLER', diet='CARNIVORE', tmpl=tmpl, hues=hues,
                scale=scale, loot=0, lootstr=LOOT_BOSS,
                attacks=attacks or '{ {"stunattack",""}, {"creatureareaknockdown",""}, {"intimidationattack",""} }')


# Fixed cave bosses (placed by hoth_ice_caves.lua, not by the world spawner).
BOSSES = [
    _boss('hoth_wampa_frostfang', 'Frostfang', 90, (30000, 34000), (620, 950), 1.3),
    _boss('hoth_wampa_icemaw', 'Icemaw', 90, (30000, 34000), (620, 950), 1.3,
          attacks='{ {"creatureareaknockdown",""}, {"dizzyattack",""}, {"intimidationattack",""} }'),
    _boss('hoth_wampa_snowblind', 'Snowblind the Ravager', 92, (32000, 36000), (640, 980), 1.35,
          attacks='{ {"blindattack",""}, {"creatureareaknockdown",""}, {"stunattack",""} }'),
    _boss('hoth_wampa_patriarch', 'the wampa patriarch', 98, (40000, 45000), (700, 1100), 1.5),
    _boss('hoth_mynock_broodmother', 'the mynock broodmother', 85, (26000, 30000), (580, 880), 1.8, social='mynock',
          tmpl='object/mobile/salt_mynock_hue.iff', hues='{ 16, 17, 18, 19, 20, 21, 22, 23 }',
          attacks='{ {"blindattack",""}, {"creatureareaknockdown",""} }',
          meat=('meat_carnivore', 150), hide=('hide_leathery', 200), bone=('bone_mammal', 80)),
]
# The matriarch moved from a random world lair to a fixed cave boss: give her boss loot too.
next(c for c in CREATURES if c['key'] == 'hoth_wampa_matriarch')['lootstr'] = LOOT_BOSS
for _c in CREATURES:
    if _c.get('lootstr') is None:  # non-boss creatures: trickle chance at the custom paintings
        _c['extra'] = _c.get('extra', '') + HOOK('hoth_art_rare', ART_TRICKLE)


def creature_lua(c):
    hues = '\n\thues = %s,' % c['hues'] if c['hues'] else ''
    loot = c.get('lootstr') or (LOOT_BEAST % c['loot'] if c['loot'] else '{}')
    if c.get('extra'):
        loot = ('{' + c['extra'][1:] if loot == '{}' else loot.rstrip()[:-1].rstrip() + c['extra']) + '\n\t}'
    return f'''{c['key']} = Creature:new {{
	objectName = "",
	customName = "{c['name']}",
	socialGroup = "{c['social']}",
	faction = "",
	mobType = {c['mob']},
	level = {c['level']},
	chanceHit = {c['hit']},
	damageMin = {c['dmg'][0]},
	damageMax = {c['dmg'][1]},
	baseXp = {c['xp']},
	baseHAM = {c['ham'][0]},
	baseHAMmax = {c['ham'][1]},
	armor = {c['armor']},
	resists = {c['res']},
	meatType = "{c['meat'][0]}",
	meatAmount = {c['meat'][1]},
	hideType = "{c['hide'][0]}",
	hideAmount = {c['hide'][1]},
	boneType = "{c['bone'][0]}",
	boneAmount = {c['bone'][1]},
	milk = {c['milk']},
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = {c['pvp']},
	creatureBitmask = {c['cbits']},
	optionsBitmask = AIENABLED,
	diet = {c['diet']},
	templates = {{"{c['tmpl']}"}},{hues}
	scale = {c['scale']},
	lootGroups = {loot},
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = {c['attacks']},
	secondaryAttacks = {{ }}
}}

CreatureTemplates:addCreatureTemplate({c['key']}, "{c['key']}")
'''


PROBE = '''hoth_probe_droid = Creature:new {
	objectName = "",
	customName = "an Imperial probe droid",
	socialGroup = "imperial",
	faction = "",
	mobType = MOB_DROID,
	level = 68,
	chanceHit = 0.65,
	damageMin = 480,
	damageMax = 660,
	baseXp = 6563,
	baseHAM = 10500,
	baseHAMmax = 12500,
	armor = 1,
	resists = {140,140,140,30,30,30,30,-1,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	templates = {"object/mobile/probot.iff"},
	lootGroups = {
		{
			groups = {
				{group = "armor_all", chance = 3000000},
				{group = "weapons_all", chance = 3500000},
				{group = "wearables_all", chance = 3500000}
			},
			lootChance = 2000000
		}''' + HOOK('hoth_art_rare', ART_TRICKLE) + '''
	},
	defaultAttack = "attack",
	primaryWeapon = "droid_probot_ranged",
	secondaryWeapon = "none",
	conversationTemplate = ""
}

CreatureTemplates:addCreatureTemplate(hoth_probe_droid, "hoth_probe_droid")
'''

# --------------------------------------------------------------------------
# NPCs
# --------------------------------------------------------------------------
NPCS = [
    dict(key='hoth_snowtrooper', name='a snowtrooper', rname='NAME_STORMTROOPER', social='imperial', faction='imperial',
         level=70, hit=0.7, dmg=(500, 700), xp=6747, ham=(12000, 14500), armor=1, res='{40,40,60,40,80,40,40,-1,-1}',
         tmpls=['object/mobile/snowtrooper_s01.iff'], loot='imperial_tier_3', pw='stormtrooper_rifle', sw='stormtrooper_pistol',
         extra=HOOK('hoth_snowtrooper_schematics', 150000) + HOOK('hoth_decor_common', 200000),
         pa='merge(riflemanmaster,marksmanmaster)', sa='merge(pistoleermaster,marksmanmaster)',
         react='@npc_reaction/stormtrooper', pers='@hireling/hireling_stormtrooper'),
    dict(key='hoth_snowtrooper_sergeant', name='a snowtrooper sergeant', rname='NAME_STORMTROOPER', social='imperial', faction='imperial',
         level=78, hit=0.78, dmg=(560, 800), xp=7484, ham=(13500, 16000), armor=1, res='{50,50,70,50,90,50,50,-1,-1}',
         tmpls=['object/mobile/snowtrooper_s01.iff'], loot='imperial_tier_4', pw='stormtrooper_rifle', sw='stormtrooper_pistol',
         extra=HOOK('hoth_snowtrooper_schematics', 400000) + HOOK('hoth_decor_common', 300000),
         pa='merge(riflemanmaster,marksmanmaster)', sa='merge(pistoleermaster,marksmanmaster)',
         react='@npc_reaction/stormtrooper', pers='@hireling/hireling_stormtrooper'),
    dict(key='hoth_rebel_snow_soldier', name='a Rebel snow soldier', rname='NAME_GENERIC', social='rebel', faction='rebel',
         level=70, hit=0.7, dmg=(500, 700), xp=6747, ham=(12000, 14500), armor=1, res='{40,40,60,40,80,40,40,-1,-1}',
         tmpls=['object/mobile/rebel_snow_m_01.iff', 'object/mobile/rebel_snow_f_01.iff'], loot='rebel_tier_3',
         extra=HOOK('hoth_rebel_snow_schematics', 150000) + HOOK('hoth_decor_common', 200000),
         pw='rebel_carbine', sw='rebel_pistol', pa='merge(carbineermaster,marksmanmaster)', sa='merge(pistoleermaster,marksmanmaster)',
         react='@npc_reaction/military', pers='@hireling/hireling_military'),
    dict(key='hoth_rebel_snow_sergeant', name='a Rebel snow sergeant', rname='NAME_GENERIC', social='rebel', faction='rebel',
         level=78, hit=0.78, dmg=(560, 800), xp=7484, ham=(13500, 16000), armor=1, res='{50,50,70,50,90,50,50,-1,-1}',
         tmpls=['object/mobile/rebel_snow_m_01.iff', 'object/mobile/rebel_snow_f_01.iff'], loot='rebel_tier_4',
         extra=HOOK('hoth_rebel_snow_schematics', 400000) + HOOK('hoth_decor_common', 300000),
         pw='rebel_carbine', sw='rebel_pistol', pa='merge(carbineermaster,marksmanmaster)', sa='merge(pistoleermaster,marksmanmaster)',
         react='@npc_reaction/military', pers='@hireling/hireling_military'),
]
for _n in NPCS:
    _n['extra'] = _n.get('extra', '') + HOOK('hoth_art_rare', ART_TRICKLE)


def npc_lua(n):
    tm = ',\n\t\t'.join('"%s"' % t for t in n['tmpls'])
    return f'''{n['key']} = Creature:new {{
	objectName = "",
	customName = "{n['name']}",
	randomNameType = {n['rname']},
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "{n['social']}",
	faction = "{n['faction']}",
	level = {n['level']},
	chanceHit = {n['hit']},
	damageMin = {n['dmg'][0]},
	damageMax = {n['dmg'][1]},
	baseXp = {n['xp']},
	baseHAM = {n['ham'][0]},
	baseHAMmax = {n['ham'][1]},
	armor = {n['armor']},
	resists = {n['res']},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	templates = {{
		{tm}
	}},
	lootGroups = {{
		{{
			groups = {{
				{{group = "{n['loot']}", chance = 10000000}}
			}}
		}},
		{{
			groups = {{
				{{group = "bg_token_group", chance = 10000000}}
			}},
			lootChance = 250000
		}}{n.get('extra', '')}
	}},
	primaryWeapon = "{n['pw']}",
	secondaryWeapon = "{n['sw']}",
	thrownWeapon = "thrown_weapons",
	conversationTemplate = "",
	reactionStf = "{n['react']}",
	personalityStf = "{n['pers']}",
	primaryAttacks = {n['pa']},
	secondaryAttacks = {n['sa']}
}}

CreatureTemplates:addCreatureTemplate({n['key']}, "{n['key']}")
'''


SCAVENGER = '''hoth_scavenger = Creature:new {
	objectName = "",
	customName = "a Hoth scavenger",
	randomNameType = NAME_GENERIC,
	randomNameTag = true,
	mobType = MOB_NPC,
	socialGroup = "townsperson",
	faction = "",
	level = 62,
	chanceHit = 0.58,
	damageMin = 440,
	damageMax = 590,
	baseXp = 6010,
	baseHAM = 10000,
	baseHAMmax = 12000,
	armor = 1,
	resists = {30,30,30,30,60,30,30,-1,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = NONE,
	creatureBitmask = NONE,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	templates = {
		"object/mobile/dressed_tatooine_scavenger.iff",
		"object/mobile/dressed_mercenary_commander_zab_m.iff",
		"object/mobile/dressed_goon_twk_male_01.iff",
		"object/mobile/dressed_robber_human_female_01.iff"
	},
	lootGroups = {},
	primaryWeapon = "pirate_weapons_heavy",
	secondaryWeapon = "unarmed",
	conversationTemplate = "",
	reactionStf = "@npc_reaction/slang",
	primaryAttacks = marksmanmid,
	secondaryAttacks = brawlermid
}

CreatureTemplates:addCreatureTemplate(hoth_scavenger, "hoth_scavenger")
'''

RAIDER = SCAVENGER.replace('hoth_scavenger', 'hoth_scavenger_raider') \
    .replace('customName = "a Hoth scavenger"', 'customName = "a scavenger raider"') \
    .replace('socialGroup = "townsperson"', 'socialGroup = "thug"') \
    .replace('faction = ""', 'faction = "thug"') \
    .replace('level = 62,', 'level = 68,') \
    .replace('pvpBitmask = NONE,', 'pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,') \
    .replace('creatureBitmask = NONE,', 'creatureBitmask = PACK + KILLER,') \
    .replace('lootGroups = {},', '''lootGroups = {
		{
			groups = {
				{group = "armor_all", chance = 3000000},
				{group = "weapons_all", chance = 3500000},
				{group = "wearables_all", chance = 3500000}
			},
			lootChance = 2500000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 250000
		}''' + HOOK('hoth_paintings', 500000) + HOOK('hoth_decor_common', 1000000) + HOOK('hoth_art_rare', ART_TRICKLE) + '''
	},''')

SALVAGE = SCAVENGER.replace('hoth_scavenger', 'hoth_imperial_salvage_tech') \
    .replace('customName = "a Hoth scavenger"', 'customName = "an Imperial salvage technician"') \
    .replace('randomNameType = NAME_GENERIC', 'randomNameType = NAME_STORMTROOPER') \
    .replace('socialGroup = "townsperson"', 'socialGroup = "imperial"') \
    .replace('faction = ""', 'faction = "imperial"') \
    .replace('level = 62,', 'level = 66,') \
    .replace('pvpBitmask = NONE,', 'pvpBitmask = ATTACKABLE,') \
    .replace('creatureBitmask = NONE,', 'creatureBitmask = PACK,') \
    .replace('''		"object/mobile/dressed_tatooine_scavenger.iff",
		"object/mobile/dressed_mercenary_commander_zab_m.iff",
		"object/mobile/dressed_goon_twk_male_01.iff",
		"object/mobile/dressed_robber_human_female_01.iff"''', '		"object/mobile/dressed_imperial_atat_pilot_m.iff"') \
    .replace('primaryWeapon = "pirate_weapons_heavy"', 'primaryWeapon = "imperial_weapons_light"') \
    .replace('reactionStf = "@npc_reaction/slang"', 'reactionStf = "@npc_reaction/military"') \
    .replace('lootGroups = {},', 'lootGroups = {' + HOOK('hoth_decor_common', 1500000)[1:] + HOOK('hoth_art_rare', ART_TRICKLE) + '\n\t},')

# Plain scavengers (derived templates above already replaced their own lootGroups block).
SCAVENGER = SCAVENGER.replace('lootGroups = {},', 'lootGroups = {' + HOOK('hoth_art_rare', ART_TRICKLE)[1:] + '\n\t},')

# --------------------------------------------------------------------------
# Lairs: (key, folder, mobiles, buildingType/lair building, extra)
# --------------------------------------------------------------------------
BONES = 'object/tangible/lair/base/poi_all_lair_bones_large.iff'
MOUND = 'object/tangible/lair/base/poi_all_lair_mound_large.iff'
LAIRS = [
    ('hoth_tauntaun_herd_neutral_none', 'creature_dynamic', [('hoth_tauntaun', 4), ('hoth_tauntaun_bull', 1)], None, 15),
    ('hoth_tauntaun_lair_neutral_medium', 'creature_lair', [('hoth_tauntaun', 2), ('hoth_tauntaun_bull', 1)], MOUND, 15),
    ('hoth_ice_mynock_pack_neutral_none', 'creature_dynamic', [('hoth_ice_mynock', 3), ('hoth_greater_ice_mynock', 1)], None, 15),
    ('hoth_ice_mynock_lair_neutral_medium', 'creature_lair', [('hoth_ice_mynock', 2), ('hoth_greater_ice_mynock', 1)], MOUND, 15),
    ('hoth_probe_droid_neutral_none', 'creature_dynamic', [('hoth_probe_droid', 1)], None, 6),
    ('hoth_wampa_neutral_none', 'creature_dynamic', [('hoth_wampa', 1)], None, 6),
    ('hoth_wampa_lair_neutral_large', 'creature_lair', [('hoth_wampa', 2), ('hoth_elder_wampa', 1)], BONES, 15),
    ('hoth_snowtrooper_patrol_imperial_none', 'npc_dynamic', [('hoth_snowtrooper', 3), ('hoth_snowtrooper_sergeant', 1)], 'npc', 9),
    ('hoth_rebel_snow_patrol_rebel_none', 'npc_dynamic', [('hoth_rebel_snow_soldier', 3), ('hoth_rebel_snow_sergeant', 1)], 'npc', 9),
]


def lair_lua(key, kind, mobs, building, limit):
    m = ', '.join('{"%s", %d}' % x for x in mobs)
    if kind == 'creature_lair':
        b = '{"%s"}' % building
        body = '\n'.join(f'\tbuildings{t} = {b},' for t in ['VeryEasy', 'Easy', 'Medium', 'Hard', 'VeryHard'])
        tail = ''
    else:
        body = '\n'.join(f'\tbuildings{t} = {{}},' for t in ['VeryEasy', 'Easy', 'Medium', 'Hard', 'VeryHard'])
        tail = '\tmobType = "npc",\n\tbuildingType = "none"' if building == 'npc' else '\tbuildingType = "none"'
    return f'''{key} = Lair:new {{
	mobiles = {{{m}}},
	spawnLimit = {limit},
{body}
{tail}
}}

addLairTemplate("{key}", {key})
'''.replace('\n\n}', '\n}')


SPAWN = [  # (lair, minDifficulty, weighting)
    ('hoth_tauntaun_herd_neutral_none', 60, 60),
    ('hoth_tauntaun_lair_neutral_medium', 60, 40),
    ('hoth_ice_mynock_pack_neutral_none', 62, 45),
    ('hoth_ice_mynock_lair_neutral_medium', 62, 35),
    ('hoth_probe_droid_neutral_none', 68, 25),
    ('hoth_wampa_neutral_none', 80, 30),
    ('hoth_wampa_lair_neutral_large', 80, 25),
    ('hoth_snowtrooper_patrol_imperial_none', 70, 12),
    ('hoth_rebel_snow_patrol_rebel_none', 70, 12),
]


def spawn_lua():
    rows = []
    for lair, mn, w in SPAWN:
        rows.append(f'''		{{
			lairTemplateName = "{lair}",
			spawnLimit = -1,
			minDifficulty = {mn},
			maxDifficulty = 500,
			numberToSpawn = 15,
			weighting = {w},
			size = 25,
		}}''')
    return 'hoth_world = {\n\tlairSpawns = {\n' + ',\n'.join(rows) + '\n\t}\n}\n\naddSpawnGroup("hoth_world", hoth_world);\n'


# --------------------------------------------------------------------------
# Static spawns at the outposts
# --------------------------------------------------------------------------
OUTPOSTS = {  # starport centre x, height, y
    'scavenger': (0.0, 0.0, -2000.0),
    'imperial': (5927.6, 3.0, -406.5),
    'rebel': (4525.0, 87.8, 1164.0),
}


def ring(center, radius, n, start=0):
    cx, h, cy = center
    out = []
    for i in range(n):
        a = math.radians(start + i * 360.0 / n)
        x, y = cx + radius * math.sin(a), cy + radius * math.cos(a)
        heading = int(round(math.degrees(a))) % 360
        heading = heading - 360 if heading > 180 else heading
        out.append((round(x, 1), h, round(y, 1), heading))  # face outward
    return out


def static_lua():
    rows = []
    def add(tmpl, resp, pts):
        for x, h, y, hd in pts:
            rows.append(f'\t\t{{"{tmpl}", {resp}, {x}, {h}, {y}, {hd}, 0}},')
    imp, reb, scav = OUTPOSTS['imperial'], OUTPOSTS['rebel'], OUTPOSTS['scavenger']
    add('hoth_snowtrooper', 300, ring(imp, 40, 6, 30))
    add('hoth_snowtrooper_sergeant', 300, ring(imp, 28, 2, 0))
    add('imperial_recruiter', 60, [(imp[0] - 12.0, imp[1], imp[2] + 14.0, 180)])
    add('hoth_rebel_snow_soldier', 300, ring(reb, 40, 6, 30))
    add('hoth_rebel_snow_sergeant', 300, ring(reb, 28, 2, 0))
    add('rebel_recruiter', 60, [(reb[0] - 12.0, reb[1], reb[2] + 14.0, 180)])
    # Scavenger camp at the Lucky Despot wreck (tents + campfire at -95, -2047)
    camp = (-95.0, 0.0, -2047.0)
    add('hoth_scavenger', 300, ring(camp, 9, 5, 15))
    add('junk_dealer', 60, [(camp[0] + 6.0, camp[1], camp[2] + 4.0, -120)])
    # Imperial salvage team on the AT-ST wreck inside the Imperial Outpost
    add('hoth_imperial_salvage_tech', 300, ring((5893.5, 3.2, -401.0), 6, 3, 60))
    # Shield-generator battlefield east of the Rebel Outpost: squads facing each other
    for gx, gh, gy in [(5654.0, -2.0, 1029.0), (5190.0, -2.0, 534.0)]:
        add('hoth_snowtrooper', 300, [(gx - 18.0 + i * 3.0, gh, gy - 14.0, 0) for i in range(4)])
        add('hoth_snowtrooper_sergeant', 300, [(gx - 12.0, gh, gy - 18.0, 0)])
        add('hoth_rebel_snow_soldier', 300, [(gx - 18.0 + i * 3.0, gh, gy + 14.0, 180) for i in range(4)])
        add('hoth_rebel_snow_sergeant', 300, [(gx - 12.0, gh, gy + 18.0, 180)])
    # Raiders stripping the generator at (5068, 1300)
    add('hoth_scavenger_raider', 300, ring((5068.0, 0.0, 1300.0), 10, 6, 0))
    return '''-- Generated by NewPlanets/gen_hoth_mobiles.py. Positions ring each snapshot starport / site.
HothStaticSpawnsScreenPlay = ScreenPlay:new {
	screenplayName = "HothStaticSpawnsScreenPlay",
	planet = "hoth",
	mobiles = {
''' + '\n'.join(rows) + '''
	}
}

registerScreenPlay("HothStaticSpawnsScreenPlay", true)

function HothStaticSpawnsScreenPlay:start()
	if (isZoneEnabled(self.planet)) then
		self:spawnMobiles()
	end
end

function HothStaticSpawnsScreenPlay:spawnMobiles()
	local mobiles = self.mobiles

	for i = 1, #mobiles do
		local mobile = mobiles[i]
		local pMobile = spawnMobile(self.planet, mobile[1], mobile[2], mobile[3], mobile[4], mobile[5], mobile[6], mobile[7])

		if pMobile ~= nil then
			AiAgent(pMobile):addObjectFlag(AI_STATIC)
		end
	end
end
'''


CAVE_PLAN = {  # building -> (boss cells {index: boss}, regular mobiles, elite mobile)
    'cave_01_ice': ({11: 'hoth_wampa_frostfang'}, 'hoth_wampa', 'hoth_elder_wampa'),
    'cave_04_ice_s01': ({11: 'hoth_wampa_icemaw'}, 'hoth_wampa', 'hoth_elder_wampa'),
    'cave_02_ice': ({9: 'hoth_wampa_snowblind'}, 'hoth_wampa', 'hoth_elder_wampa'),
    'cave_03_ice': ({29: 'hoth_wampa_matriarch', 9: 'hoth_wampa_patriarch'}, 'hoth_wampa', 'hoth_elder_wampa'),
    'cave_06_flatland_s01_ice': ({11: 'hoth_mynock_broodmother'}, 'hoth_ice_mynock', 'hoth_greater_ice_mynock'),
}
CAVE_RESPAWN, BOSS_RESPAWN = 420, 1800


def cave_lua():
    import json
    caves = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'server_prep', 'hoth_cave_points.json')))
    rows = []
    for cave in caves:
        bosses, regular, elite = CAVE_PLAN[cave['building']]
        rows.append(f'\t\t-- {cave["building"]} at {cave["world"]} (building {cave["objectId"]})')
        for cell in cave['cells']:
            pts, idx = cell['points'], cell['index']
            if not pts:
                continue
            if idx in bosses:
                plan = [(bosses[idx], BOSS_RESPAWN), (elite, CAVE_RESPAWN), (elite, CAVE_RESPAWN)]
            elif idx <= 2:
                plan = [(regular, CAVE_RESPAWN), (regular, CAVE_RESPAWN)]
            else:
                plan = [(regular, CAVE_RESPAWN), (elite if idx % 2 else regular, CAVE_RESPAWN)]
            for (tmpl, resp), (x, h, y) in zip(plan, pts):
                heading = (idx * 47 + int(abs(x) * 7)) % 360 - 180
                rows.append(f'\t\t{{"{tmpl}", {resp}, {x}, {h}, {y}, {heading}, {cell["cellId"]}}},')
    return '''-- Generated by NewPlanets/gen_hoth_mobiles.py from server_prep/hoth_cave_points.json.
-- {template, respawn, cell-local x, height, y, heading, cell object id from snapshot/hoth.ws}
HothIceCavesScreenPlay = ScreenPlay:new {
	screenplayName = "HothIceCavesScreenPlay",
	planet = "hoth",
	mobiles = {
''' + '\n'.join(rows) + '''
	}
}

registerScreenPlay("HothIceCavesScreenPlay", true)

function HothIceCavesScreenPlay:start()
	if (isZoneEnabled(self.planet)) then
		self:spawnMobiles()
	end
end

function HothIceCavesScreenPlay:spawnMobiles()
	local mobiles = self.mobiles

	for i = 1, #mobiles do
		local mobile = mobiles[i]
		spawnMobile(self.planet, mobile[1], mobile[2], mobile[3], mobile[4], mobile[5], mobile[6], mobile[7])
	end
end
'''


def unregister(rel_list_file, line):
    path = os.path.join(ROOT, *rel_list_file.split('/'))
    s = open(path, encoding='utf-8', newline='').read()
    if line not in s:
        return False
    nl = '\r\n' if '\r\n' in s else '\n'
    s = s.replace(line + nl, '').replace(nl + line, '')
    open(path, 'w', encoding='utf-8', newline='').write(s)
    return True


def terminals():
    """planet_manager.lua planetObjects rows: mission, bank and bazaar terminals at each outpost."""
    rows = []
    kinds = {
        'scavenger': ['terminal_mission', 'terminal_bank', 'terminal_bazaar'],
        'imperial': ['terminal_mission_imperial', 'terminal_bank', 'terminal_bazaar'],
        'rebel': ['terminal_mission_rebel', 'terminal_bank', 'terminal_bazaar'],
    }
    for name, (cx, h, cy) in OUTPOSTS.items():
        for i, t in enumerate(kinds[name]):
            x, y = round(cx - 16.0 + i * 3.0, 1), round(cy - 14.0, 1)
            rows.append(f'\t\t{{templateFile = "object/tangible/terminal/{t}.iff", ox = 0, oy = 0, oz = 0, ow = 1, x = {x}, z = {h}, y = {y}, parentid = 0}},')
    return rows


def main():
    made = []
    for c in CREATURES:
        made.append(write(f'mobile/hoth/{c["key"]}.lua', creature_lua(c)))
    made.append(write('mobile/hoth/hoth_probe_droid.lua', PROBE))
    for n in NPCS:
        made.append(write(f'mobile/hoth/{n["key"]}.lua', npc_lua(n)))
    made.append(write('mobile/hoth/hoth_scavenger.lua', SCAVENGER))
    made.append(write('mobile/hoth/hoth_scavenger_raider.lua', RAIDER))
    made.append(write('mobile/hoth/hoth_imperial_salvage_tech.lua', SALVAGE))
    for b in BOSSES:
        made.append(write(f'mobile/hoth/{b["key"]}.lua', creature_lua(b)))
    keys = ([c['key'] for c in CREATURES] + [b['key'] for b in BOSSES] + ['hoth_probe_droid'] + [n['key'] for n in NPCS] +
            ['hoth_scavenger', 'hoth_scavenger_raider', 'hoth_imperial_salvage_tech'])
    made.append(write('mobile/hoth/serverobjects.lua', ''.join(f'includeFile("hoth/{k}.lua")\n' for k in keys)))
    register('mobile/serverobjects.lua', 'includeFile("hoth/serverobjects.lua")', after_prefix='includeFile("endor/')

    for key, kind, mobs, building, limit in LAIRS:
        made.append(write(f'mobile/lair/{kind}/hoth/{key}.lua', lair_lua(key, kind, mobs, building, limit)))
        register(f'mobile/lair/{kind}/serverobjects.lua', f'includeFile("lair/{kind}/hoth/{key}.lua")')

    # The matriarch boss lair was retired in favour of a fixed cave boss.
    old = 'lair/creature_lair/hoth/hoth_wampa_lair_neutral_boss_01.lua'
    if unregister('mobile/lair/creature_lair/serverobjects.lua', f'includeFile("{old}")'):
        print('unregistered', old)
    stale = os.path.join(MOB, *old.split('/'))
    if os.path.exists(stale):
        os.remove(stale)
        print('removed', 'mobile/' + old)

    made.append(write('screenplays/caves/hoth_ice_caves.lua', cave_lua()))
    register('screenplays/screenplays.lua', 'includeFile("caves/hoth_ice_caves.lua")', after_prefix='includeFile("caves/')

    made.append(write('mobile/spawn/hoth/hoth_world.lua', spawn_lua()))
    register('mobile/spawn/serverobjects.lua', 'includeFile("spawn/hoth/hoth_world.lua")')

    made.append(write('screenplays/static_spawns/hoth_static_spawns.lua', static_lua()))
    register('screenplays/screenplays.lua', 'includeFile("static_spawns/hoth_static_spawns.lua")',
             after_prefix='includeFile("static_spawns/')

    print('\n'.join(made))
    print('\n-- planetObjects for hoth:')
    print('\n'.join(terminals()))


if __name__ == '__main__':
    main()
