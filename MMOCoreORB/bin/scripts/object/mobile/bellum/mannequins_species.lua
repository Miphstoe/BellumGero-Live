--[[
  Bellum Gero - additional display mannequin species (Phase 2)
  Server-only object templates. Each reuses the stock vendor client appearance
  object/mobile/vendor/shared_<species>_<gender>.iff - NO TRE change required.
  See mannequin_human_male.lua for the full design notes (inert AiAgent subclass,
  gameObjectType 1248 = SceneObjectType::MANNEQUINCREATURE).
]]

object_mobile_bellum_mannequin_bothan_male = object_mobile_vendor_shared_bothan_male:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_bothan_male, "object/mobile/bellum/mannequin_bothan_male.iff")

object_mobile_bellum_mannequin_bothan_female = object_mobile_vendor_shared_bothan_female:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_bothan_female, "object/mobile/bellum/mannequin_bothan_female.iff")

object_mobile_bellum_mannequin_moncal_male = object_mobile_vendor_shared_moncal_male:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_moncal_male, "object/mobile/bellum/mannequin_moncal_male.iff")

object_mobile_bellum_mannequin_moncal_female = object_mobile_vendor_shared_moncal_female:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_moncal_female, "object/mobile/bellum/mannequin_moncal_female.iff")

object_mobile_bellum_mannequin_rodian_male = object_mobile_vendor_shared_rodian_male:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_rodian_male, "object/mobile/bellum/mannequin_rodian_male.iff")

object_mobile_bellum_mannequin_rodian_female = object_mobile_vendor_shared_rodian_female:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_rodian_female, "object/mobile/bellum/mannequin_rodian_female.iff")

object_mobile_bellum_mannequin_trandoshan_male = object_mobile_vendor_shared_trandoshan_male:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_trandoshan_male, "object/mobile/bellum/mannequin_trandoshan_male.iff")

object_mobile_bellum_mannequin_trandoshan_female = object_mobile_vendor_shared_trandoshan_female:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_trandoshan_female, "object/mobile/bellum/mannequin_trandoshan_female.iff")

object_mobile_bellum_mannequin_twilek_male = object_mobile_vendor_shared_twilek_male:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_twilek_male, "object/mobile/bellum/mannequin_twilek_male.iff")

object_mobile_bellum_mannequin_twilek_female = object_mobile_vendor_shared_twilek_female:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_twilek_female, "object/mobile/bellum/mannequin_twilek_female.iff")

object_mobile_bellum_mannequin_zabrak_male = object_mobile_vendor_shared_zabrak_male:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_zabrak_male, "object/mobile/bellum/mannequin_zabrak_male.iff")

object_mobile_bellum_mannequin_zabrak_female = object_mobile_vendor_shared_zabrak_female:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_zabrak_female, "object/mobile/bellum/mannequin_zabrak_female.iff")

object_mobile_bellum_mannequin_wookiee_male = object_mobile_vendor_shared_wookiee_male:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_wookiee_male, "object/mobile/bellum/mannequin_wookiee_male.iff")

object_mobile_bellum_mannequin_wookiee_female = object_mobile_vendor_shared_wookiee_female:new {
	templateType = NPCCREATURE,
	gameObjectType = 1248, -- SceneObjectType::MANNEQUINCREATURE

	objectMenuComponent = "MannequinMenuComponent",
	containerComponent = "MannequinContainerComponent",

	optionsBitmask = INVULNERABLE,
	pvpStatusBitmask = 0,

	customName = "a display mannequin",
}

ObjectTemplates:addTemplate(object_mobile_bellum_mannequin_wookiee_female, "object/mobile/bellum/mannequin_wookiee_female.iff")

