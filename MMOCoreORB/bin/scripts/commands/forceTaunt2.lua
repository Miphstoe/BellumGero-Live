ForceTaunt2Command = {
  name = "forceTaunt2",

    forceCost = 50,
	forceAttack = true,
	splashDamage = true,
	areaAction = true,
	areaRange = 32,
	visMod = 25,

    poolsToDamage = NO_ATTRIBUTE,

    combatSpam = "taunt",
    effectString = "clienteffect/combat_special_attacker_taunt.cef",

    range = 64,
}
AddCommand(ForceTaunt2Command)