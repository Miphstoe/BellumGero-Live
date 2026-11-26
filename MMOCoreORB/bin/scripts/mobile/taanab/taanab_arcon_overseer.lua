-- Arcon farm overseer at the hex farms: reports the Norulac raid status and lets players start a raid
-- (TaanabNorulacRaidWorldBoss:startFromOverseer). Spawned by taanab_norulac_raid_worldboss.lua.
taanab_arcon_overseer = Creature:new {
	customName = "Arcon Farm Overseer",
	socialGroup = "",
	faction = "",
	level = 1,
	chanceHit = 0.5,
	damageMin = 0,
	damageMax = 0,
	baseXp = 0,
	baseHAM = 1000,
	baseHAMmax = 1000,
	armor = 0,
	resists = { -1, -1, -1, -1, -1, -1, -1, -1, -1 },
	pvpBitmask = NONE,
	creatureBitmask = NONE,
	optionsBitmask = INVULNERABLE + CONVERSABLE,
	diet = HERBIVORE,

	templates = {"object/mobile/dressed_quest_farmer.iff"},

	conversationTemplate = "taanabArconOverseerConvoTemplate",
	attacks = {}
}

CreatureTemplates:addCreatureTemplate(taanab_arcon_overseer, "taanab_arcon_overseer")
