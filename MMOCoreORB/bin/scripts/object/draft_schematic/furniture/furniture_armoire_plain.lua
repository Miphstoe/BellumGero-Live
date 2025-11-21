object_draft_schematic_furniture_furniture_armoire_plain = object_draft_schematic_furniture_shared_furniture_armoire_plain:new {

	templateType = DRAFTSCHEMATIC,

	customObjectName = "Armoire",

	craftingToolTab = 512, -- (See DraftSchematicObjectTemplate.h)
	complexity = 15,
	size = 2,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_furniture.iff",
   
	xpType = "crafting_structure_general",
	xp = 250,

	assemblySkill = "structure_assembly",
	experimentingSkill = "structure_experimentation",
	customizationSkill = "structure_customization",

	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},

	ingredientTemplateNames = {"craft_furniture_ingredients_n", "craft_furniture_ingredients_n"},
	ingredientTitleNames = {"frame", "upholstery"},
	ingredientSlotType = {0, 1},
	resourceTypes = {"steel_duralloy", "object/tangible/component/structure/shared_container_expansion_module.iff"},
	resourceQuantities = {250, 1},
	contribution = {100, 100},

	targetTemplate = "object/tangible/furniture/plain/plain_armoire_s01.iff",

	additionalTemplates = {}
}

ObjectTemplates:addTemplate(object_draft_schematic_furniture_furniture_armoire_plain, "object/draft_schematic/furniture/furniture_armoire_plain.iff")
