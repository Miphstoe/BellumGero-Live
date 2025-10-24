-- Carbineer Ultimate: Reaper Blast

ReaperBlastCommand = {
    name = "reaperblast",

    damageMultiplier = 5.0,
    speedMultiplier  = 2.0,
    healthCostMultiplier = 0.5,
    actionCostMultiplier = 0.5,
    mindCostMultiplier   = 2.0,
    accuracyBonus = 50,
    coneAngle = 60,
	coneAction = true,

    poolsToDamage = RANDOM_ATTRIBUTE,

    stateEffects = {
      StateEffect( 
		BLIND_EFFECT, 
		{}, 
		{ "blind_defense" }, 
		{ "jedi_state_defense", "resistance_states" },
		40, 
		0, 
		30 
	  ),
	  StateEffect( 
		STUN_EFFECT, 
		{}, 
		{ "stun_defense" }, 
		{ "jedi_state_defense", "resistance_states" },
		75, 
		0, 
		45 
	  ),
	  StateEffect( 
		DIZZY_EFFECT, 
		{}, 
		{ "dizzy_defense" }, 
		{ "jedi_state_defense", "resistance_states" },
		50, 
		0, 
		30 
	  ),
    },

    animation = "fire_area",
    animType  = GENERATE_INTENSITY,

    combatSpam = "reaper_blast",

    weaponType = CARBINEWEAPON,
    range = -1
}

AddCommand(ReaperBlastCommand)