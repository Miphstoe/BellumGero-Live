object_building_player_tree_house = object_building_player_shared_tree_house:new {
	lotSize = 2,
	storageLimit = 400,
	baseMaintenanceRate = 10,
	allowedZones = {"corellia", "dantooine", "lok", "naboo", "rori", "talus", "tatooine", "endor", "yavin4", "dathomir"},
	publicStructure = 0,
	skillMods = {
		{"private_medical_rating", 100},
		{"private_buff_mind", 100},
		{"private_med_battle_fatigue", 5},
		{"private_safe_logout", 1},
		{"bio_engineer_assembly", 10},
		{"bio_engineer_experimentation", 5},
	},
	childObjects = {
		{templateFile = "object/tangible/terminal/terminal_player_structure.iff", x = -6.87, z = 1.0, y = 10.54, ox = 0, oy = 1, oz = 0, ow = 0, cellid = 1, containmentType = -1},
		{templateFile = "object/tangible/sign/player/house_address.iff", x = 0.09, z = 1.16, y = 11.00, ox = 0, oy = 0.38268, oz = 0, ow = 0.92388, cellid = -1, containmentType = -1},
	},
	shopSigns = {
		{templateFile = "object/tangible/sign/player/house_address.iff", x = 0.09, z = 1.16, y = 11.00, ox = 0, oy = 0.38268, oz = 0, ow = 0.92388, cellid = -1, containmentType = -1, requiredSkill = "", suiItem = "@player_structure:house_address"},
		{templateFile = "object/tangible/sign/player/shop_sign_s01.iff", x = -7.18, z = 1.0, y = 13.80, ow = 0.95213, ox = 0, oz = 0, oy = 0.30570, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_01", suiItem = "@player_structure:shop_sign1"},
		{templateFile = "object/tangible/sign/player/shop_sign_s02.iff", x = -7.93, z = 1.0, y = 14.40, ow = 0.95832, ox = 0, oz = 0, oy = 0.28569, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_02", suiItem = "@player_structure:shop_sign2"},
		{templateFile = "object/tangible/sign/player/shop_sign_s03.iff", x = -8.23, z = 1.0, y = 14.00, ow = 0.95832, ox = 0, oz = 0, oy = 0.28569, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_03", suiItem = "@player_structure:shop_sign3"},
		{templateFile = "object/tangible/sign/player/shop_sign_s04.iff", x = -8.58, z = 1.0, y = 14.68, ow = 0.95981, ox = 0, oz = 0, oy = 0.28067, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_04", suiItem = "@player_structure:shop_sign4"},
	},
	constructionMarker = "object/building/player/construction/construction_player_house_corellia_large_style_01.iff",
	length = 4,
	width = 5
}

ObjectTemplates:addTemplate(object_building_player_tree_house, "object/building/player/tree_house.iff")
