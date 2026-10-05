#ifndef IMAGEDESIGNSTATIONSTATMIGRATIONTIMEOUTTASK_H_
#define IMAGEDESIGNSTATIONSTATMIGRATIONTIMEOUTTASK_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/tangible/components/imagedesignstation/ImageDesignStationMenuComponent.h"

class ImageDesignStationStatMigrationTimeoutTask : public Task {
	ManagedWeakReference<CreatureObject*> player;
	uint64 stationObjectId;

public:
	ImageDesignStationStatMigrationTimeoutTask(
		CreatureObject* creature,
		uint64 stationId)
		: player(creature), stationObjectId(stationId) {
	}

	void run() override {
		ManagedReference<CreatureObject*> creature =
			player.get();

		if (creature == nullptr)
			return;

		String marker =
			creature->getLuaStringData(
				"fmidstation_stat_migration_station_id");

		if (marker.isEmpty() ||
				marker != String::valueOf(stationObjectId)) {
			return;
		}

		ImageDesignStationMenuComponent::cancelStationStatMigration(
			creature,
			stationObjectId,
			true);
	}
};

#endif
