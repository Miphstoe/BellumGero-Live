-- Placeable house decor: the green power crystal from the Mellichae camp / Jedi trials, with switchable fog.
object_tangible_furniture_jedi_frn_jedi_power_shrine_green = object_tangible_furniture_jedi_shared_frn_jedi_power_shrine_green:new {
	gameObjectType = 8203,
	objectMenuComponent = "DecorFogMenuComponent",
	optionsBitmask = 257,
}

ObjectTemplates:addTemplate(object_tangible_furniture_jedi_frn_jedi_power_shrine_green, "object/tangible/furniture/jedi/frn_jedi_power_shrine_green.iff")
