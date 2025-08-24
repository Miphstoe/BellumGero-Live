object_draft_schematic_clothing_clothing_boots_nightsister = object_draft_schematic_clothing_shared_clothing_boots_nightsister:new {

   templateType = DRAFTSCHEMATIC,

   customObjectName = "Nightsister Boots",

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
   ingredientTitleNames = {"boots", "binding_and_hardware", "liner", "sole"},
   ingredientSlotType = {0, 1, 0, 1},
   resourceTypes = {"fiberplast", "object/tangible/component/clothing/shared_metal_fasteners.iff", "hide_wooly", "object/tangible/component/clothing/shared_shoe_sole.iff"},
   resourceQuantities = {20, 1, 20, 1},
   contribution = {100, 100, 100, 100},


   targetTemplate = "object/tangible/wearables/boots/nightsister_boots.iff",

   additionalTemplates = {
             }

}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_boots_nightsister, "object/draft_schematic/clothing/clothing_boots_nightsister.iff")