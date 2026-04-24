object_tangible_wearables_robe_exar_cultist_hood_up = object_tangible_wearables_robe_shared_exar_cultist_hood_up:new {
	playerRaces = { "object/creature/player/bothan_male.iff",
		"object/creature/player/bothan_female.iff",
		"object/creature/player/human_male.iff",
		"object/creature/player/human_female.iff",
		"object/creature/player/ithorian_male.iff",
		"object/creature/player/ithorian_female.iff",
		"object/creature/player/moncal_male.iff",
		"object/creature/player/moncal_female.iff",
		"object/creature/player/rodian_male.iff",
		"object/creature/player/rodian_female.iff",
		"object/creature/player/sullustan_male.iff",
		"object/creature/player/sullustan_female.iff",
		"object/creature/player/trandoshan_male.iff",
		"object/creature/player/trandoshan_female.iff",
		"object/creature/player/twilek_male.iff",
		"object/creature/player/twilek_female.iff",
		"object/creature/player/wookiee_male.iff",
		"object/creature/player/wookiee_female.iff",
		"object/creature/player/zabrak_male.iff",
		"object/creature/player/zabrak_female.iff" },

	maxCondition = 100,
	volume = 1,
	jediRobe = true,

	skillMods = {
		{"jedi_force_power_max", 250},
		{"jedi_force_power_regen", 10}
	},

	objectMenuComponent = "RobeObjectMenuComponent",
	certificationsRequired = {"force_title_jedi_rank_03"},
	attributeListComponent = "JediRobeAttributeListComponent",
}

ObjectTemplates:addTemplate(object_tangible_wearables_robe_exar_cultist_hood_up, "object/tangible/wearables/robe/exar_cultist_hood_up.iff")
