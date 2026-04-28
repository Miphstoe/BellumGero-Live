local WorldBossLootManager = require("screenplays.managers.world_boss_loot_manager")

local originalOnDamage = PrimordialWarlordGrakBoss.onDamage
local originalOnDeath = PrimordialWarlordGrakBoss.onDeath

local PRIMORDIAL_GRAK_LOOT_GROUPS = {
	{
		groups = {
			{group = "krayt_tissue_rare", chance = 4000000},
			{group = "krayt_pearls", chance = 3000000},
			{group = "armor_attachments", chance = 1500000},
			{group = "clothing_attachments", chance = 1500000}
		},
		lootChance = 10000000
	},
	{
		groups = {
			{group = "krayt_tissue_rare", chance = 4000000},
			{group = "krayt_pearls", chance = 3000000},
			{group = "armor_attachments", chance = 1500000},
			{group = "clothing_attachments", chance = 1500000}
		},
		lootChance = 7000000
	},
	{
		groups = {
			{group = "krayt_tissue_rare", chance = 4000000},
			{group = "krayt_pearls", chance = 3000000},
			{group = "armor_attachments", chance = 1500000},
			{group = "clothing_attachments", chance = 1500000}
		},
		lootChance = 5000000
	},
	{
		groups = {
			{group = "krayt_tissue_rare", chance = 4000000},
			{group = "krayt_pearls", chance = 3000000},
			{group = "armor_attachments", chance = 1500000},
			{group = "clothing_attachments", chance = 1500000}
		},
		lootChance = 2500000
	},
	{
		groups = {
			{group = "krayt_pearls", chance = 10000000}
		},
		lootChance = 1500000
	},
	{
		groups = {
			{group = "krayt_pearls", chance = 10000000}
		},
		lootChance = 1000000
	},
	{
		groups = {
			{group = "endgame_weapon_schematics", chance = 10000000}
		},
		lootChance = 1500000
	},
	{
		groups = {
			{group = "bg_token_group", chance = 10000000}
		},
		lootChance = 350000
	}
}

function PrimordialWarlordGrakBoss:onDamage(pBoss, pAttacker, damage)
	WorldBossLootManager:trackDamage(pBoss, pAttacker)

	if originalOnDamage then
		return originalOnDamage(self, pBoss, pAttacker, damage)
	end

	return 0
end

function PrimordialWarlordGrakBoss:onDeath(pBoss, pKiller)
	WorldBossLootManager:onBossDeath(pBoss, PRIMORDIAL_GRAK_LOOT_GROUPS, self.BOSS_NAME)

	if originalOnDeath then
		return originalOnDeath(self, pBoss, pKiller)
	end

	return 0
end

print("[GRAK-LOOT] Loot wrapper loaded - automatic world boss rewards enabled")
