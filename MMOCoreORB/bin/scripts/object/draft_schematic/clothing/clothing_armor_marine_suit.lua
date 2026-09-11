-- Bellum Gero Marine Armor Full-Suit Crafting
object_draft_schematic_clothing_clothing_armor_marine_suit = object_draft_schematic_clothing_shared_clothing_armor_marine_suit:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Marine Armor Suit Package",
	craftingToolTab = 2, complexity = 35, size = 1,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor", xp = 2010,
	assemblySkill = "armor_assembly", experimentingSkill = "armor_experimentation", customizationSkill = "armor_customization",
	customizationOptions = {}, customizationStringNames = {}, customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage","body","liner","hardware_and_attachments","binding_and_reinforcement","padding","armor","load_bearing_harness","reinforcement"},
	ingredientSlotType = {0,0,0,0,0,0,1,1,1},
	resourceTypes = {"iron","steel","hide_leathery","steel_neutronium","petrochem_inert_polymer","hide_wooly","object/tangible/component/armor/shared_armor_segment_ubese.iff","object/tangible/component/clothing/shared_fiberplast_panel.iff","object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {390,390,195,230,170,160,16,6,6},
	contribution = {100,100,100,100,100,100,100,100,100},
	targetTemplate = "object/tangible/wearables/armor/marine/armor_marine_suit_package.iff", additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_armor_marine_suit, "object/draft_schematic/clothing/clothing_armor_marine_suit.iff")
