-- Mandalorian Way of Life — equippable rank titles (title = 1).
-- Client: each skillName needs string/en/skl_t.stf (nameplate / @skl_t). Without it the client shows (skl_t:[skillName]).
-- Optional: skl_n.stf / skl_d.stf for skill UI; Community title dropdown may also need these skills in the client's skill datatables (patch TRE).

local function mandoTitleSkill(skillName)
	return {
		skillName = skillName,
		parentName = "",
		graphType = 4,
		godOnly = 0,
		title = 1,
		profession = 0,
		hidden = 0,
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
		commands = {},
		skillModifiers = {},
		schematicsGranted = {},
		schematicsRevoked = {},
		searchable = 0,
	}
end

addSkill(mandoTitleSkill("mando_title_foundling"))
addSkill(mandoTitleSkill("mando_title_initiate"))
addSkill(mandoTitleSkill("mando_title_hunter"))
addSkill(mandoTitleSkill("mando_title_verdika"))
addSkill(mandoTitleSkill("mando_title_clanbound"))
addSkill(mandoTitleSkill("mando_title_mandalorian"))
