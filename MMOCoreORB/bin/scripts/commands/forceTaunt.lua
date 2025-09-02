ForceTauntCommand = {
  name = "forcetaunt",

    forceCost = 25,
	forceAttack = true,
	visMod = 25,
  speed = 0.0,               -- instant
  	cooldown = 0.0,            -- short anti-spam

    poolsToDamage = NO_ATTRIBUTE,

    combatSpam = "taunt",
    effectString = "clienteffect/combat_special_attacker_taunt.cef",

    range = 64,
}
AddCommand(ForceTauntCommand)