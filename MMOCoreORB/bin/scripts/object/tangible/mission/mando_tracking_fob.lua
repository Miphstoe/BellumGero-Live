-- Bellum: movie-style Mandalorian tracking fob (daily bounty interface).
object_tangible_mission_mando_tracking_fob = object_tangible_mission_shared_mando_tracking_fob:new {
	objectMenuComponent = "MandoDailyBountyFobMenuComponent",
	attributeListComponent = "MandoDailyBountyFobAttributeListComponent",
}

ObjectTemplates:addTemplate(object_tangible_mission_mando_tracking_fob, "object/tangible/mission/mando_tracking_fob.iff")
