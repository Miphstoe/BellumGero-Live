object_draft_schematic_weapon_carbine_mando_way_slugthrower = object_draft_schematic_weapon_shared_carbine_mando_way_slugthrower:new {

	templateType = DRAFTSCHEMATIC,

	customObjectName = "Mandalorian Nym Slugthrower Carbine",

	craftingToolTab = 1,
	complexity = 24,
	size = 1,
	factoryCrateType = "object/factory/factory_crate_weapon.iff",

	xpType = "crafting_weapons_general",
	xp = 165,

	assemblySkill = "weapon_assembly",
	experimentingSkill = "weapon_experimentation",
	customizationSkill = "weapon_customization",

	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},

	ingredientTemplateNames = {"craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n"},
	ingredientTitleNames = {"frame_assembly", "receiver_assembly", "grip_assembly", "powerhandler", "barrel", "scope", "stock"},
	ingredientSlotType = {0, 0, 0, 1, 1, 3, 3},
	resourceTypes = {"iron_kammris", "aluminum_phrik", "metal", "object/tangible/component/weapon/shared_blaster_power_handler.iff", "object/tangible/component/weapon/shared_blaster_rifle_barrel.iff", "object/tangible/component/weapon/shared_scope_weapon.iff", "object/tangible/component/weapon/shared_stock.iff"},
	resourceQuantities = {48, 24, 10, 1, 1, 1, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100},
	ingredientAppearance = {"", "", "", "", "muzzle", "scope", ""},

	targetTemplate = "object/weapon/ranged/carbine/carbine_mando_way_slugthrower.iff",

	additionalTemplates = {
	}
}
ObjectTemplates:addTemplate(object_draft_schematic_weapon_carbine_mando_way_slugthrower, "object/draft_schematic/weapon/carbine_mando_way_slugthrower.iff")
