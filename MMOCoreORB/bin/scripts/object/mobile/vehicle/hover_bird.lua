object_mobile_vehicle_hover_bird = object_mobile_vehicle_shared_hover_bird:new {
	templateType = VEHICLE,
	decayRate = 15, -- Damage tick per decay cycle
	decayCycle = 600 -- Time in seconds per cycle
}

ObjectTemplates:addTemplate(object_mobile_vehicle_hover_bird, "object/mobile/vehicle/hover_bird.iff")
