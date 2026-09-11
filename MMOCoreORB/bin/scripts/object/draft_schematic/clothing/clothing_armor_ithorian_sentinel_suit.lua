-- Bellum Gero Ithorian Sentinel Armor Full-Suit Crafting
-- Recipe totals are derived from the current individual suit schematics.

object_draft_schematic_clothing_clothing_armor_ithorian_sentinel_suit =
	object_draft_schematic_clothing_shared_clothing_armor_ithorian_sentinel_suit:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Ithorian Sentinel Armor Suit Package",
	craftingToolTab = 2,
	complexity = 45,
	size = 1,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 4100,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage","body","liner","hardware_and_attachments","binding_and_reinforcement","padding","armor","load_bearing_harness","reinforcement"},
	ingredientSlotType = {0,0,0,0,0,0,1,1,1},
	resourceTypes = {"ore_intrusive","fuel_petrochem_solid_known","fiberplast_naboo","aluminum","copper_beyrllius","hide_wooly","object/tangible/component/armor/shared_armor_segment_composite.iff","object/tangible/component/clothing/shared_synthetic_cloth.iff","object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {515,515,260,300,220,210,21,9,9},
	contribution = {100,100,100,100,100,100,100,100,100},
	targetTemplate = "object/tangible/wearables/armor/ithorian_sentinel/armor_ithorian_sentinel_suit_package.iff",
	additionalTemplates = {}
}

ObjectTemplates:addTemplate(
	object_draft_schematic_clothing_clothing_armor_ithorian_sentinel_suit,
	"object/draft_schematic/clothing/clothing_armor_ithorian_sentinel_suit.iff")
