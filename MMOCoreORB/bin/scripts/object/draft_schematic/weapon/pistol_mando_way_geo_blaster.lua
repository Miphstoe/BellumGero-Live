object_draft_schematic_weapon_pistol_mando_way_geo_blaster = object_draft_schematic_weapon_shared_pistol_mando_way_geo_blaster:new {

	templateType = DRAFTSCHEMATIC,

	customObjectName = "Mandalorian Geonosian Blaster Pistol",

	craftingToolTab = 1,
	complexity = 32,
	size = 1,
	factoryCrateType = "object/factory/factory_crate_weapon.iff",

	xpType = "crafting_weapons_general",
	xp = 380,

	assemblySkill = "weapon_assembly",
	experimentingSkill = "weapon_experimentation",
	customizationSkill = "weapon_customization",

	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},

	ingredientTemplateNames = {"craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n"},
	ingredientTitleNames = {"frame_assembly", "receiver_assembly", "grip_assembly", "powerhandler", "barrel", "power_supply", "scope"},
	ingredientSlotType = {0, 0, 0, 1, 1, 1, 3},
	resourceTypes = {"aluminum_chromium", "copper_mythra", "aluminum_chromium", "object/tangible/component/weapon/shared_blaster_power_handler.iff", "object/tangible/component/weapon/shared_blaster_pistol_barrel.iff", "object/tangible/component/weapon/shared_geonosian_power_cube_base.iff", "object/tangible/component/weapon/shared_scope_weapon.iff"},
	resourceQuantities = {150, 65, 32, 4, 1, 1, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100},

	targetTemplate = "object/weapon/ranged/pistol/pistol_mando_way_geo_blaster.iff",

	additionalTemplates = {
	}
}
ObjectTemplates:addTemplate(object_draft_schematic_weapon_pistol_mando_way_geo_blaster, "object/draft_schematic/weapon/pistol_mando_way_geo_blaster.iff")
