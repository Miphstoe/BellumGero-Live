bounty_tracking_droid = Creature:new {
	objectName = "@droid_name:probe_droid",
	socialGroup = "",
	faction = "",
	mobType = MOB_DROID,
	level = 1,
	chanceHit = 0.0,
	damageMin = 0,
	damageMax = 0,
	baseXp = 0,
	baseHAM = 6000,
	baseHAMmax = 6000,
	armor = 2, -- 0=none, 1=light, 2=medium, 3=heavy; this feeds an exponential armor-piercing formula, keep it small
	-- {kinetic, energy, blast, heat, cold, electricity, acid, stun, lightSaber} percent damage reduction.
	-- Deliberately higher than the flavor probot/seeker droids this scan prop must survive a few hits.
	resists = {40,40,40,40,40,40,40,20,20},
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

	templates = {"object/creature/npc/droid/crafted/probe_droid.iff"},
	lootGroups = {},

	-- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(bounty_tracking_droid, "bounty_tracking_droid")
