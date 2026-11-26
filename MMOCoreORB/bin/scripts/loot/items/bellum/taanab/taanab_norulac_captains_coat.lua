-- Taanab boss loot (Norulac raiders / Old Thunderhorn).
taanab_norulac_captains_coat = {
	minimumLevel = 0,
	maximumLevel = -1,
	customObjectName = "Norulac Raider Captain's Coat",
	directObjectTemplate = "object/tangible/wearables/jacket/jacket_ace_privateer.iff",
	craftingValues = {
		{"sockets", 3, 4, true},
	},
	customizationStringNames = {},
	customizationValues = {}
}

addLootItemTemplate("taanab_norulac_captains_coat", taanab_norulac_captains_coat)
