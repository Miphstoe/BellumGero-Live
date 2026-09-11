--[[
	Bellum Gero - Human Male Display Mannequin (Phase 2 PoC)

	Server-only object template. Reuses the stock vendor human-male client appearance
	(object/mobile/vendor/shared_human_male.iff) so NO TRE change is required.

	gameObjectType is overridden to SceneObjectType::MANNEQUINCREATURE (0x4E0 = 1248) so
	the object factory builds a MannequinObject (subclass of AiAgent). templateType stays
	NPCCREATURE so it parses as an ordinary non-player creature template.

	It is deliberately inert:
	  * optionsBitmask has NO AIENABLED  -> AiAgent FSM never activates
	  * pvpStatusBitmask = 0             -> not attackable, no faction behavior
	  * no primary/secondary weapon, no npc spawn record -> no weapons, no attack maps
]]

object_mobile_bellum_mannequin_human_male = object_mobile_vendor_shared_human_male:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_human_male, "object/mobile/bellum/mannequin_human_male.iff")
