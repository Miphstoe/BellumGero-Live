-- Bellum Gero - FMIDStation
-- Server-only station; reuses the stock Image Design terminal client appearance.

object_tangible_terminal_image_design_station =
	object_tangible_terminal_shared_terminal_imagedesign:new {

	gameObjectType = 8203,
	objectMenuComponent = "ImageDesignStationMenuComponent",
	dataObjectComponent = "ImageDesignStationDataComponent",
	noTrade = 1,
	customName = "Image Designer Station",
}

ObjectTemplates:addTemplate(
	object_tangible_terminal_image_design_station,
	"object/tangible/terminal/image_design_station.iff")
