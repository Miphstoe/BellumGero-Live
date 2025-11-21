gcw_cave_rebel_officer = Creature:new {
  objectName = "@mob/creature_names:rebel_commando",
  customName = "Rebel Liaison",
  socialGroup = "rebel",
  faction = "rebel",
  level = 90,
  chanceHit = 0.5,
  damageMin = 200,
  damageMax = 250,
  baseXp = 0,
  baseHAM = 5000,
  baseHAMmax = 7000,
  armor = 1,
  templates = { "object/mobile/dressed_rebel_commando_human_male_01.iff" },
  conversationTemplate = "gcwCaveDailyConvoTemplate",
  optionsBitmask = INVULNERABLE + CONVERSABLE,
  pvpBitmask = NONE,
  creatureBitmask = NONE,
  diet = HERBIVORE
}
CreatureTemplates:addCreatureTemplate(gcw_cave_rebel_officer, "gcw_cave_rebel_officer")