--Copyright (C) 2010 <SWGEmu>
-- Core3 Powerup: Damage Type - Electricity

object_tangible_powerup_weapon_damage_type_electricity = object_tangible_powerup_weapon_shared_damage_type_electricity:new {

	templateType = POWERUP,

	-- ApplyPowerupCommand checks pup->isAll() => type == "all"
	-- PowerupObjectImplementation sets type = pupTemplate->getType().toLowerCase()
	-- So "All" becomes "all" and matches isAll().
	pupType = "All",

	-- Used for naming: "A <PrimaryName> <baseName>"
	baseName = "Damage Type Powerup",

	-- THIS is what your modified PowerupTemplate reads into damageTypeOverride.
	-- WeaponObjectImplementation applies it when powerup is applied.
	damageType = ELECTRICITY,

	-- Keep a primary entry so the crafted PUP gets named (and isn't blank/odd).
	-- Using "damageType" here is safe: it won't modify any real weapon stat,
	-- because PowerupObjectImplementation::getWeaponStat() doesn't handle it (returns 0).
	primary = { },

	-- No secondaries needed for a pure damage-type PUP.
	secondary = { },

	numberExperimentalProperties = {1, 1, 1, 1},
	experimentalProperties = {"XX", "XX", "XX", "OQ"},
	experimentalWeights = {1, 1, 1, 1},
	experimentalGroupTitles = {"null", "null", "null", "exp_effectiveness"},
	experimentalSubGroupTitles = {"null", "null", "hitpoints", "effect"},
	experimentalMin = {0, 0, 1000, 100},
	experimentalMax = {0, 0, 1000, 100},
	experimentalPrecision = {0, 0, 0, 0},
	experimentalCombineType = {0, 0, 4, 1},
}

ObjectTemplates:addTemplate(object_tangible_powerup_weapon_damage_type_electricity, "object/tangible/powerup/weapon/damage_type_electricity.iff")
