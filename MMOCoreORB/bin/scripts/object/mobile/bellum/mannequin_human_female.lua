--[[
	Bellum Gero - Human Female Display Mannequin (Phase 2 PoC)
	See mannequin_human_male.lua for design notes. Reuses the stock vendor human-female
	client appearance (object/mobile/vendor/shared_human_female.iff) - no TRE change.
]]

object_mobile_bellum_mannequin_human_female = object_mobile_vendor_shared_human_female:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_human_female, "object/mobile/bellum/mannequin_human_female.iff")
