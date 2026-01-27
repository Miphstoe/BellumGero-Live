damage_type_powerups = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		{ itemTemplate = "damage_type_electricity_powerup", weight = 1500000 },
		{ itemTemplate = "damage_type_kinetic_powerup",     weight = 1250000 },
		{ itemTemplate = "damage_type_energy_powerup",      weight = 1250000 },
		{ itemTemplate = "damage_type_blast_powerup",       weight = 1500000 },
		{ itemTemplate = "damage_type_heat_powerup",        weight = 1500000 },
		{ itemTemplate = "damage_type_cold_powerup",        weight = 1500000 },
		{ itemTemplate = "damage_type_acid_powerup",        weight = 1500000 },
	}
}

addLootGroupTemplate("damage_type_powerups", damage_type_powerups)
