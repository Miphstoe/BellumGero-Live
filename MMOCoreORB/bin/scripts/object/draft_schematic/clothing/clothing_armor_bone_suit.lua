-- Bellum Gero Bone Armor Full-Suit Crafting
-- Recipe totals are derived from the current individual suit schematics.

object_draft_schematic_clothing_clothing_armor_bone_suit =
	object_draft_schematic_clothing_shared_clothing_armor_bone_suit:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Bone Armor Suit Package",
	craftingToolTab = 2,
	complexity = 17,
	size = 1,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_general",
	xp = 1746,
	assemblySkill = "general_assembly",
	experimentingSkill = "general_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n","craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage","body","hardware_and_attachments","binding_and_reinforcement","armor","load_bearing_harness"},
	ingredientSlotType = {0,0,0,0,1,1},
	resourceTypes = {"bone","hide","metal","petrochem_inert","object/tangible/component/armor/shared_armor_segment_bone.iff","object/tangible/component/clothing/shared_fiberplast_panel.iff"},
	resourceQuantities = {515,985,300,220,21,19},
	contribution = {100,100,100,100,100,100},
	targetTemplate = "object/tangible/wearables/armor/bone/armor_bone_suit_package.iff",
	additionalTemplates = {}
}

ObjectTemplates:addTemplate(
	object_draft_schematic_clothing_clothing_armor_bone_suit,
	"object/draft_schematic/clothing/clothing_armor_bone_suit.iff")
