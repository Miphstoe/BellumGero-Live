object_draft_schematic_vehicle_civilian_sith_speeder = object_draft_schematic_vehicle_civilian_shared_sith_speeder:new {

	templateType = DRAFTSCHEMATIC,

	customObjectName = "Sith Speeder",

	craftingToolTab = 16, -- (See DraftSchematicObjectTemplate.h)
	complexity = 25,
	size = 1,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_installation.iff",
   
	xpType = "crafting_general",
	xp = 1800,

	assemblySkill = "general_assembly",
	experimentingSkill = "general_experimentation",
	customizationSkill = "clothing_customization",

	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},

	ingredientTemplateNames = {"craft_vehicle_ingredients_n", "craft_vehicle_ingredients_n"},
	ingredientTitleNames = {"vehicle_body", "structural_frame"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"metal_nonferrous", "metal_ferrous"},
	resourceQuantities = {1500, 3500},
	contribution = {100, 100},

	targetTemplate = "object/tangible/deed/vehicle_deed/vehicle_deed_sith_speeder.iff",

	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_vehicle_civilian_sith_speeder, "object/draft_schematic/vehicle/civilian/sith_speeder.iff")
