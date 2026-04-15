/*
 				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#ifndef BOUNTYHUNTERTARGETTASK_H_
#define BOUNTYHUNTERTARGETTASK_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/mission/MissionObject.h"
#include "server/zone/managers/mission/MissionManager.h"
#include "server/zone/managers/collision/PathFinderManager.h"
#include "server/zone/managers/planet/PlanetManager.h"
#include "server/zone/Zone.h"
#include "conf/ConfigManager.h"

namespace server {
namespace zone {
namespace objects {
namespace mission {
namespace bountyhunter {
namespace events {

class BountyHunterTargetTask: public Task, public Logger {
	ManagedWeakReference<MissionObject*> mission;
	ManagedWeakReference<BountyMissionObjective*> objective;
	ManagedWeakReference<CreatureObject*> player;

	Vector3 currentPosition;
	Vector3 destination;
	bool move, movedOffPlanet, movingToStarport, targetSpawned;
	String zoneName;

public:
	BountyHunterTargetTask(MissionObject* mission, CreatureObject* player, const String& zoneName) :
		Logger("BountyHunterTargetTask") {
		this->mission = mission;
		this->player = player;
		this->zoneName = zoneName;
		this->movedOffPlanet = false;
		this->movingToStarport = false;
		this->targetSpawned = false;
		this->destination = Vector3(0, 0, 0);

		objective = cast<BountyMissionObjective*> (mission->getMissionObjective());

		currentPosition.setX(mission->getEndPositionX());
		currentPosition.setY(mission->getEndPositionY());
		currentPosition.setZ(0);

		// Only hard (tier 3) simulates travel / starport / random planet. Standard (tier 2) used to
		// walk toward getRandomBountyTargetPosition() anywhere on the planet, often kilometers from
		// the mission waypoint, so players could not spawn the NPC until they intercepted the moving
		// point. Tier 1 and 2: stay at mission end XY like pre-move behavior.
		if (mission->getMissionLevel() > 2) {
			move = true;
		} else {
			move = false;
		}
	}

	~BountyHunterTargetTask() {
	}

	void run() {
		const bool bountySpawnDbg = ConfigManager::instance()->getBool("Core3.MissionManager.BountyNpcSpawnDebug", false);

		ManagedReference<BountyMissionObjective*> objectiveRef = objective.get();

		if (objectiveRef == nullptr) {
			if (bountySpawnDbg)
				info(true) << "[BountyNpcSpawnDebug] run: objectiveRef is null";
			return;
		}

		ManagedReference<CreatureObject*> playerRef = player.get();

		if (playerRef == nullptr) {
			if (bountySpawnDbg)
				info(true) << "[BountyNpcSpawnDebug] run: playerRef is null";
			return;
		}

		ZoneServer* zoneServer = playerRef->getZoneServer();

		Zone* zone = zoneServer->getZone(zoneName);

		if (zone == nullptr) {
			if (bountySpawnDbg)
				info(true) << "[BountyNpcSpawnDebug] run: mission zone not loaded zoneName=" << zoneName
					<< " player=" << playerRef->getObjectID();
			return;
		}

		ManagedReference<MissionObject*> strongMissionRef = mission.get();

		if (strongMissionRef == nullptr) {
			if (bountySpawnDbg)
				info(true) << "[BountyNpcSpawnDebug] run: mission object null player=" << playerRef->getObjectID();
			return;
		}

		if (destination == Vector3(0, 0, 0)) {
			ManagedReference<PlanetManager*> planetManager = zone->getPlanetManager();

			if (strongMissionRef->getMissionLevel() > 2) {
				Reference<PlanetTravelPoint*> randomStarport = planetManager->getRandomStarport();
				destination = randomStarport->getDeparturePosition();
				destination.setZ(0);
				movingToStarport = true;
			} else {
				destination = zoneServer->getMissionManager()->getRandomBountyTargetPosition(playerRef, zoneName);
			}
		}

		Locker locker(playerRef);

		if (move && !targetSpawned)
			updatePosition(playerRef);

		Zone* playerZone = playerRef->getZone();

		if (bountySpawnDbg && !targetSpawned) {
			String pz = (playerZone != nullptr) ? playerZone->getZoneName() : String("null");
			info(true) << "[BountyNpcSpawnDebug] tick player=" << playerRef->getObjectID()
				<< " mission=" << strongMissionRef->getObjectID()
				<< " missionLevel=" << strongMissionRef->getMissionLevel()
				<< " move=" << (move ? "1" : "0")
				<< " taskZone=" << zoneName << " playerZone=" << pz
				<< " curPos=" << currentPosition.getX() << "," << currentPosition.getY()
				<< " dest=" << destination.getX() << "," << destination.getY()
				<< " template=" << strongMissionRef->getTargetOptionalTemplate();
		}

		if (!targetSpawned && playerZone != nullptr && playerZone->getZoneName() == zoneName) {
			Vector3 playerPosition = playerRef->getWorldPosition();
			playerPosition.setZ(0);

			const float distBefore = playerPosition.distanceTo(currentPosition);

			if (distBefore < 256.0f) {
				const float xBefore = currentPosition.getX();
				const float yBefore = currentPosition.getY();
				updateToSpawnableTargetPosition();
				const float distAfter = playerPosition.distanceTo(currentPosition);

				if (distAfter < 256.0f) {
					if (bountySpawnDbg)
						info(true) << "[BountyNpcSpawnDebug] spawnTarget: player=" << playerRef->getObjectID()
							<< " distBefore=" << distBefore << " distAfter=" << distAfter
							<< " posAdjust=" << (currentPosition.getX() - xBefore) << "," << (currentPosition.getY() - yBefore)
							<< " spawnXY=" << currentPosition.getX() << "," << currentPosition.getY();
					targetSpawned = true;
					Locker olocker(objectiveRef);
					objectiveRef->spawnTarget(zoneName);
				} else if (bountySpawnDbg) {
					info(true) << "[BountyNpcSpawnDebug] navAdjust pushed out of range: player=" << playerRef->getObjectID()
						<< " distBefore=" << distBefore << " distAfter=" << distAfter
						<< " (need <256)";
				}
			} else if (bountySpawnDbg) {
				info(true) << "[BountyNpcSpawnDebug] waiting player in range: player=" << playerRef->getObjectID()
					<< " dist=" << distBefore << " (need <256) curPos=" << currentPosition.getX() << "," << currentPosition.getY();
			}
		} else if (bountySpawnDbg && !targetSpawned) {
			if (playerZone == nullptr)
				info(true) << "[BountyNpcSpawnDebug] player has no zone; taskZone=" << zoneName;
			else if (playerZone->getZoneName() != zoneName)
				info(true) << "[BountyNpcSpawnDebug] wrong planet: player on " << playerZone->getZoneName()
					<< " mission task expects " << zoneName << " player=" << playerRef->getObjectID();
		}

		reschedule(10 * 1000);
	}

	Vector3 getTargetPosition() {
		return currentPosition;
	}

	const String& getTargetZoneName() {
		return zoneName;
	}

private:
	void updatePosition(CreatureObject* player) {
		Vector3 direction = destination - currentPosition;
		float distToDest = direction.length();
		int distPerSec = Math::min(4, 1 + mission.get()->getMissionLevel());
		float distToTravel = distPerSec * 10.f;

		if (distToDest <= distToTravel) {
			currentPosition = destination;

			if (movingToStarport && !movedOffPlanet) {
				zoneName = player->getZoneServer()->getMissionManager()->getRandomBountyPlanet();
				movedOffPlanet = true;
				movingToStarport = false;

				ZoneServer* zoneServer = player->getZoneServer();
				Zone* zone = zoneServer->getZone(zoneName);

				if (zone == nullptr) {
					if (ConfigManager::instance()->getBool("Core3.MissionManager.BountyNpcSpawnDebug", false))
						info(true) << "[BountyNpcSpawnDebug] updatePosition: new zone null after planet roll zoneName=" << zoneName;
					return;
				}

				ManagedReference<MissionObject*> strongMissionRef = mission.get();

				if (strongMissionRef == nullptr)
					return;

				Locker clocker(strongMissionRef, player);
				strongMissionRef->setEndPlanet(zoneName);

				ManagedReference<PlanetManager*> planetManager = zone->getPlanetManager();
				Reference<PlanetTravelPoint*> randomStarport = planetManager->getRandomStarport();
				currentPosition = randomStarport->getDeparturePosition();
			}

			destination = player->getZoneServer()->getMissionManager()->getRandomBountyTargetPosition(player, zoneName);
		} else {
			Vector3 movementUpdate = direction;
			movementUpdate.normalize();
			movementUpdate = movementUpdate * distToTravel;

			currentPosition = currentPosition + movementUpdate;
		}
	}

	void updateToSpawnableTargetPosition() {
		ManagedReference<CreatureObject*> playerRef = player.get();

		if (playerRef == nullptr || playerRef->getZone() == nullptr)
			return;

		Zone* zone = playerRef->getZone();
		SortedVector<ManagedReference<NavArea*> > areas;

		Sphere sphere(Vector3(currentPosition.getX(), currentPosition.getY(), zone->getHeightNoCache(currentPosition.getX(), currentPosition.getY())), 20);
		Vector3 result;

		if (PathFinderManager::instance()->getSpawnPointInArea(sphere, zone, result)) {
			currentPosition.setX(result.getX());
			currentPosition.setY(result.getY());
			return;
		}

		if (canSpawnTargetAt(currentPosition)) {
			return;
		}

		//Spawning at coordinates failed, try to find new coordinates.
		int radius = 50;
		while (radius <= 1600) {
			//Max 20 retries per radius, total 120 retries.
			int retries = 20;

			while (retries > 0) {
				//Generate a random direction and move the target position in that direction within the radius.
				Vector3 direction;
				direction.setX((float)System::random(2 * radius) - radius);
				direction.setY((float)System::random(2 * radius) - radius);
				direction.normalize();
				direction = direction * System::random(radius);

				if (canSpawnTargetAt(currentPosition + direction)) {
					currentPosition = currentPosition + direction;
					return;
				}

				retries--;
			}

			radius *= 2;
		}

		//Failed to find new spawn for the target, spawn at current position.
	}

	bool canSpawnTargetAt(const Vector3& position) {
		ManagedReference<CreatureObject*> playerRef = player.get();

		if (playerRef == nullptr || playerRef->getZone() == nullptr) {
			return false;
		}

		Zone* zone = playerRef->getZone();

		if (zone->getPlanetManager()->isBuildingPermittedAt(position.getX(), position.getY(), nullptr)) {
			return true;
		}

		return true;
	}
};

} // namespace events
} // namespace bountyhunter
} // namespace mission
} // namespace objects
} // namespace zone
} // namespace server

using namespace server::zone::objects::mission::bountyhunter::events;

#endif /* BOUNTYHUNTERTARGETTASK_H_ */
