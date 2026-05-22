-- Player slash /mandoStatus (and client command_table row). Hidden; granted when Foundling arc starts.

mando_way_status_cmd = {
	skillName = "mando_way_status_cmd",
	parentName = "",
	graphType = 4,
	godOnly = 0,
	title = 0,
	profession = 0,
	hidden = 1,
	moneyRequired = 0,
	pointsRequired = 0,
	skillsRequiredCount = 0,
	skillsRequired = {},
	preclusionSkills = {},
	xpType = "",
	xpCost = 0,
	xpCap = 0,
	missionsRequired = {},
	apprenticeshipsRequired = 0,
	statsRequired = {},
	speciesRequired = {},
	jediStateRequired = 0,
	skillAbility = {},
	commands = {
		"mandoStatus",
	},
	skillModifiers = {},
	schematicsGranted = {},
	schematicsRevoked = {},
	searchable = 0,
}

addSkill(mando_way_status_cmd)
