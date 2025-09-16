object_draft_schematic_furniture_furniture_plants_potted_small_s02 = object_draft_schematic_furniture_shared_furniture_plants_potted_small_s02:new {

	templateType = DRAFTSCHEMATIC,

	customObjectName = "Small Potted Plant, Style Two",

	craftingToolTab = 512, -- (See DraftSchematicObjectTemplate.h)
	complexity = 15,
	size = 2,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_furniture.iff",
   
	xpType = "crafting_structure_general",
	xp = 110,

	assemblySkill = "structure_assembly",
	experimentingSkill = "structure_experimentation",
	customizationSkill = "structure_customization",

	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},

	ingredientTemplateNames = {"craft_furniture_ingredients_n", "craft_furniture_ingredients_n", "craft_furniture_ingredients_n"},
	ingredientTitleNames = {"pot", "tree", "greenery"},
	ingredientSlotType = {0, 0, 0},
	resourceTypes = {"mineral", "wood", "chemical"},
	resourceQuantities = {25, 20, 20},
	contribution = {100, 100, 100},

	targetTemplate = "object/tangible/furniture/all/frn_all_potted_plants_sml_s02.iff",

	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_furniture_furniture_plants_potted_small_s02, "object/draft_schematic/furniture/furniture_plants_potted_small_s02.iff")