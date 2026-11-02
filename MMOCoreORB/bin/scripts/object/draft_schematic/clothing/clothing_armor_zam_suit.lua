-- Bellum Gero Mabari Armorweave Suit full-suit; totals derived from 6 existing armor recipes.
object_draft_schematic_clothing_clothing_armor_zam_suit = object_draft_schematic_clothing_shared_clothing_armor_zam_suit:new {
 templateType = DRAFTSCHEMATIC,
 customObjectName = "Mabari Armorweave Suit Package",
 craftingToolTab = 2, complexity = 45, size = 1,
 factoryCrateSize = 1000, factoryCrateType = "object/factory/factory_crate_clothing.iff",
 xpType = "crafting_clothing_armor", xp = 1200,
 assemblySkill = "armor_assembly", experimentingSkill = "armor_experimentation", customizationSkill = "armor_customization",
 customizationOptions = {}, customizationStringNames = {}, customizationDefaults = {},
 ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
 ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
 ingredientSlotType = {0, 0, 0, 0, 0, 0, 2, 1, 1},
 resourceTypes = {"metal", "hide", "fiberplast", "metal", "petrochem_inert", "fiberplast", "object/tangible/component/armor/shared_armor_segment_zam.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_fiberplast_panel.iff"},
 resourceQuantities = {325, 325, 165, 185, 143, 132, 13, 7, 6}, contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
 targetTemplate = "object/tangible/wearables/armor/zam/armor_zam_suit_package.iff", additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_armor_zam_suit, "object/draft_schematic/clothing/clothing_armor_zam_suit.iff")
