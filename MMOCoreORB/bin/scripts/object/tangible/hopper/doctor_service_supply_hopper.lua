--[[
	Bellum Gero - FMDoctorBot Medical Supply Hopper

	Server-only child container; NO TRE change required.
	Reuses the stock crafting-station ingredient-hopper client object.
]]

object_tangible_hopper_doctor_service_supply_hopper =
	object_tangible_hopper_shared_crafting_station_ingredient_hopper_1:new {

	containerComponent = "DoctorServiceHopperContainerComponent",
	containerType = 2,
	containerVolumeLimit = 100,
	noTrade = 1,
	customName = "Medical Supply Hopper",
}

ObjectTemplates:addTemplate(
	object_tangible_hopper_doctor_service_supply_hopper,
	"object/tangible/hopper/doctor_service_supply_hopper.iff")
