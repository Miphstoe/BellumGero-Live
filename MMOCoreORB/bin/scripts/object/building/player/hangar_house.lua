object_building_player_hangar_house = object_building_player_shared_hangar_house:new {
	lotSize = 5,
	storageLimit = 1000,
	baseMaintenanceRate = 50,
	allowedZones = {"corellia", "dantooine", "lok", "naboo", "rori", "talus", "tatooine", "endor", "yavin4", "dathomir"},
	publicStructure = 0,
	skillMods = {
		{"private_medical_rating", 100},
		{"private_buff_mind", 100},
		{"private_med_battle_fatigue", 5},
		{"private_safe_logout", 1},
		{"structure_assembly", 10},
		{"structure_experimentation", 5},
	},
	childObjects = {
		{templateFile = "object/tangible/terminal/terminal_player_structure.iff", x = -8.8, z = 0.74, y = -24.4, ox = 0, oy = 0.707107, oz = 0, ow = 0.707107, cellid = 1, containmentType = -1},
		{templateFile = "object/tangible/sign/player/house_address.iff", x = -11.28, z = 4.0, y = 1.223, ow = 0, ox = 0, oz = 0, oy = -1, cellid = -1, containmentType = -1},
	},
	shopSigns = {
		{templateFile = "object/tangible/sign/player/house_address.iff", x = -11.28, z = 4.0, y = 1.223, ow = 0, ox = 0, oz = 0, oy = -1, cellid = -1, containmentType = -1, requiredSkill = "", suiItem = "@player_structure:house_address"},
		{templateFile = "object/tangible/sign/player/shop_sign_s01.iff", x = 7.9249, z = 0.179972, y = 6.2, ow = 1, ox = 0, oz = 0, oy = 0, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_01", suiItem = "@player_structure:shop_sign1"},
		{templateFile = "object/tangible/sign/player/shop_sign_s02.iff", x = 7.9249, z = 0.179972, y = 6.2, ow = 1, ox = 0, oz = 0, oy = 0, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_02", suiItem = "@player_structure:shop_sign2"},
		{templateFile = "object/tangible/sign/player/shop_sign_s03.iff", x = 7.9249, z = 0.179972, y = 6.2, ow = 1, ox = 0, oz = 0, oy = 0, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_03", suiItem = "@player_structure:shop_sign3"},
		{templateFile = "object/tangible/sign/player/shop_sign_s04.iff", x = 7.9249, z = 0.179972, y = 6.2, ow = 1, ox = 0, oz = 0, oy = 0, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_04", suiItem = "@player_structure:shop_sign4"},
	},
	constructionMarker = "object/building/player/construction/construction_player_house_corellia_large_style_01.iff",
	length = 5,
	width = 7
}

ObjectTemplates:addTemplate(object_building_player_hangar_house, "object/building/player/hangar_house.iff")
