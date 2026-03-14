-- Mandalorian Foundling Informant
-- Dynamically spawned per-player on each planet by MandoWayOfLife:spawnInformant()
-- Despawned on planet turn-in by MandoWayOfLife:despawnInformant()
-- Conversation: mandoFoundlingInformantConvoTemplate
-- TODO: replace template mesh with confirmed Mandalorian-armored client IFF

mando_foundling_informant = Creature:new {
	objectName   = "Mandalorian Informant",
	socialGroup  = "neutral",
	faction      = "",
	mobType      = MOB_NPC,
	level        = 20,
	chanceHit    = 0.3,
	damageMin    = 50,
	damageMax    = 100,
	baseXp       = 0,
	baseHAM      = 2000,
	baseHAMmax   = 2400,
	armor        = 0,
	resists      = {0,0,0,0,0,0,0,-1,-1},
	meatType     = "",
	meatAmount   = 0,
	hideType     = "",
	hideAmount   = 0,
	boneType     = "",
	boneAmount   = 0,
	milk         = 0,
	tamingChance = 0,
	ferocity     = 0,
	pvpBitmask   = 0,
	creatureBitmask = NONE,
	optionsBitmask  = AIENABLED + INVULNERABLE + CONVERSABLE,
	diet         = HERBIVORE,

	-- TODO: replace with distinct Mandalorian informant mesh once confirmed
	templates    = {"object/mobile/dressed_bountyhunter_trainer_02.iff"},
	lootGroups   = {},

	primaryWeapon   = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "mandoFoundlingInformantConvoTemplate",
	primaryAttacks  = brawlermid,
	secondaryAttacks = {},
}

CreatureTemplates:addCreatureTemplate(mando_foundling_informant, "mando_foundling_informant")
