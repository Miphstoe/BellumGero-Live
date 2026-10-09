object_building_player_atat_house = object_building_player_shared_atat_house:new {
	lotSize = 3,
	storageLimit = 600,
	baseMaintenanceRate = 16,
	allowedZones = {"corellia", "dantooine", "lok", "naboo", "rori", "talus", "tatooine", "endor", "yavin4", "dathomir"},
	publicStructure = 0,
	skillMods = {
		{"private_medical_rating", 100},
		{"private_buff_mind", 100},
		{"private_med_battle_fatigue", 5},
		{"private_safe_logout", 1}
	},
	childObjects = {
		{templateFile = "object/tangible/terminal/terminal_player_structure.iff", x = -3.4, z = 18.1, y = -12.3, ox = 0, oy = 0.707107, oz = 0, ow = 0.707107, cellid = 1, containmentType = -1},
		{templateFile = "object/tangible/sign/player/house_address.iff", x = -5.3, z = 3.26, y = 6.75, ox = 0, oy = -0.707107, oz = 0, ow = -0.707107, cellid = -1, containmentType = -1},
	},
	shopSigns = {
		{templateFile = "object/tangible/sign/player/house_address.iff", x = -5.3, z = 3.26, y = 6.75, ox = 0, oy = -0.707107, oz = 0, ow = -0.707107, cellid = -1, containmentType = -1, requiredSkill = "", suiItem = "@player_structure:house_address"},
		{templateFile = "object/tangible/sign/player/shop_sign_s01.iff", x = -13.39, z = 0.81, y = -3.36, ow = 0.707107, ox = 0, oz = 0, oy = 0.707107, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_01", suiItem = "@player_structure:shop_sign1"},
		{templateFile = "object/tangible/sign/player/shop_sign_s02.iff", x = -13.39, z = 0.81, y = -3.36, ow = 0.707107, ox = 0, oz = 0, oy = 0.707107, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_02", suiItem = "@player_structure:shop_sign2"},
		{templateFile = "object/tangible/sign/player/shop_sign_s03.iff", x = -13.39, z = 0.81, y = -3.36, ow = 0.707107, ox = 0, oz = 0, oy = 0.707107, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_03", suiItem = "@player_structure:shop_sign3"},
		{templateFile = "object/tangible/sign/player/shop_sign_s04.iff", x = -13.39, z = 0.81, y = -3.36, ow = 0.707107, ox = 0, oz = 0, oy = 0.707107, cellid = -1, containmentType = -1, requiredSkill = "crafting_merchant_management_04", suiItem = "@player_structure:shop_sign4"},
	},
	constructionMarker = "object/building/player/construction/construction_player_house_corellia_large_style_01.iff",
	length = 5,
	width = 7
}

ObjectTemplates:addTemplate(object_building_player_atat_house, "object/building/player/atat_house.iff")
