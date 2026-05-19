-- Mandalorian Spynet Operative
-- Spawned for Chapters 1+ private contract access
-- Rotates weekly through player cities; falls back to NPC city cantinas
-- Rotation logic handled by MandoWayOfLife screenplay (TODO: implement rotation)
-- Conversation: mandoSpynetOperativeConvoTemplate
-- TODO: replace template mesh with confirmed Mandalorian-armored client IFF

mando_spynet_operative = Creature:new {
	objectName   = "",
	customName   = "Mandalorian Operative",
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

	-- TODO: replace with distinct Mando operative mesh once confirmed
	templates    = {"object/mobile/dressed_bountyhunter_trainer_03.iff"},
	lootGroups   = {},

	primaryWeapon   = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "mandoSpynetOperativeConvoTemplate",
	primaryAttacks  = brawlermid,
	secondaryAttacks = {},
}

CreatureTemplates:addCreatureTemplate(mando_spynet_operative, "mando_spynet_operative")
