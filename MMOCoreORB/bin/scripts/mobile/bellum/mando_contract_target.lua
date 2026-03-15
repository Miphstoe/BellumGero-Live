-- Mandalorian Way of Life — Private Contract Target
-- Spawned dynamically near the player when a private contract trial begins
-- Reactive combat only (no aggro on bystanders); player must engage first
-- Despawned on failure via MandoWayOfLife:failPrivateContract()
-- Completion detected via MandoWayOfLife:contractCheckEvent()
-- TODO: replace template mesh with a confirmed criminal/fugitive IFF

mando_contract_target = Creature:new {
	objectName      = "",
	customName      = "Private Contract Target",
	socialGroup     = "criminal",
	faction         = "",
	mobType         = MOB_NPC,
	level           = 55,
	chanceHit       = 0.65,
	damageMin       = 600,
	damageMax       = 850,
	baseXp          = 3500,
	baseHAM         = 42000,
	baseHAMmax      = 50000,
	armor           = 1,
	resists         = {10, 10, 0, 0, 20, 10, 0, 10, -1},
	meatType        = "",
	meatAmount      = 0,
	hideType        = "",
	hideAmount      = 0,
	boneType        = "",
	boneAmount      = 0,
	milk            = 0,
	tamingChance    = 0,
	ferocity        = 0,
	pvpBitmask      = ATTACKABLE,
	creatureBitmask = NONE,
	optionsBitmask  = AIENABLED,
	diet            = HERBIVORE,

	templates       = {"object/mobile/dressed_bountyhunter_trainer_01.iff"},
	lootGroups      = {
		{
			groups = { {groupTemplate = "mando_contract_kill_reward", weight = 10000000} },
			lootChance = 10000000,   -- 100% guaranteed drop
		},
		{
			groups = { {groupTemplate = "mando_contract_rare_bonus", weight = 10000000} },
			lootChance = 3000000,    -- 30% rare bonus drop
		},
	},

	primaryWeapon   = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks  = brawlermid,
	secondaryAttacks = {},
}

CreatureTemplates:addCreatureTemplate(mando_contract_target, "mando_contract_target")
