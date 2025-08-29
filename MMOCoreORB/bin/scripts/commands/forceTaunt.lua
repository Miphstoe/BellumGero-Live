ForceTauntCommand = {
  name = "forcetaunt",

    forceCost = 25,
	forceAttack = true,
	visMod = 25,

    poolsToDamage = NO_ATTRIBUTE,

    combatSpam = "taunt",
    effectString = "clienteffect/combat_special_attacker_taunt.cef",

    range = 64,
}
AddCommand(ForceTauntCommand)