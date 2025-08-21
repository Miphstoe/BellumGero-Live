object_draft_schematic_clothing_clothing_dress_nightsister = object_draft_schematic_clothing_shared_clothing_dress_nightsister:new {

   templateType = DRAFTSCHEMATIC,

   customObjectName = "Nightsister Vibrant Dread Shroud",

   craftingToolTab = 8, -- (See DraftSchematicObjectTemplate.h)
   complexity = 15, 
   size = 1, 
   factoryCrateType = "object/factory/factory_crate_clothing.iff",

   xpType = "crafting_clothing_general", 
   xp = 100, 

   assemblySkill = "clothing_assembly", 
   experimentingSkill = "clothing_experimentation", 
   customizationSkill = "clothing_customization", 

   customizationOptions = {2, 1},
   customizationStringNames = {"/private/index_color_1", "/private/index_color_2"},
   customizationDefaults = {7, 42},

   ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
   ingredientTitleNames = {"trim_and_binding", "extra_trim", "hardware", "skirt", "bodice"},
   ingredientSlotType = {0, 1, 0, 1, 1},
   resourceTypes = {"hide", "object/tangible/component/clothing/shared_trim.iff", "metal", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff"},
   resourceQuantities = {20, 1, 20, 1, 1},
   contribution = {100, 100, 100, 100, 100},


   targetTemplate = "object/tangible/wearables/dress/nightsister_dress.iff",

   additionalTemplates = {
             }

}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_dress_nightsister, "object/draft_schematic/clothing/clothing_dress_nightsister.iff")