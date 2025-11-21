gcw_cave_imperial_officer = Creature:new {
  objectName = "@mob/creature_names:imperial_commander",
  customName = "Imperial Liaison",
  socialGroup = "imperial",
  faction = "imperial",
  level = 90,
  chanceHit = 0.5,
  damageMin = 200,
  damageMax = 250,
  baseXp = 0,
  baseHAM = 5000,
  baseHAMmax = 7000,
  armor = 1,
  templates = { "object/mobile/dressed_imperial_commander_m.iff" },
  conversationTemplate = "gcwCaveDailyConvoTemplate",
  optionsBitmask = INVULNERABLE + CONVERSABLE,  -- 264 works too; this is clearer
  pvpBitmask = NONE,
  creatureBitmask = NONE,
  diet = HERBIVORE
}
CreatureTemplates:addCreatureTemplate(gcw_cave_imperial_officer, "gcw_cave_imperial_officer")