-- Old Thunderhorn, the ancient bull of the Great Herds: Taanab roaming elite (screenplays/bellum/taanab_thunderhorn.lua).
taanab_old_thunderhorn = Creature:new {
	objectName = "",
	customName = "Old Thunderhorn",
	socialGroup = "bantha",
	faction = "",
	mobType = MOB_HERBIVORE,
	level = 130,
	chanceHit = 1.5,
	damageMin = 900,
	damageMax = 1300,
	baseXp = 12500,
	baseHAM = 200000,
	baseHAMmax = 240000,
	armor = 2,
	resists = {80,140,60,140,60,60,60,40,-1},
	meatType = "meat_herbivore",
	meatAmount = 2500,
	hideType = "hide_wooly",
	hideAmount = 2200,
	boneType = "bone_mammal",
	boneAmount = 1800,
	milkType = "milk_wild",
	milk = 1000,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = ATTACKABLE,
	creatureBitmask = HERD,
	optionsBitmask = AIENABLED,
	diet = HERBIVORE,
	templates = {"object/mobile/bantha_hue.iff"},
	hues = { 6 },
	scale = 2.4,
	lootGroups = {
		{
			groups = {
				{group = "taanab_thunderhorn_trophies", chance = 10000000}
			},
			lootChance = 10000000
		},
		{
			groups = {
				{group = "taanab_thunderhorn_trophies", chance = 10000000}
			},
			lootChance = 3500000
		},
		{
			groups = {
				{group = "bg_token_group", chance = 10000000}
			},
			lootChance = 300000
		}
	},
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	primaryAttacks = { {"creatureareaknockdown","stateAccuracyBonus=60"}, {"knockdownattack","stateAccuracyBonus=60"}, {"posturedownattack","stateAccuracyBonus=50"}, {"intimidationattack",""} },
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(taanab_old_thunderhorn, "taanab_old_thunderhorn")
