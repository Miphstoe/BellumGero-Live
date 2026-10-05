#include "server/zone/objects/player/sessions/ImageDesignStationStatMigrationObserver.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/tangible/components/imagedesignstation/ImageDesignStationMenuComponent.h"
#include "templates/params/ObserverEventType.h"

int ImageDesignStationStatMigrationObserverImplementation::notifyObserverEvent(
	uint32 eventType,
	Observable* observable,
	ManagedObject* arg1,
	int64 arg2) {

	ManagedReference<CreatureObject*> creature =
		player.get();

	if (creature == nullptr)
		return 1;

	String stationMarker =
		creature->getLuaStringData(
			"fmidstation_stat_migration_station_id");

	if (stationMarker.isEmpty() ||
			stationMarker != String::valueOf(stationObjectId)) {
		return 1;
	}

	if (eventType == ObserverEventType::LOGGEDOUT) {
		ImageDesignStationMenuComponent::cancelStationStatMigration(
			creature,
			stationObjectId,
			false);

		return 1;
	}

	if (eventType == ObserverEventType::POSITIONCHANGED) {
		ZoneServer* zoneServer =
			creature->getZoneServer();

		ManagedReference<SceneObject*> station =
			zoneServer != nullptr ?
				zoneServer->getObject(stationObjectId) :
				nullptr;

		bool valid =
			station != nullptr &&
			station->getZone() != nullptr &&
			station->getZone() == creature->getZone() &&
			station->getParentID() == creature->getParentID() &&
			station->getDistanceTo(creature) <= 10.0f;

		if (!valid) {
			ImageDesignStationMenuComponent::cancelStationStatMigration(
				creature,
				stationObjectId,
				true);

			return 1;
		}
	}

	return 0;
}
