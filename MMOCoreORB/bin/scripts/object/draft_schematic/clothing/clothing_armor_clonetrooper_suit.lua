-- Bellum Gero Phase II Clone Trooper Armor Full-Suit Crafting
object_draft_schematic_clothing_clothing_armor_clonetrooper_suit =
	object_draft_schematic_clothing_shared_clothing_armor_clonetrooper_suit:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Phase II Clone Trooper Armor Suit Package",
	craftingToolTab = 2, complexity = 45, size = 1,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor", xp = 4180,
	assemblySkill = "armor_assembly", experimentingSkill = "armor_experimentation", customizationSkill = "armor_customization",
	customizationOptions = {}, customizationStringNames = {}, customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage","body","liner","hardware_and_attachments","binding_and_reinforcement","padding","armor","load_bearing_harness","reinforcement"},
	ingredientSlotType = {0,0,0,0,0,0,1,1,1},
	resourceTypes = {"ore_intrusive","fuel_petrochem_solid_known","fiberplast_gravitonic","aluminum","iron_kammris","hide_wooly","object/tangible/component/armor/shared_armor_segment_composite.iff","object/tangible/component/clothing/shared_synthetic_cloth.iff","object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {515,515,260,300,225,215,21,10,10},
	contribution = {100,100,100,100,100,100,100,100,100},
	targetTemplate = "object/tangible/wearables/armor/clone_trooper/armor_clonetrooper_suit_package.iff", additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_armor_clonetrooper_suit, "object/draft_schematic/clothing/clothing_armor_clonetrooper_suit.iff")
