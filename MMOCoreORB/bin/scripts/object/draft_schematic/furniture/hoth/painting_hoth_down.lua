object_draft_schematic_furniture_hoth_painting_hoth_down = object_draft_schematic_furniture_hoth_shared_painting_hoth_down:new {
	templateType = DRAFTSCHEMATIC,

	customObjectName = "Painting: Down for the Count",

	craftingToolTab = 512, -- (See DraftSchematicObjectTemplate.h)
	complexity = 15,
	size = 2,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_furniture.iff",
   
	xpType = "crafting_structure_general",
	xp = 80,

	assemblySkill = "structure_assembly",
	experimentingSkill = "structure_experimentation",
	customizationSkill = "structure_customization",

	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},

	ingredientTemplateNames = {"craft_furniture_ingredients_n", "craft_furniture_ingredients_n", "craft_furniture_ingredients_n"},
	ingredientTitleNames = {"frame", "canvas", "paints"},
	ingredientSlotType = {0, 0, 0},
	resourceTypes = {"metal", "hide", "petrochem_inert_polymer"},
	resourceQuantities = {50, 50, 40},
	contribution = {100, 100, 100},

	targetTemplate = "object/tangible/painting/battlehoth_01_f05_000000000000.iff",

	additionalTemplates = {}
}

ObjectTemplates:addTemplate(object_draft_schematic_furniture_hoth_painting_hoth_down, "object/draft_schematic/furniture/hoth/painting_hoth_down.iff")
