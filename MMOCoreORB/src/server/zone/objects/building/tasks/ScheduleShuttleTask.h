
#ifndef SCHEDULESHUTTLETASK_H_
#define SCHEDULESHUTTLETASK_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/planet/PlanetManager.h"
#include "server/zone/objects/region/Region.h"

class ScheduleShuttleTask : public Task, public Logger {
	ManagedWeakReference<CreatureObject*> shuttleObject;
	Zone* zone;

public:
	ScheduleShuttleTask(CreatureObject* shuttle, Zone* zon) : Task() {
		shuttleObject = shuttle;
		zone = zon;

		Logger::setLoggingName("ScheduleShuttleTask");
	}

	/**
	 * Searches the zone's active area tree for a player (non-client) city region
	 * at the given position. This is more reliable than getCityRegion() on a
	 * SceneObject, which can be overwritten by overlapping NPC region notifyEnter
	 * events firing after the player city region.
	 */
	ManagedReference<CityRegion*> findPlayerCityRegionAt(float x, float y) {
		SortedVector<ManagedReference<ActiveArea*>> areas;

		// getInRangeActiveAreas uses areaTree->getActiveAreas(x, y) — a point
		// containment query. The z/height param is ignored for ground zones.
		zone->getInRangeActiveAreas(x, 0.0f, y, &areas, true);

		for (int i = 0; i < areas.size(); ++i) {
			ManagedReference<ActiveArea*> area = areas.get(i);

			if (area == nullptr || !area->isCityRegion())
				continue;

			Region* region = dynamic_cast<Region*>(area.get());

			if (region == nullptr)
				continue;

			ManagedReference<CityRegion*> regionCity = region->getCityRegion().get();

			if (regionCity != nullptr && !regionCity->isClientRegion())
				return regionCity;
		}

		return nullptr;
	}

	void run() {
		if (zone == nullptr) {
			error() << " zone has a nullptr.";
			return;
		}

		auto zoneServer = zone->getZoneServer();

		if (zoneServer == nullptr) {
			error() << " zoneServer is nullptr.";
			return;
		}

		if (zoneServer->isServerLoading()) {
			schedule(1000);
			return;
		}

		ManagedReference<CreatureObject*> strongShuttle = shuttleObject.get();

		if (strongShuttle == nullptr) {
			error() << " Shuttle strongShuttle has a nullptr in Zone: " << zone->getZoneName();
			return;
		}

		Locker lock(strongShuttle);

		ManagedReference<PlanetManager*> planetManager = zone->getPlanetManager();

		if (planetManager == nullptr) {
			zone->error() << " planetManager has a nullptr in Zone: " << zone->getZoneName();
			return;
		}

		float shuttleX = strongShuttle->getWorldPositionX();
		float shuttleY = strongShuttle->getWorldPositionY();

		ManagedReference<CityRegion*> cityRegion = strongShuttle->getCityRegion().get();

		ManagedReference<CityRegion*> found = nullptr;
		if (cityRegion == nullptr || cityRegion->isClientRegion()) {
			lock.release();
			found = findPlayerCityRegionAt(shuttleX, shuttleY);
		}

		// Re-acquire the shuttle lock. If lock was never released above this is a
		// no-op (isLockedByCurrentThread() returns true → Locker skips lock()).
		Locker relock(strongShuttle);

		if (found != nullptr) {
			cityRegion = found;
		}

		// Player City
		if ((cityRegion != nullptr) && !cityRegion->isClientRegion()) {
			float x = strongShuttle->getWorldPositionX();
			float y = strongShuttle->getWorldPositionY();
			float z = strongShuttle->getWorldPositionZ();

			Vector3 arrivalVector(x, y, z);

			String zoneName = zone->getZoneName();

			Locker clocker(cityRegion, strongShuttle);

			cityRegion->setShuttleID(strongShuttle->getObjectID());
			clocker.release();

			PlanetTravelPoint* planetTravelPoint = new PlanetTravelPoint(zoneName, cityRegion->getCityRegionName(), arrivalVector, arrivalVector, strongShuttle, 6.f);

			planetManager->addPlayerCityTravelPoint(planetTravelPoint);
			planetManager->scheduleShuttle(strongShuttle, PlanetManager::SHUTTLEPORT);
		} else {
			Reference<PlanetTravelPoint*> travelPoint = planetManager->getNearestPlanetTravelPoint(strongShuttle, 128.f);

			if (travelPoint == nullptr) {
				error() << " Planet Travel Point (travelPoint) has a nullptr in Zone: " << zone->getZoneName();
				return;
			}

			auto oldShuttle = travelPoint->getShuttle();

			if (oldShuttle == nullptr) {
				travelPoint->setShuttle(strongShuttle);

				if (travelPoint->isInterplanetary()) {
					planetManager->scheduleShuttle(strongShuttle, PlanetManager::STARPORT);
				} else {
					planetManager->scheduleShuttle(strongShuttle, PlanetManager::SHUTTLEPORT);
				}
			} else if (oldShuttle != strongShuttle) {
				// Only destroy the duplicate if it is not a player city shuttle installation child.
				// A player city shuttle should never be destroyed here — if city region detection
				// failed entirely above, we must not corrupt the city's shuttleport data.
				uint64 ownerID = strongShuttle->getContainerPermissions()->getOwnerID();
				bool isPlayerCityShuttle = false;

				if (ownerID != 0) {
					ManagedReference<SceneObject*> parentObj = zoneServer->getObject(ownerID);

					if (parentObj != nullptr && parentObj->isShuttleInstallation()) {
						isPlayerCityShuttle = true;
					}
				}

				if (!isPlayerCityShuttle) {
					strongShuttle->destroyObjectFromWorld(true);
					strongShuttle->destroyObjectFromDatabase(true);
				} else {
					error() << " Player city shuttle in Zone: " << zone->getZoneName()
						<< " could not be registered (player city region not resolved). Shuttle OID: "
						<< strongShuttle->getObjectID() << " was NOT destroyed.";
				}
			}
		}
	}
};

#endif /* SCHEDULESHUTTLETASK_H_ */
