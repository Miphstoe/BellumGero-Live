object_tangible_scout_trap_trap_noise_maker = object_tangible_scout_trap_shared_trap_noise_maker:new {
  templateType = TRAP,
  objectMenuComponent = "TrapMenuComponent",

  useCount = 8,
  skillRequired = 15,

  healthCost = 17,
  actionCost = 30,
  mindCost = 17,

  maxRange = 32,            -- throw/placement range
  areaOfEffect = true,      -- flip this to true
  aoeRadius = 16,           -- add if your core supports it (common in some forks)
  aoeMaxTargets = 12,       -- optional safety cap (if supported)

  poolToDamage = MIND,
  minDamage = 80,
  maxDamage = 120,

  duration = 10,
  state = STUNNED,
  defenseMod = "stun_defense",

  successMessage = "trap_noise_maker_effect",
  failMessage = "trap_noise_maker_effect_no",

  animation = "throw_trap_noise_maker",

  numberExperimentalProperties = {1,1,1,1},
  experimentalProperties = {"XX","XX","XX","XX"},
  experimentalWeights = {1,1,1,1},
  experimentalGroupTitles = {"null","null","null","null"},
  experimentalSubGroupTitles = {"null","null","hitpoints","quality"},
  experimentalMin = {0,0,1000,1},
  experimentalMax = {0,0,1000,100},
  experimentalPrecision = {0,0,0,0},
  experimentalCombineType = {0,0,4,1},
}
ObjectTemplates:addTemplate(object_tangible_scout_trap_trap_noise_maker, "object/tangible/scout/trap/trap_noise_maker.iff")