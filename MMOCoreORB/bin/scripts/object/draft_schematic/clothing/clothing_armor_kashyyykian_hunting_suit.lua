-- Bellum Gero Kashyyykian Hunting Armor Full-Suit Crafting
-- Recipe totals are derived from the current individual suit schematics.

object_draft_schematic_clothing_clothing_armor_kashyyykian_hunting_suit =
	object_draft_schematic_clothing_shared_clothing_armor_kashyyykian_hunting_suit:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Kashyyykian Hunting Armor Suit Package",
	craftingToolTab = 2,
	complexity = 45,
	size = 1,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 2040,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage","body","liner","hardware_and_attachments","binding_and_reinforcement","padding","armor","load_bearing_harness","reinforcement","bone_decoration"},
	ingredientSlotType = {0,0,0,0,0,1,1,1,0,0},
	resourceTypes = {"softwood_evergreen_dathomir","hide_leathery_lok","hide_wooly_tatooine","copper_mythra","petrochem_inert_polymer","object/tangible/component/clothing/shared_padding_segment.iff","object/tangible/component/armor/shared_armor_segment_kashyyykian_hunting.iff","object/tangible/component/clothing/shared_synthetic_cloth.iff","fiberplast_naboo","bone_mammal_dantooine"},
	resourceQuantities = {270,270,180,130,110,14,11,4,115,40},
	contribution = {100,100,100,100,100,100,100,100,100,100},
	targetTemplate = "object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_suit_package.iff",
	additionalTemplates = {}
}

ObjectTemplates:addTemplate(
	object_draft_schematic_clothing_clothing_armor_kashyyykian_hunting_suit,
	"object/draft_schematic/clothing/clothing_armor_kashyyykian_hunting_suit.iff")
