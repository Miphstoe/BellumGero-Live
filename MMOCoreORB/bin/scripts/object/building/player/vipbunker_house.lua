object_building_player_vipbunker_house = object_building_player_shared_vipbunker_house:new {
	lotSize = 2,
    storageLimit = 400,
	baseMaintenanceRate = 16,
	allowedZones = {"corellia", "dantooine", "lok", "naboo", "rori", "talus", "tatooine", "endor", "yavin4", "dathomir"},
	publicStructure = 0,
	skillMods = {
		{"private_medical_rating", 100},
		{"private_buff_mind", 100},
		{"private_med_battle_fatigue", 5},
		{"private_safe_logout", 1},
		{"clothing_assembly", 10},
		{"clothing_experimentation", 5}
	},
	childObjects = {
		{templateFile = "object/tangible/sign/player/house_address.iff", x = -3.27, z = 1.78, y = 0.37, ox = 0, oy = 0, oz = 0, ow = 1, cellid = -1, containmentType = -1},
		{templateFile = "object/tangible/terminal/terminal_player_structure.iff", x = -1.13, z = 0.35, y = 2.92, ox = 0, oy = 0.38268, oz = 0, ow = 0.92388, cellid = 1, containmentType = -1},
	},
	shopSigns = {
		{templateFile = "object/tangible/sign/player/house_address.iff", x = -3.27, z = 1.78, y = 0.37, ox = 0, oy = 0, oz = 0, ow = 1, cellid = -1, containmentType = -1, requiredSkill = "", suiItem = "@player_structure:house_address"},
		{templateFile = "object/tangible/sign/player/shop_sign_s01.iff", x = -0.68, z = 0.40, y = -0.79, ow = 1, ox = 0, oz = 0, oy = 0, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_01", suiItem = "@player_structure:shop_sign1"},
		{templateFile = "object/tangible/sign/player/shop_sign_s02.iff", x = -0.68, z = 0.40, y = -0.79, ow = 1, ox = 0, oz = 0, oy = 0, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_02", suiItem = "@player_structure:shop_sign2"},
		{templateFile = "object/tangible/sign/player/shop_sign_s03.iff", x = -0.68, z = 0.40, y = -0.79, ow = 1, ox = 0, oz = 0, oy = 0, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_03", suiItem = "@player_structure:shop_sign3"},
		{templateFile = "object/tangible/sign/player/shop_sign_s04.iff", x = -0.68, z = 0.40, y = -0.79, ow = 1, ox = 0, oz = 0, oy = 0, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_04", suiItem = "@player_structure:shop_sign4"}

	},
	constructionMarker = "object/building/player/construction/construction_player_house_corellia_large_style_01.iff",
	length = 5,
	width = 7
}

ObjectTemplates:addTemplate(object_building_player_vipbunker_house, "object/building/player/vipbunker_house.iff")