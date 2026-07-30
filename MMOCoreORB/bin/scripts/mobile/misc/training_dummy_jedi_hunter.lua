--
-- Bellum Gero Training Dummy benchmark
--
-- Matches jk_hunt_bh defenses, with Lightsaber resistance increased from 20 to 40 for PvP Bounty Hunter gear.
--

training_dummy_jedi_hunter = Creature:new {
	objectName = "@npc_spawner_n:cll_8",
	customName = "Dummy - Jedi Hunter",
	socialGroup = "",
	faction = "",
	mobType = MOB_DROID,
	level = 1,
	chanceHit = 0,
	damageMin = 0,
	damageMax = 0,
	baseXp = 0,
	baseHAM = 2000000,
	baseHAMmax = 2000000,
	armor = 1,
	resists = {90,90,90,90,90,90,90,90,40},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,

	-- 0x008000 STATIONARY + 0x010000 NOAIAGGRO
	creatureBitmask = 98304,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	scale = 1.0,

	templates = {"object/mobile/training_dummy.iff"},
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = {},
	secondaryAttacks = {}
}

CreatureTemplates:addCreatureTemplate(
	training_dummy_jedi_hunter,
	"training_dummy_jedi_hunter"
)
