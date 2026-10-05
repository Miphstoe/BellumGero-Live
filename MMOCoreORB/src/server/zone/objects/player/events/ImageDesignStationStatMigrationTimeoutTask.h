#ifndef IMAGEDESIGNSTATIONSTATMIGRATIONTIMEOUTTASK_H_
#define IMAGEDESIGNSTATIONSTATMIGRATIONTIMEOUTTASK_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/tangible/components/imagedesignstation/ImageDesignStationMenuComponent.h"

class ImageDesignStationStatMigrationTimeoutTask : public Task {
	ManagedWeakReference<CreatureObject*> player;
	uint64 stationObjectId;
	String migrationToken;

public:
	ImageDesignStationStatMigrationTimeoutTask(
		CreatureObject* creature,
		uint64 stationId,
		const String& token)
		: player(creature),
		  stationObjectId(stationId),
		  migrationToken(token) {
	}

	void run() override {
		ManagedReference<CreatureObject*> creature =
			player.get();

		if (creature == nullptr)
			return;

		String marker =
			creature->getLuaStringData(
				"fmidstation_stat_migration_station_id");

		String activeToken =
			creature->getLuaStringData(
				"fmidstation_stat_migration_token");

		if (marker.isEmpty() ||
				marker != String::valueOf(stationObjectId) ||
				activeToken.isEmpty() ||
				activeToken != migrationToken) {
			return;
		}

		ImageDesignStationMenuComponent::cancelStationStatMigration(
			creature,
			stationObjectId,
			true,
			migrationToken);
	}
};

#endif
