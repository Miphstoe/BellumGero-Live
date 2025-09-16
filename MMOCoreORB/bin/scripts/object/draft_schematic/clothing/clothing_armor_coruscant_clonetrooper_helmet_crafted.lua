object_draft_schematic_clothing_clothing_armor_coruscant_clonetrooper_helmet_crafted = object_draft_schematic_clothing_shared_clothing_armor_coruscant_clonetrooper_helmet_crafted:new {

   templateType = DRAFTSCHEMATIC,

   customObjectName = "Coruscant Clone Trooper Armor Helmet",

   craftingToolTab = 2, -- (See DraftSchematicObjectTemplate.h)
   complexity = 45, 
   size = 1, 
   factoryCrateType = "object/factory/factory_crate_clothing.iff",

   xpType = "crafting_clothing_armor", 
   xp = 550, 

   assemblySkill = "armor_assembly", 
   experimentingSkill = "armor_experimentation", 
   customizationSkill = "armor_customization", 

   customizationOptions = {},
   customizationStringNames = {},
   customizationDefaults = {},

   ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
   ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
   ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
   resourceTypes = {"ore_intrusive", "fuel_petrochem_solid_known", "fiberplast_gravitonic", "aluminum", "iron_kammris", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_composite.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
   resourceQuantities = {70, 70, 35, 40, 30, 30, 3, 1, 1},
   contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},


   targetTemplate = "object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_rebel_s01_helmet.iff",

   additionalTemplates = {
             }

}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_armor_coruscant_clonetrooper_helmet_crafted, "object/draft_schematic/clothing/clothing_armor_coruscant_clonetrooper_helmet_crafted.iff")