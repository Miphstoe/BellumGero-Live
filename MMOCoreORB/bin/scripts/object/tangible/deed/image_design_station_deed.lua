-- Bellum Gero - FMIDStation
-- Stationary deed; reuses the stock test-deed client appearance.

object_tangible_deed_image_design_station_deed =
	object_tangible_deed_shared_test_deed:new {

	templateType = DEED,
	objectMenuComponent = "ImageDesignStationDeedMenuComponent",
	generatedObjectTemplate = "object/tangible/terminal/image_design_station.iff",
	customName = "Image Designer Station Deed",
}

ObjectTemplates:addTemplate(
	object_tangible_deed_image_design_station_deed,
	"object/tangible/deed/image_design_station_deed.iff")
