#!/usr/bin/env python3
"""gen_boss_loot.py — give every boss fight the Hoth boss loot, at the Hoth cave-boss rates. Idempotent.

The rates come from gen_hoth_mobiles.LOOT_BOSS (every hoth_* entry), so the cave bosses stay the single source.
  * Corpse-loot bosses (mobile lootGroups, BOSSES below): the Hoth entries are appended between marker comments;
    each entry rolls independently, so existing drop rates are untouched.
  * World bosses (WorldBossLootManager) and scripted per-player bosses (The Hand, Zaritha, Valen Kade, the Sunday
    event) pick from equal-share collections and ignore lootChance, so they get an extra per-player roll instead:
    screenplays/bellum/hoth_boss_bonus_loot.lua -> giveHothBossBonusLoot(), which uses createLootFromCollection
    (honours lootChance). HOOKS below insert one call per reward path."""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import gen_hoth_mobiles

SCRIPTS = r'\\wsl.localhost\Debian\home\EnderWookie\workspace\BellumGero-Hoth\MMOCoreORB\bin\scripts'
BEGIN, END = '-- BEGIN Hoth boss loot (gen_boss_loot.py)', '-- END Hoth boss loot'
TAG = '-- Hoth boss loot (gen_boss_loot.py)'

ENTRIES = [(g, int(c)) for g, c in re.findall(r'\{group = "(hoth_[a-z_]+)", chance = 10000000\}\s*\},\s*lootChance = (\d+)',
                                              gen_hoth_mobiles.LOOT_BOSS)]

BOSSES = [f'mobile/{p}.lua' for p in (
    # event bosses
    'event/ancient_krayt_king', 'event/annihilator_unit_kr_9', 'event/autonomous_war_machine', 'event/boss_grakk_na_joor',
    'event/boss_rulo_besh_ka', 'event/boss_tarko_muu_zenn', 'event/boss_vreego_makk_tarn', 'event/c3po_event',
    'event/dune_reaver', 'event/execution_droid_kr_44', 'event/fleshrend_matriarch_woolamander', 'event/giant_ewok_graaku',
    'event/giant_ewok_nakku', 'event/giant_ewok_torga', 'event/giant_ewok_warchief', 'event/gravejaw_colossus_woolamander',
    'event/krayt_dragon_ancient_event', 'event/r2_d2_event', 'event/rendhide_overlord_woolamander', 'event/sandfang_alpha',
    'event/spineclaw_alpha_woolamander', 'event/tactical_unit_bx_77', 'event/twin_spine_terror', 'event/wookiee_jedi_event',
    'event/zerathul_buried_king',
    # Bellum Gero bosses
    'bellum/dreadmaw_mauler', 'bellum/field_captain_rax_vorn', 'bellum/gloomfang_mauler', 'bellum/high_strategist_velkor_thane',
    'bellum/imperial_traitor', 'bellum/imperial_traitor_elite', 'bellum/rebel_traitor', 'bellum/rebel_traitor_elite',
    'bellum/rotmaw_mauler', 'bellum/supreme_warlord_darth_malvek', 'bellum/war_general_kael_draxus', 'bellum/xalgorath',
    # custom event bosses
    'custom_events/black_sun_deathstalker', 'custom_events/black_sun_shadowfang', 'custom_events/black_sun_viper',
    'custom_events/brain_food_nuna', 'custom_events/brussel_sprout_nuna', 'custom_events/christal_nuna',
    'custom_events/tiny_cabbage_nuna', 'custom_events/deez_nuts_jedi', 'custom_events/dude_jedi',
    'custom_events/humdinger_jedi', 'custom_events/throat_goat_jedi',
    # classic dungeon / named bosses
    'dathomir/axkva_min', 'tatooine/tusken_king', 'dungeon/death_watch_bunker/death_watch_overlord',
    'dungeon/death_watch_bunker/death_watch_overlord_mines', 'dungeon/geonosian_bio_lab/acklay',
    'dungeon/droid_foundry/foundry_overseer_ig_series', 'dungeon/warren/bors_teraud', 'naboo/mordran',
    'corellia/lord_nyax', 'endor/gorax',
)]

# (file, anchor line (must occur once), indent) -> call inserted right after the anchor
HOOKS = [
    ('screenplays/managers/world_boss_loot_manager.lua', '  -- Build reward message',
     '  if giveHothBossBonusLoot then giveHothBossBonusLoot(pPlayer, pInventory, lootLevel) end ' + TAG + '\n', 'before'),
    ('screenplays/bellum/the_hand_boss_loot_wrapper.lua',
     '\tpcall(function() itemOID = createLoot(pInventory, chosenGroup, bossLevel, true) end)',
     '\tif giveHothBossBonusLoot then giveHothBossBonusLoot(pPlayer, pInventory, bossLevel) end ' + TAG + '\n', 'after'),
    ('screenplays/caves/dathomir_rancor_cave.lua',
     '\tlocal item2 = _rollOneNightLoot(pInventory, lootGroups, bossLevel)',
     '\tif giveHothBossBonusLoot then giveHothBossBonusLoot(pPlayer, pInventory, bossLevel) end ' + TAG + '\n', 'after'),
    ('screenplays/caves/dantooine_force_crystal_hunter_cave.lua',
     '        pcall(_giveBossLoot, pRecipient, INQUISITOR_LOOT_GROUPS, "Valen Kade (Fallen Inquisitor)", 400)',
     '        if giveHothBossBonusLoot then pcall(giveHothBossBonusLoot, pRecipient, nil, 400) end ' + TAG + '\n', 'after'),
    ('screenplays/bellum/bg_sunday_dantooine_event.lua',
     '\tlocal itemOid = createLoot(pInventory, rewardGroup, bossLevel or 1, true)',
     '\tif giveHothBossBonusLoot then giveHothBossBonusLoot(pPlayer, pInventory, bossLevel or 1) end ' + TAG + '\n', 'after'),
]


def path(rel):
    return os.path.join(SCRIPTS, *rel.split('/'))


def read(rel):
    return open(path(rel), encoding='utf-8', newline='').read()


def write(rel, s):
    open(path(rel), 'w', encoding='utf-8', newline='').write(s)


def collections_lua(indent):
    out = []
    for g, c in ENTRIES:
        out.append(f'{indent}{{\n{indent}\tgroups = {{\n{indent}\t\t{{group = "{g}", chance = 10000000}}\n'
                   f'{indent}\t}},\n{indent}\tlootChance = {c}\n{indent}}}')
    return ',\n'.join(out)


def patch_mobile(rel):
    s = read(rel)
    nl = '\r\n' if '\r\n' in s else '\n'
    s = s.replace('\r\n', '\n')
    s = re.sub(r',?\n[ \t]*' + re.escape(BEGIN) + r'.*?' + re.escape(END) + r'[^\n]*', '', s, flags=re.S)  # idempotent
    m = re.search(r'lootGroups\s*=\s*\{', s)
    assert m, f'{rel}: no lootGroups'
    depth, i = 0, m.end() - 1
    while True:  # find the matching close brace
        if s[i] == '{':
            depth += 1
        elif s[i] == '}':
            depth -= 1
            if depth == 0:
                break
        i += 1
    body = s[m.end():i]
    assert body.strip(), f'{rel}: empty lootGroups (loot comes from a screenplay)'
    line_start = s.rfind('\n', 0, i) + 1
    close_indent = re.match(r'[ \t]*', s[line_start:]).group(0)
    indent = close_indent + '\t'
    head = s[:i].rstrip()
    sep = '' if head.endswith(',') else ','
    block = f'{sep}\n{indent}{BEGIN}\n{collections_lua(indent)}\n{indent}{END}\n{close_indent}'
    s = head + block + s[i:]
    write(rel, s.replace('\n', nl))


BONUS_LUA = '''-- Generated by NewPlanets/gen_boss_loot.py. Hoth boss loot at the Hoth cave-boss rates, rolled once per
-- rewarded player by the world bosses and scripted per-player bosses (their own pickers ignore lootChance).
HOTH_BOSS_BONUS_LOOT = {
%s
}

function giveHothBossBonusLoot(pPlayer, pInventory, level)
	if pPlayer == nil then return end
	if pInventory == nil then
		pcall(function() pInventory = CreatureObject(pPlayer):getSlottedObject("inventory") end)
	end
	if pInventory == nil then return end

	local inv = SceneObject(pInventory)
	local before = inv:getContainerObjectsSize()
	local ok = pcall(function() createLootFromCollection(pInventory, HOTH_BOSS_BONUS_LOOT, level or 1) end)
	if not ok then return end

	local names = {}
	for i = before, inv:getContainerObjectsSize() - 1 do
		local pItem = inv:getContainerObject(i)
		if pItem ~= nil then
			table.insert(names, SceneObject(pItem):getDisplayedName() or "an item")
		end
	end
	if #names > 0 then
		pcall(function()
			CreatureObject(pPlayer):sendSystemMessage("\\\\#00FFFFHoth spoils: " .. table.concat(names, ", ") .. "!")
		end)
	end
end

-- Per-player boss rewards for bosses whose corpse carries no loot (the Hoth cave bosses): every player who damaged
-- the boss (tracked by WorldBossLootManager:trackDamage) and is within range when it dies rolls lootTable into their
-- own inventory. If nobody was tracked, the killer (or a pet's owner) and their group in range qualify.
function giveHothBossRewards(pBoss, pKiller, lootTable, range)
	local soBoss = SceneObject(pBoss)
	local bossOID = soBoss:getObjectID()
	local level = 1
	pcall(function() level = CreatureObject(pBoss):getLevel() or 1 end)
	local bossName = soBoss:getDisplayedName() or "the boss"

	local recipients, seen = {}, {}
	local function add(pPlayer)
		if pPlayer == nil then return end
		local ok = false
		pcall(function()
			ok = SceneObject(pPlayer):isPlayerCreature() and SceneObject(pPlayer):isInRangeWithObject(pBoss, range)
		end)
		local oid = SceneObject(pPlayer):getObjectID()
		if ok and not seen[oid] then
			seen[oid] = true
			table.insert(recipients, pPlayer)
		end
	end

	local damagers = (_G.__WB_DAMAGE_TRACKING or {})[bossOID] or {}
	for playerOID, _ in pairs(damagers) do
		pcall(function() add(getSceneObject(tonumber(playerOID))) end)
	end
	if #recipients == 0 and pKiller ~= nil then
		local pPlayer = nil
		pcall(function()
			if SceneObject(pKiller):isPlayerCreature() then
				pPlayer = pKiller
			else
				local owner = CreatureObject(pKiller):getOwner()
				if owner ~= nil and SceneObject(owner):isPlayerCreature() then pPlayer = owner end
			end
		end)
		if pPlayer ~= nil then
			add(pPlayer)
			pcall(function()
				local co = CreatureObject(pPlayer)
				if co:isGrouped() then
					for i = 0, co:getGroupSize() - 1 do add(co:getGroupMember(i)) end
				end
			end)
		end
	end
	if _G.__WB_DAMAGE_TRACKING ~= nil then _G.__WB_DAMAGE_TRACKING[bossOID] = nil end

	for _, pPlayer in ipairs(recipients) do
		pcall(function()
			local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
			if pInventory == nil then return end
			local inv = SceneObject(pInventory)
			local before = inv:getContainerObjectsSize()
			createLootFromCollection(pInventory, lootTable, level)
			local names = {}
			for i = before, inv:getContainerObjectsSize() - 1 do
				local pItem = inv:getContainerObject(i)
				if pItem ~= nil then table.insert(names, SceneObject(pItem):getDisplayedName() or "an item") end
			end
			local msg = #names > 0 and table.concat(names, ", ") or "nothing this time"
			CreatureObject(pPlayer):sendSystemMessage("\\\\#00FF00Your share from " .. bossName .. ": " .. msg .. ".")
		end)
	end
end
'''


def main():
    assert len(ENTRIES) == 8, ENTRIES
    print('rates:', ', '.join(f'{g} {c / 100000:g}%' for g, c in ENTRIES))
    for rel in BOSSES:
        patch_mobile(rel)
    print(f'{len(BOSSES)} corpse-loot bosses patched')

    write('screenplays/bellum/hoth_boss_bonus_loot.lua', BONUS_LUA % collections_lua('\t'))
    sp = read('screenplays/screenplays.lua')
    inc = 'includeFile("bellum/hoth_boss_bonus_loot.lua")'
    if inc not in sp:
        anchor = 'includeFile("bellum/the_hand_boss_loot_wrapper.lua")'
        nl = '\r\n' if '\r\n' in sp else '\n'
        assert sp.count(anchor) == 1
        sp = sp.replace(anchor, inc + nl + anchor)
        write('screenplays/screenplays.lua', sp)
    for rel, anchor, call, where in HOOKS:
        s = read(rel)
        nl = '\r\n' if '\r\n' in s else '\n'
        s = '\n'.join(l for l in s.replace('\r\n', '\n').split('\n') if TAG not in l)  # idempotent
        assert s.count(anchor + '\n') == 1, (rel, s.count(anchor))
        s = s.replace(anchor + '\n', (call + anchor + '\n') if where == 'before' else (anchor + '\n' + call))
        write(rel, s.replace('\n', nl))
    print(f'{len(HOOKS)} per-player reward paths hooked')


if __name__ == '__main__':
    main()
