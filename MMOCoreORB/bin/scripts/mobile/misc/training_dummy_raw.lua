--
-- Bellum Gero Training Dummy benchmark
--
-- Pure raw-output baseline: Armor 0 and vulnerable to every damage type.
--

training_dummy_raw = Creature:new {
	objectName = "@npc_spawner_n:cll_8",
	customName = "Dummy - Raw",
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
	armor = 0,
	resists = {-1,-1,-1,-1,-1,-1,-1,-1,-1},
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
	training_dummy_raw,
	"training_dummy_raw"
)
