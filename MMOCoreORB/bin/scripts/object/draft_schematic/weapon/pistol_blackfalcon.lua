object_draft_schematic_weapon_pistol_blackfalcon = object_draft_schematic_weapon_shared_pistol_blackfalcon:new {

   templateType = DRAFTSCHEMATIC,

   customObjectName = "Black Falcon Pistol",

   craftingToolTab = 1, -- (See DraftSchematicObjectTemplate.h)
   complexity = 30, 
   size = 1, 
   factoryCrateType = "object/factory/factory_crate_weapon.iff",
   
   xpType = "crafting_weapons_general", 
   xp = 650, 

   assemblySkill = "weapon_assembly", 
   experimentingSkill = "weapon_experimentation", 
   customizationSkill = "weapon_customization", 

   customizationOptions = {},
   customizationStringNames = {},
   customizationDefaults = {},

   ingredientTemplateNames = {"craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n"},
   ingredientTitleNames = {"frame_assembly", "receiver_assembly", "grip_assembly", "enhanced_cooling_mechanism", "powerhandler", "thermal_control_unit", "barrel"},
   ingredientSlotType = {0, 0, 0, 0, 1, 0, 1},
   resourceTypes = {"copper_mythra", "iron_kammris", "metal", "aluminum_phrik", "object/tangible/component/weapon/shared_blaster_power_handler.iff", "ore_carbonate_alantium", "object/tangible/component/weapon/shared_blaster_pistol_barrel.iff"},
   resourceQuantities = {250, 115, 20, 15, 10, 30, 1},
   contribution = {100, 100, 100, 100, 100, 100, 100},
   ingredientAppearance = {"", "", "", "", "", "", "muzzle"},


   targetTemplate = "object/weapon/ranged/pistol/pistol_blackfalcon.iff",

   additionalTemplates = {
             }

}
ObjectTemplates:addTemplate(object_draft_schematic_weapon_pistol_blackfalcon, "object/draft_schematic/weapon/pistol_blackfalcon.iff")
