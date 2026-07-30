-- Bellum: holographic bounty hunter guild contact.
-- Appears from the tracking fob to deliver the daily bounty story
-- (speaks via spatial chat; not conversable, not attackable).
mando_holo_bh = Creature:new {
	objectName   = "",
	customName   = "Guild Contact (Hologram)",
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
	optionsBitmask  = AIENABLED + INVULNERABLE,
	diet         = HERBIVORE,

	templates    = {"object/mobile/mando_holo_bh.iff"},
	lootGroups   = {},

	primaryWeapon   = "unarmed",
	secondaryWeapon = "none",
	primaryAttacks  = brawlermid,
	secondaryAttacks = {},
}

CreatureTemplates:addCreatureTemplate(mando_holo_bh, "mando_holo_bh")
