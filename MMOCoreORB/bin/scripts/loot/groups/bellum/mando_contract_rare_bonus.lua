-- Mandalorian Way of Life — 30% rare bonus drop from contract target kill
-- One item drawn from this pool on a 30% lootChance roll.
-- Pool: jetpack base, RIS schematic, peko feather, jetpack stabilizer

mando_contract_rare_bonus = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		{itemTemplate = "jet_pack_base",            weight = 2000000},
		{itemTemplate = "acklay_ris_armor_schematic", weight = 2000000},
		{itemTemplate = "peko_albatross_feather",   weight = 3000000},
		{itemTemplate = "jetpack_stabilizer",       weight = 3000000},
	}
}

addLootGroupTemplate("mando_contract_rare_bonus", mando_contract_rare_bonus)
