-- Placeable house decor: the mysterious shrine from the Mellichae camp / Jedi trials, with switchable fog.
object_tangible_furniture_jedi_frn_jedi_force_shrine = object_tangible_furniture_jedi_shared_frn_jedi_force_shrine:new {
	gameObjectType = 8203,
	objectMenuComponent = "DecorFogMenuComponent",
	optionsBitmask = 257,
}

ObjectTemplates:addTemplate(object_tangible_furniture_jedi_frn_jedi_force_shrine, "object/tangible/furniture/jedi/frn_jedi_force_shrine.iff")
