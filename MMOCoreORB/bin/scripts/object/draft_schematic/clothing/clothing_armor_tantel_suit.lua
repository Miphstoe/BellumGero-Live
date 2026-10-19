-- Bellum Gero Tantel Armor Suit full-suit; totals derived from 3 existing armor recipes.
object_draft_schematic_clothing_clothing_armor_tantel_suit = object_draft_schematic_clothing_shared_clothing_armor_tantel_suit:new {
 templateType = DRAFTSCHEMATIC,
 customObjectName = "Tantel Armor Suit Package",
 craftingToolTab = 2, complexity = 45, size = 1,
 factoryCrateSize = 1000, factoryCrateType = "object/factory/factory_crate_clothing.iff",
 xpType = "crafting_clothing_armor", xp = 600,
 assemblySkill = "armor_assembly", experimentingSkill = "armor_experimentation", customizationSkill = "armor_customization",
 customizationOptions = {}, customizationStringNames = {}, customizationDefaults = {},
 ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
 ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
 ingredientSlotType = {0, 0, 0, 0, 0, 0, 2, 1, 1},
 resourceTypes = {"bone_avian", "hide", "hide_bristley", "aluminum", "petrochem_inert_polymer", "hide_bristley", "object/tangible/component/armor/shared_armor_segment.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
 resourceQuantities = {90, 90, 90, 50, 50, 50, 9, 3, 3}, contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
 targetTemplate = "object/tangible/wearables/armor/tantel/armor_tantel_suit_package.iff", additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_armor_tantel_suit, "object/draft_schematic/clothing/clothing_armor_tantel_suit.iff")
