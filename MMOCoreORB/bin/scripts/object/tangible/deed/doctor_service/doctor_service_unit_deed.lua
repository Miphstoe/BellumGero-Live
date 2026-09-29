--[[
	Bellum Gero - FMDoctorBot Automated Medical Station Deed

	Normal DEED, never VEHICLEDEED. Deployment is handled by
	DoctorServiceUnitDeedMenuComponent and produces a stationary persistent TangibleObject.
	Reuses the stock test-deed client asset; NO TRE change required.
]]

object_tangible_deed_doctor_service_doctor_service_unit_deed =
	object_tangible_deed_shared_test_deed:new {

	templateType = DEED,
	objectMenuComponent = "DoctorServiceUnitDeedMenuComponent",
	generatedObjectTemplate = "object/tangible/vendor/doctor_service_unit.iff",
	customName = "Automated Medical Station Deed",
}

ObjectTemplates:addTemplate(
	object_tangible_deed_doctor_service_doctor_service_unit_deed,
	"object/tangible/deed/doctor_service/doctor_service_unit_deed.iff")
