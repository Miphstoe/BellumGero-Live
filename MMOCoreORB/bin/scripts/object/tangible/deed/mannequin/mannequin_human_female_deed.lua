--[[
	Bellum Gero - Human Female Mannequin Deed (Phase 2 PoC)
	See mannequin_human_male_deed.lua for design notes.
]]

object_tangible_deed_mannequin_mannequin_human_female_deed = object_tangible_deed_shared_test_deed:new {
	templateType = DEED,

	objectMenuComponent = "MannequinDeedMenuComponent",

	generatedObjectTemplate = "object/mobile/bellum/mannequin_human_female.iff",

	customName = "Human Female Mannequin Deed",
}

ObjectTemplates:addTemplate(object_tangible_deed_mannequin_mannequin_human_female_deed, "object/tangible/deed/mannequin/mannequin_human_female_deed.iff")
