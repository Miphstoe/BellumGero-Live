-- Mandalorian Trialmaster / Recruiter
-- Static spawn at Mos Eisley Cantina (Tatooine)
-- Spawned by MandoWayOfLife:start()
-- Conversation: mandoTrialmasterConvoTemplate
-- TODO: replace template mesh with confirmed Mandalorian-armored client IFF

mando_trialmaster = Creature:new {
	objectName   = "",
	customName   = "Mandalorian Recruiter",
	socialGroup  = "neutral",
	faction      = "",
	mobType      = MOB_NPC,
	level        = 50,
	chanceHit    = 0.5,
	damageMin    = 100,
	damageMax    = 200,
	baseXp       = 0,
	baseHAM      = 5000,
	baseHAMmax   = 6000,
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

	-- TODO: replace with Mandalorian-armored mesh once confirmed
	templates    = {"object/mobile/dressed_bountyhunter_trainer_01.iff"},
	lootGroups   = {},

	primaryWeapon   = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "mandoTrialmasterConvoTemplate",
	primaryAttacks  = brawlermid,
	secondaryAttacks = {},
}

CreatureTemplates:addCreatureTemplate(mando_trialmaster, "mando_trialmaster")
