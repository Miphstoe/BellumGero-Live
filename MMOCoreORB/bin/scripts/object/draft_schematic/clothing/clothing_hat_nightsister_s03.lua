object_draft_schematic_clothing_clothing_hat_nightsister_s03 = object_draft_schematic_clothing_shared_clothing_hat_nightsister_s03:new {

   templateType = DRAFTSCHEMATIC,

   customObjectName = "Nightsister Tarnished Shroud",

   craftingToolTab = 8, -- (See DraftSchematicObjectTemplate.h)
   complexity = 15, 
   size = 1, 
   factoryCrateType = "object/factory/factory_crate_clothing.iff",

   xpType = "crafting_clothing_general", 
   xp = 90, 

   assemblySkill = "clothing_assembly", 
   experimentingSkill = "clothing_experimentation", 
   customizationSkill = "clothing_customization", 

   customizationOptions = {2, 1},
   customizationStringNames = {"/private/index_color_1", "/private/index_color_2"},
   customizationDefaults = {7, 42},

   ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
   ingredientTitleNames = {"shell", "binding_and_weatherproofing", "trim", "liner"},
   ingredientSlotType = {1, 0, 1, 1},
   resourceTypes = {"object/tangible/component/clothing/shared_metal_fasteners.iff", "petrochem_inert", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff", "object/tangible/component/clothing/shared_fiberplast_panel.iff"},
   resourceQuantities = {1, 40, 1, 1},
   contribution = {100, 100, 100, 100},


   targetTemplate = "object/tangible/wearables/hat/nightsister_hat_s03.iff",

   additionalTemplates = {
             }

}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_hat_nightsister_s03, "object/draft_schematic/clothing/clothing_hat_nightsister_s03.iff")