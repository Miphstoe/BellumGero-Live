object_mobile_vehicle_landspeeder_xp38 = object_mobile_vehicle_shared_landspeeder_xp38:new {
	templateType = VEHICLE,
	decayRate = 15, -- Damage tick per decay cycle
	decayCycle = 600 -- Time in seconds per cycle
}

ObjectTemplates:addTemplate(object_mobile_vehicle_landspeeder_xp38, "object/mobile/vehicle/landspeeder_xp38.iff")
