-- enhanced_gaping_spider_boss.lua
-- World Boss variant of the Enhanced Gaping Spider (tougher stats + 5 guaranteed drops)
-- at the very top of enhanced_gaping_spider_boss.lua:
print("[EGSPIDER] loading mobile: enhanced_gaping_spider_boss")

enhanced_gaping_spider_boss = Creature:new {
	objectName = "@mob/creature_names:geonosian_gaping_spider_fire",
	customName = "Searing Broodwarden - The Spider Queen",
	socialGroup = "geonosian_creature",
	mobType = MOB_CARNIVORE,
	faction = "",
	level = 350,
	chanceHit = 6.5,
	damageMin = 1500,
	damageMax = 2400,
	baseXp = 45000,
	baseHAM = 1320000,
	baseHAMmax = 1380000,
	armor = 3,
	resists = {180, 85, 35, 195, 35, 85, 85, 85, 25}, -- tougher across the board, still a couple soft spots
	meatType = "meat_insect",
	meatAmount = 50,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
	creatureBitmask = PACK + KILLER,
	optionsBitmask = AIENABLED,
	diet = CARNIVORE,

	templates = {"object/mobile/gaping_spider.iff"},
	scale = 3.0,

	lootGroups = {
		-- Loot groups removed - using WorldBossLootManager for automatic distribution
		-- Players who damage the boss receive loot directly to inventory
	},    
	-- Keep the fearsome flame spit; melee as secondary
	primaryWeapon = "object/weapon/ranged/creature/creature_spit_heavy_flame.iff",
	secondaryWeapon = "unarmed",
	conversationTemplate = "",

	-- Keep original attacks for compatibility (we can add more later if you want)
	primaryAttacks   = { {"strongpoison",""}, {"stunattack",""} },
	secondaryAttacks = { {"strongpoison",""}, {"stunattack",""} }
}

CreatureTemplates:addCreatureTemplate(enhanced_gaping_spider_boss, "enhanced_gaping_spider_boss")
print("[EGSPIDER] registered template: enhanced_gaping_spider_boss")

