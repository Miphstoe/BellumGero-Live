-- Norulac Raider Cave, Taanab (-861, 7206): Corellia's Afarathu cave building. Spawn points are the stock Afarathu
-- cave layout (caves/corellia_afarathu_cave.lua) on Taanab's cell IDs (6036722-6036732). The back chamber holds
-- Sela Drux, Kessic's quartermaster; her rewards are per player like the Hoth cave bosses, so her corpse carries none.
local WorldBossLootManager = require("screenplays.managers.world_boss_loot_manager")

TAANAB_CAVE_BOSS_LOOT = {
	{ groups = { {group = "taanab_norulac_loot", chance = 10000000} }, lootChance = 6000000 },
	{
		groups = {
			{group = "color_crystals", chance = 3500000},
			{group = "armor_attachments", chance = 3250000},
			{group = "clothing_attachments", chance = 3250000}
		},
		lootChance = 5000000
	},
	{ groups = { {group = "bg_token_group", chance = 10000000} }, lootChance = 250000 }
}

TaanabNorulacRaiderCaveScreenPlay = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "TaanabNorulacRaiderCaveScreenPlay",
	planet = "taanab",
	bossTemplate = "taanab_sela_drux",
	lootRange = 64,

	-- {template, respawn, x, z, y, heading, cell}
	mobiles = {
		{"norulac_raider", 300, -0.6, -13.7, -8.3, 0, 6036722},
		{"norulac_raider", 300, 11.3, -14.2, -5.5, 0, 6036722},
		{"norulac_raider", 300, 9.7, -23.9, -28.3, 0, 6036723},
		{"norulac_raider", 300, -11.3, -30.7, -27.1, 0, 6036723},
		{"norulac_cutthroat", 300, -1.8, -40.7, -74.1, 0, 6036724},
		{"norulac_cutthroat", 300, 2.6, -40.4, -62.4, 0, 6036724},
		{"norulac_cutthroat", 300, 3.4, -41.0, -72.6, 0, 6036724},
		{"norulac_raider", 300, 49.3, -46.8, -53.7, 0, 6036725},
		{"norulac_raider", 300, 43.8, -46.1, -95.1, 0, 6036725},
		{"norulac_raider", 300, 23.6, -45.7, -102.8, 0, 6036725},
		{"norulac_cutthroat", 300, -1.7, -45.8, -147.8, 0, 6036726},
		{"norulac_cutthroat", 300, -11.0, -44.4, -136.4, 0, 6036726},
		{"norulac_cutthroat", 300, -4.2, -64.0, -234.2, 0, 6036728},
		{"norulac_cutthroat", 300, -21.7, -65.4, -244.6, 0, 6036728},
		{"norulac_cutthroat", 300, -95.3, -73.7, -170.0, 0, 6036729},
		{"norulac_enforcer", 300, -83.5, -71.6, -169.2, 0, 6036729},
		{"norulac_enforcer", 300, -100.5, -72.9, -159.1, 0, 6036729},
		{"norulac_enforcer", 300, -111.7, -69.4, -170.6, 0, 6036729},
		{"norulac_enforcer", 300, -85.4, -101.5, -111.2, 0, 6036732},
		{"norulac_enforcer", 300, -92.8, -101.1, -111.9, 0, 6036732},
		{"taanab_sela_drux", 1800, -90.7, -101.1, -104.8, 0, 6036732},
	}
}

registerScreenPlay("TaanabNorulacRaiderCaveScreenPlay", true)

function TaanabNorulacRaiderCaveScreenPlay:start()
	if (isZoneEnabled(self.planet)) then
		self:spawnMobiles()
	end
end

function TaanabNorulacRaiderCaveScreenPlay:spawnMobiles()
	for _, m in ipairs(self.mobiles) do
		local pMobile = spawnMobile(self.planet, m[1], m[2], m[3], m[4], m[5], m[6], m[7])

		if pMobile ~= nil and m[1] == self.bossTemplate then
			-- observers return 0, so they survive the boss's respawns (same object)
			createObserver(DAMAGERECEIVED, "TaanabNorulacRaiderCaveScreenPlay", "onBossDamage", pMobile)
			createObserver(OBJECTDESTRUCTION, "TaanabNorulacRaiderCaveScreenPlay", "onBossDied", pMobile)
		end
	end
end

function TaanabNorulacRaiderCaveScreenPlay:onBossDamage(pBoss, pAttacker, damage)
	WorldBossLootManager:trackDamage(pBoss, pAttacker)
	return 0
end

function TaanabNorulacRaiderCaveScreenPlay:onBossDied(pBoss, pKiller)
	if pBoss == nil then
		return 0
	end

	giveHothBossRewards(pBoss, pKiller, TAANAB_CAVE_BOSS_LOOT, self.lootRange)
	return 0
end
