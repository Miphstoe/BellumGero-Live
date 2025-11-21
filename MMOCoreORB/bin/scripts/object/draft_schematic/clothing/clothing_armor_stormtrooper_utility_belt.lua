object_draft_schematic_clothing_clothing_armor_stormtrooper_utility_belt = object_draft_schematic_clothing_shared_clothing_armor_stormtrooper_utility_belt:new {

   templateType = DRAFTSCHEMATIC,

   customObjectName = "Stormtrooper Armor Utility Belt",

   craftingToolTab = 2, -- (See DraftSchematicObjectTemplate.h)
   complexity = 15, 
   size = 1, 
   factoryCrateType = "object/factory/factory_crate_clothing.iff",

   xpType = "crafting_clothing_armor", 
   xp = 80, 

   assemblySkill = "armor_assembly", 
   experimentingSkill = "armor_experimentation", 
   customizationSkill = "armor_customization", 

   customizationOptions = {},
   customizationStringNames = {},
   customizationDefaults = {},

   ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
   ingredientTitleNames = {"shell", "binding_and_reinforcement", "hardware"},
   ingredientSlotType = {0, 0, 1},
   resourceTypes = {"iron_kammris", "hide_wooly", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
   resourceQuantities = {5, 5, 1},
   contribution = {100, 100, 100},


   targetTemplate = "object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_utility_belt.iff",

   additionalTemplates = {
             }

}

ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_armor_stormtrooper_utility_belt, "object/draft_schematic/clothing/clothing_armor_stormtrooper_utility_belt.iff")