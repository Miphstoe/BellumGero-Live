object_tangible_furniture_hoth_frn_hoth_ice_fog = object_tangible_furniture_hoth_shared_frn_hoth_ice_fog:new {
	-- Fog lives in the client data file's ONOF children; ACTIVATED (on/off) starts it lit.
	objectMenuComponent = "DecorFogMenuComponent",
	optionsBitmask = 257,
}

ObjectTemplates:addTemplate(object_tangible_furniture_hoth_frn_hoth_ice_fog, "object/tangible/furniture/hoth/frn_hoth_ice_fog.iff")
