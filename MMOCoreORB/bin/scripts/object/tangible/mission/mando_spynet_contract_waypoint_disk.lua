-- Legacy item (no longer granted). Radial is a no-op reminder; trials use the yellow bounty camp waypoint only.

object_tangible_mission_mando_spynet_contract_waypoint_disk = object_tangible_mission_shared_mission_datadisk:new {
	objectMenuComponent = "MandoSpynetContractWaypointDiskMenuComponent",
	noTrade = 1,
	objectName = "Spynet Coordinate Disk (legacy)",
	detailedDescription = "Obsolete. Spynet trials now use the yellow bounty camp waypoint on your datapad only. You may destroy this disk.",
}

ObjectTemplates:addTemplate(
	object_tangible_mission_mando_spynet_contract_waypoint_disk,
	"object/tangible/mission/mando_spynet_contract_waypoint_disk.iff"
)
