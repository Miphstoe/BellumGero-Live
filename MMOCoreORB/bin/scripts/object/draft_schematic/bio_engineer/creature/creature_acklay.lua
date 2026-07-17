object_draft_schematic_bio_engineer_creature_creature_acklay = object_draft_schematic_bio_engineer_creature_shared_creature_acklay:new {

	templateType = DRAFTSCHEMATIC,
	lab = BIO_CREATURE_LAB,
	factoryCrateSize = 0,

	customObjectName = "Acklay",

	craftingToolTab = 256,
	complexity = 30,
	size = 1,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",

	xpType = "crafting_bio_engineer_creature",
	xp = 290,

	assemblySkill = "bio_engineer_assembly",
	experimentingSkill = "bio_engineer_experimentation",
	customizationSkill = "bio_engineer_experimentation",

	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},

	ingredientTemplateNames = {"craft_creature_ingredients_n", "craft_creature_ingredients_n", "craft_creature_ingredients_n"},
	ingredientTitleNames = {"dna_template", "protein_base", "organic_nutrition_materials"},
	ingredientSlotType = {1, 0, 0},
	resourceTypes = {"object/tangible/component/dna/shared_dna_template_generic.iff", "creature_food", "flora_food"},
	resourceQuantities = {1, 80, 70},
	contribution = {100, 100, 100},

	targetTemplate = "object/tangible/deed/pet_deed/acklay_deed.iff",
	additionalTemplates = {}
}

ObjectTemplates:addTemplate(object_draft_schematic_bio_engineer_creature_creature_acklay, "object/draft_schematic/bio_engineer/creature/creature_acklay.iff")
