--[[
	Bellum Gero - FMDoctorBot Automated Medical Station

	Server-only template; NO TRE change required.
	Reuses the stock 21-B surgical-droid client appearance, but the server object is
	intentionally a normal furniture-class TangibleObject rather than a Vendor,
	Creature, Vehicle, Terminal, Pet, or ControlDevice.

	The only contained object is the persistent Medical Supply Hopper.
]]

object_tangible_vendor_doctor_service_unit = object_tangible_vendor_shared_vendor_droid_surgical:new {
	gameObjectType = 8203, -- SceneObjectType::FURNITURE

	objectMenuComponent = "DoctorServiceUnitMenuComponent",
	dataObjectComponent = "DoctorBuffDroidDataComponent",
	containerComponent = "DoctorServiceUnitContainerComponent",

	containerType = 2,
	containerVolumeLimit = 1,

	noTrade = 1,
	customName = "Automated Medical Station",
}

ObjectTemplates:addTemplate(
	object_tangible_vendor_doctor_service_unit,
	"object/tangible/vendor/doctor_service_unit.iff")
