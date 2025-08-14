object_draft_schematic_clothing_clothing_armor_clonetrooper_bicep_r_crafted = object_draft_schematic_clothing_shared_clothing_armor_clonetrooper_bicep_r_crafted:new {

   templateType = DRAFTSCHEMATIC,

   customObjectName = "Clone Trooper Armor Right Bicep",

   craftingToolTab = 2, -- (See DraftSchematicObjectTemplate.h)
   complexity = 45, 
   size = 1, 
   factoryCrateType = "object/factory/factory_crate_clothing.iff",

   xpType = "crafting_clothing_armor", 
   xp = 420, 

   assemblySkill = "armor_assembly", 
   experimentingSkill = "armor_experimentation", 
   customizationSkill = "armor_customization", 

   customizationOptions = {},
   customizationStringNames = {},
   customizationDefaults = {},

   ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
   ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
   ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
   resourceTypes = {"ore_intrusive", "fuel_petrochem_solid_known", "fiberplast_naboo", "aluminum", "copper_beyrllius", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_composite.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
   resourceQuantities = {50, 50, 25, 30, 20, 20, 2, 1, 1},
   contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},


   targetTemplate = "object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_neutral_s01_bicep_r.iff",

   additionalTemplates = {
             }

}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_armor_clonetrooper_bicep_r_crafted, "object/draft_schematic/clothing/clothing_armor_clonetrooper_bicep_r_crafted.iff")