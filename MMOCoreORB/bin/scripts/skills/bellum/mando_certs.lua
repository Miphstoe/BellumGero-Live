-- Mandalorian Way of Life — weapon certification skills (hidden, quest-gated).
-- Client TRE (bg_custom1.tre): each skillName needs rows in datatables/skill/skills.iff with
-- SEARCHABLE=0 and the appropriate certifications granted.
--
-- These skills are granted ONLY via the Mandalorian quest screenplay and cannot be trained
-- at trainers. They grant the weapon certifications that were removed from profession skills
-- to prevent non-quest players from using Mandalorian weapons.
--
-- Certifications removed from profession skills in bg_custom1.tre:
-- - combat_carbine_novice: removed cert_carbine_nym_slugthrower
-- - combat_bountyhunter_novice: removed cert_rifle_lightning
-- - combat_commando_heavyweapon_speed_03: removed cert_heavy_lightning_beam

local function mandoCertSkill(skillName, certCommand)
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

-- mando_cert_slugthrower: grants cert_carbine_nym_slugthrower
-- Requires: combat_carbine_novice (original skill that had this cert) + quest grant
local mandoCertSlugthrower = mandoCertSkill("mando_cert_slugthrower", "cert_carbine_nym_slugthrower")
mandoCertSlugthrower.skillsRequired = { "combat_carbine_novice" }
mandoCertSlugthrower.skillsRequiredCount = 1
addSkill(mandoCertSlugthrower)

-- mando_cert_lightning: grants cert_rifle_lightning
-- Requires: combat_bountyhunter_novice (original skill that had this cert) + quest grant
local mandoCertLightning = mandoCertSkill("mando_cert_lightning", "cert_rifle_lightning")
mandoCertLightning.skillsRequired = { "combat_bountyhunter_novice" }
mandoCertLightning.skillsRequiredCount = 1
addSkill(mandoCertLightning)

-- mando_cert_heavy_lightning: grants cert_heavy_lightning_beam
-- Requires: combat_commando_heavyweapon_speed_03 (original skill that had this cert) + quest grant
local mandoCertHeavyLightning = mandoCertSkill("mando_cert_heavy_lightning", "cert_heavy_lightning_beam")
mandoCertHeavyLightning.skillsRequired = { "combat_commando_heavyweapon_speed_03" }
mandoCertHeavyLightning.skillsRequiredCount = 1
addSkill(mandoCertHeavyLightning)
