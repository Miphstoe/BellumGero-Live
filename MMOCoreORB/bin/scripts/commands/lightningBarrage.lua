-- Bounty Hunter Ultimate: Lightning Barrage

LightningBarrageCommand = {
    name = "lightningbarrage",

    -- Tunables (start conservative; adjust later)
    damageMultiplier = 6.0,
    speedMultiplier  = 2.0,
    healthCostMultiplier = 0.5,
    actionCostMultiplier = 0.5,
    mindCostMultiplier   = 2.0,
    accuracyBonus = 50,

    -- Cone-style ultimate, similar to other Reaper abilities
    coneAngle = 60,
    coneAction = true,

    poolsToDamage = RANDOM_ATTRIBUTE,

    stateEffects = {
      StateEffect(
        BLIND_EFFECT,
        {},
        { "blind_defense" },
        { "jedi_state_defense", "resistance_states" },
        65,
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
        65,
        0,
        30
      ),
    },

    animation = "fire_area",
    animType  = GENERATE_INTENSITY,

    combatSpam = "lightningbarrage",

    -- Must be used with Lightning Cannon / Lightning Rifle heavy weapons
    weaponType = SPECIALHEAVYWEAPON,
    range = -1 -- use weapon range
}

AddCommand(LightningBarrageCommand)
