Taunt2Command = {
  name = "taunt2",
  combatSpam = "taunt",
  effectString = "clienteffect/combat_special_attacker_taunt.cef",
  poolsToDamage = NO_ATTRIBUTE,

  -- AoE like Intimidate2
  areaAction = true,
  areaRange  = 25,

  range = 64
}
AddCommand(Taunt2Command)