foundry_combat_module = {
	minimumLevel = 0,
	maximumLevel = -1,
	customObjectName = "Foundry Combat Module",
	directObjectTemplate = "object/tangible/component/droid/combat_module.iff",
	craftingValues = {
		{"cmbt_module", 100, 125, 0, false, 2},
	},
	customizationStringNames = {},
	customizationValues = {}
}
addLootItemTemplate("foundry_combat_module", foundry_combat_module)
