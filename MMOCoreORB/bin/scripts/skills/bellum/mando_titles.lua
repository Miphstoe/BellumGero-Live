-- Mandalorian Way of Life — equippable rank titles (title = 1).
-- Client TRE (bg_custom1.tre): each skillName needs rows in datatables/skill/skills.iff (IS_TITLE=1) or the
-- Community title picker will not list earned ranks after switching to a stock title. Also needs
-- string/en/skl_t.stf (nameplate) and skl_n.stf (dropdown label).
--
-- Nameplate line wrap: the stock client breaks the resolved title to a fixed width. If the
-- skl_t value is too long (e.g. "(Mandalorian Foundling)"), the closing ")" can appear alone on
-- a third line. Fix in client TRE: use a shorter phrase such as "(Mando Foundling)", or place
-- U+00A0 (no-break space) immediately before the final ")" so ")" stays with the preceding text.

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
