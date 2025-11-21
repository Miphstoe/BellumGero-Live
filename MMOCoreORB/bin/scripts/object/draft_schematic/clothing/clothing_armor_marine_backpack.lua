object_draft_schematic_clothing_clothing_armor_marine_backpack = object_draft_schematic_clothing_shared_clothing_armor_marine_backpack:new {
	templateType = DRAFTSCHEMATIC,

	customObjectName = "Marine Armor Backpack",

	craftingToolTab = 2, -- (See DraftSchematicObjectTemplate.h)
	complexity = 35,
	size = 1,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",

	xpType = "crafting_clothing_armor",
	xp = 40,

	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",

	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},

	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage", "body", "liner"},
	ingredientSlotType = {0, 0, 1},
	resourceTypes = {"iron", "steel", "object/tangible/component/clothing/shared_fiberplast_panel.iff"},
	resourceQuantities = {15, 5, 1},
	contribution = {100, 100, 100},


	targetTemplate = "object/tangible/wearables/armor/marine/armor_marine_backpack.iff",

	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_armor_marine_backpack, "object/draft_schematic/clothing/clothing_armor_marine_backpack.iff")