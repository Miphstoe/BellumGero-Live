-- Bellum Gero Ithorian Defender Armor Full-Suit Crafting
-- Recipe totals are derived from the current individual suit schematics.

object_draft_schematic_clothing_clothing_armor_ithorian_defender_suit =
	object_draft_schematic_clothing_shared_clothing_armor_ithorian_defender_suit:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Ithorian Defender Armor Suit Package",
	craftingToolTab = 2,
	complexity = 40,
	size = 1,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 3660,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage","body","liner","hardware_and_attachments","binding_and_reinforcement","padding","armor","load_bearing_harness","reinforcement"},
	ingredientSlotType = {0,0,0,0,0,0,1,1,1},
	resourceTypes = {"hide_leathery_lok","hide_scaley","fiberplast_corellia","metal","petrochem_inert_polymer","hide_wooly","object/tangible/component/armor/shared_armor_segment_padded.iff","object/tangible/component/clothing/shared_synthetic_cloth.iff","object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {515,515,260,300,220,210,21,10,9},
	contribution = {100,100,100,100,100,100,100,100,100},
	targetTemplate = "object/tangible/wearables/armor/ithorian_defender/armor_ithorian_defender_suit_package.iff",
	additionalTemplates = {}
}

ObjectTemplates:addTemplate(
	object_draft_schematic_clothing_clothing_armor_ithorian_defender_suit,
	"object/draft_schematic/clothing/clothing_armor_ithorian_defender_suit.iff")
