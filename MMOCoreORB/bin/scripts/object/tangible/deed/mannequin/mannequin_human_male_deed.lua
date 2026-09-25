--[[
	Bellum Gero - Human Male Mannequin Deed (Phase 2 PoC)

	Reuses the stock test-deed client asset (no TRE change). Deploy is handled by
	MannequinDeedMenuComponent: usable only while standing inside a player structure
	cell the player administers. On deploy it creates the persistent MannequinObject
	named by generatedObjectTemplate and consumes the deed.
]]

object_tangible_deed_mannequin_mannequin_human_male_deed = object_tangible_deed_shared_test_deed:new {
	templateType = DEED,

	objectMenuComponent = "MannequinDeedMenuComponent",

	generatedObjectTemplate = "object/mobile/bellum/mannequin_human_male.iff",

	customName = "Human Male Mannequin Deed",
}

ObjectTemplates:addTemplate(object_tangible_deed_mannequin_mannequin_human_male_deed, "object/tangible/deed/mannequin/mannequin_human_male_deed.iff")
