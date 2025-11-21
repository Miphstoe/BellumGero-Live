object_draft_schematic_weapon_sword_wookiee = object_draft_schematic_weapon_shared_sword_wookiee:new {

   templateType = DRAFTSCHEMATIC,

   customObjectName = "Blade of Nyenthi'Oris",

   craftingToolTab = 1, -- (See DraftSchematicObjectTemplate.h)
   complexity = 15, 
   size = 1, 
   factoryCrateType = "object/factory/factory_crate_weapon.iff",
   
   xpType = "crafting_weapons_general", 
   xp = 45, 

   assemblySkill = "weapon_assembly", 
   experimentingSkill = "weapon_experimentation", 
   customizationSkill = "weapon_customization", 

   customizationOptions = {},
   customizationStringNames = {},
   customizationDefaults = {},

   ingredientTemplateNames = {"craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n"},
   ingredientTitleNames = {"sword_core_jacket", "grip", "jacketed_sword_core"},
   ingredientSlotType = {0, 0, 1},
   resourceTypes = {"iron_kammris", "petrochem_inert", "object/tangible/component/weapon/shared_sword_core.iff"},
   resourceQuantities = {75, 40, 1},
   contribution = {100, 100, 100},


   targetTemplate = "object/weapon/melee/sword/sword_wookiee.iff",

   additionalTemplates = {
             }

}
ObjectTemplates:addTemplate(object_draft_schematic_weapon_sword_wookiee, "object/draft_schematic/weapon/sword_wookiee.iff")