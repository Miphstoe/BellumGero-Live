-- Mandalorian Way of Life — 30% rare bonus drop from contract target kill
-- One item drawn from this pool on a 30% lootChance roll.
-- Pool: jetpack base, RIS schematic, peko feather, jetpack stabilizer,
--       plus rare Mando trophies (banner, blueprint print, portrait, DW lamp)

mando_contract_rare_bonus = {
	description = "",
	minimumLevel = 0,
	maximumLevel = 0,
	lootItems = {
		{itemTemplate = "jet_pack_base",            weight = 1900000},
		{itemTemplate = "acklay_ris_armor_schematic", weight = 1900000},
		{itemTemplate = "peko_albatross_feather",   weight = 2200000},
		{itemTemplate = "jetpack_stabilizer",       weight = 2200000},
		-- Mando weapon schematics (3% total)
		{itemTemplate = "mando_beskar_pike_schematic",  weight = 50000},
		{itemTemplate = "mando_power_hammer_schematic", weight = 50000},
		{itemTemplate = "mando_stun_baton_schematic",   weight = 50000},
		{itemTemplate = "mando_acid_baton_schematic",   weight = 50000},
		{itemTemplate = "mando_knuckler_schematic",     weight = 50000},
		{itemTemplate = "mando_lava_blade_schematic",   weight = 50000},
		-- Rare Mando trophies (15% total)
		{itemTemplate = "mando_clan_banner",        weight = 300000},
		{itemTemplate = "mando_armor_blueprint_painting", weight = 300000},
		{itemTemplate = "mando_hunter_portrait",    weight = 200000},
		{itemTemplate = "death_watch_lamp",         weight = 200000},
		{itemTemplate = "mando_clan_painting",      weight = 150000},
		{itemTemplate = "mando_helmet_trophy",      weight = 150000},
		{itemTemplate = "mando_holo_emblem",        weight = 100000},
		{itemTemplate = "mando_helmet_holo",        weight = 100000},
	}
}

addLootGroupTemplate("mando_contract_rare_bonus", mando_contract_rare_bonus)
