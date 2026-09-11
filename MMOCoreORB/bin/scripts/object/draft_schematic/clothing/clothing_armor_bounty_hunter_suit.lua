-- Bellum Gero Bounty Hunter Armor Full-Suit Crafting
object_draft_schematic_clothing_clothing_armor_bounty_hunter_suit = object_draft_schematic_clothing_shared_clothing_armor_bounty_hunter_suit:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Bounty Hunter Armor Suit Package",
	craftingToolTab = 2, complexity = 15, size = 1,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor", xp = 4180,
	assemblySkill = "armor_assembly", experimentingSkill = "armor_experimentation", customizationSkill = "armor_customization",
	customizationOptions = {}, customizationStringNames = {}, customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n"},
	ingredientTitleNames = {"shell","binding_and_reinforcement","hardware","auxilary_coverage","body","liner","hardware_and_attachments","auxilary_coverage_2","armor","load_bearing_harness"},
	ingredientSlotType = {0,0,1,0,0,0,0,0,1,1},
	resourceTypes = {"copper_beyrllius","hide_wooly","object/tangible/component/clothing/shared_reinforced_fiber_panels.iff","ore_intrusive","fuel_petrochem_solid_known","fiberplast_naboo","aluminum","steel","object/tangible/component/armor/shared_armor_segment_composite.iff","object/tangible/component/clothing/shared_synthetic_cloth.iff"},
	resourceQuantities = {225,215,10,515,515,260,300,210,21,10},
	contribution = {100,100,100,100,100,100,100,100,100,100},
	targetTemplate = "object/tangible/wearables/armor/bounty_hunter/armor_bounty_hunter_suit_package.iff", additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_armor_bounty_hunter_suit, "object/draft_schematic/clothing/clothing_armor_bounty_hunter_suit.iff")
