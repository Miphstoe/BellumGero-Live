-- Mandalorian Way armory: hidden weapon certifications (granted on chapter trial complete).
-- Weapons require these certs so only players who earned the rank (or equivalent) can equip.

local function mandoArmoryCertSkill(skillName, certCommand)
	return {
		skillName = skillName,
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
		commands = { certCommand },
		skillModifiers = {},
		schematicsGranted = {},
		schematicsRevoked = {},
		searchable = 0,
	}
end

addSkill(mandoArmoryCertSkill("mando_way_cert_geo_blaster", "cert_mando_way_geo_blaster"))
addSkill(mandoArmoryCertSkill("mando_way_cert_slugthrower_carbine", "cert_mando_way_slugthrower_carbine"))
addSkill(mandoArmoryCertSkill("mando_way_cert_lightning_cannon", "cert_mando_way_lightning_cannon"))
