-- Bellum Gero RIS Armor Suit full-suit; totals derived from 9 existing armor recipes.
object_draft_schematic_clothing_clothing_armor_ris_suit = object_draft_schematic_clothing_shared_clothing_armor_ris_suit:new {
 templateType = DRAFTSCHEMATIC,
 customObjectName = "RIS Armor Suit Package",
 craftingToolTab = 2, complexity = 45, size = 1,
 factoryCrateSize = 1000, factoryCrateType = "object/factory/factory_crate_clothing.iff",
 xpType = "crafting_clothing_armor", xp = 1800,
 assemblySkill = "armor_assembly", experimentingSkill = "armor_experimentation", customizationSkill = "armor_customization",
 customizationOptions = {}, customizationStringNames = {}, customizationDefaults = {},
 ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
 ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
 ingredientSlotType = {0, 0, 0, 0, 0, 0, 2, 1, 2},
 resourceTypes = {"armophous_vendusii", "fuel_petrochem_solid_known", "fiberplast_talus", "aluminum_chromium", "copper_platinite", "hide_wooly_rori", "object/tangible/component/armor/shared_armor_segment_ris.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/armor/shared_scale_giant_dune_kimogila.iff"},
 resourceQuantities = {1550, 825, 700, 560, 440, 330, 9, 9, 9}, contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
 targetTemplate = "object/tangible/wearables/armor/ris/armor_ris_suit_package.iff", additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_armor_ris_suit, "object/draft_schematic/clothing/clothing_armor_ris_suit.iff")
