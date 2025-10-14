object_draft_schematic_clothing_clothing_armor_marine_boots = object_draft_schematic_clothing_shared_clothing_armor_marine_boots:new {

   templateType = DRAFTSCHEMATIC,

   customObjectName = "Marine Armor Boots",

   craftingToolTab = 2, -- (See DraftSchematicObjectTemplate.h)
   complexity = 35, 
   size = 1, 
   factoryCrateType = "object/factory/factory_crate_clothing.iff",

   xpType = "crafting_clothing_armor", 
   xp = 270, 

   assemblySkill = "armor_assembly", 
   experimentingSkill = "armor_experimentation", 
   customizationSkill = "armor_customization", 

   customizationOptions = {34, 2},
   customizationStringNames = {"/private/index_color_0", "/private/index_color_1"},
   customizationDefaults = {0, 0},

   ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
   ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
   ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
   resourceTypes = {"iron", "steel", "hide_leathery", "steel_neutronium", "petrochem_inert_polymer", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_ubese.iff", "object/tangible/component/clothing/shared_fiberplast_panel.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
   resourceQuantities = {50, 50, 25, 30, 20, 20, 2, 1, 1},
   contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},


   targetTemplate = "object/tangible/wearables/armor/marine/armor_marine_boots.iff",

   additionalTemplates = {
             }

}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_armor_marine_boots, "object/draft_schematic/clothing/clothing_armor_marine_boots.iff")