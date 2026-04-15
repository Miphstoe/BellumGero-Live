object_draft_schematic_weapon_rifle_mando_way_lightning = object_draft_schematic_weapon_shared_rifle_mando_way_lightning:new {

	templateType = DRAFTSCHEMATIC,

	customObjectName = "Mandalorian Light Lightning Cannon",

	craftingToolTab = 1,
	complexity = 26,
	size = 1,
	factoryCrateType = "object/factory/factory_crate_weapon.iff",

	xpType = "crafting_weapons_general",
	xp = 400,

	assemblySkill = "weapon_assembly",
	experimentingSkill = "weapon_experimentation",
	customizationSkill = "weapon_customization",

	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},

	ingredientTemplateNames = {"craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n"},
	ingredientTitleNames = {"frame_assembly", "receiver_assembly", "conduction_mass", "pulse_insulator", "shock_buffer", "grip_assembly", "powerhandler", "barrel", "scope", "stock"},
	ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 3, 3},
	resourceTypes = {"steel", "iron", "metal", "copper", "ore_siliclastic", "petrochem_inert_polymer", "object/tangible/component/weapon/shared_blaster_power_handler.iff", "object/tangible/component/weapon/shared_blaster_rifle_barrel.iff", "object/tangible/component/weapon/shared_scope_weapon.iff", "object/tangible/component/weapon/shared_stock.iff"},
	resourceQuantities = {72, 38, 18, 28, 48, 80, 4, 1, 1, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100, 100},

	targetTemplate = "object/weapon/ranged/rifle/rifle_mando_way_lightning.iff",

	additionalTemplates = {
	}
}
ObjectTemplates:addTemplate(object_draft_schematic_weapon_rifle_mando_way_lightning, "object/draft_schematic/weapon/rifle_mando_way_lightning.iff")
