--
-- Bellum Gero Training Dummy benchmark
--
-- Matches the current Geo Lab Acklay defense profile.
--

training_dummy_acklay = Creature:new {
	objectName = "@npc_spawner_n:cll_8",
	customName = "Dummy - Acklay",
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
	armor = 2,
	resists = {130,145,155,155,145,30,30,30,-1},
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
	training_dummy_acklay,
	"training_dummy_acklay"
)
