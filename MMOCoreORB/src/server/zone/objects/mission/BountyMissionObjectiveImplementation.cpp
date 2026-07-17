/*
 * BountyMissionObjectiveImplementation.cpp
 *
 *  Created on: 20/08/2010
 *      Author: dannuic
 */

#include "server/zone/objects/mission/BountyMissionObjective.h"

#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/mission/MissionManager.h"
#include "server/zone/managers/creature/CreatureManager.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/objects/mission/MissionObject.h"
#include "server/zone/objects/mission/MissionObserver.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/creature/ai/AiAgent.h"
#include "server/zone/objects/group/GroupObject.h"
#include "server/chat/ChatManager.h"
#include "server/zone/objects/mission/bountyhunter/BountyHunterDroid.h"
#include "server/zone/objects/mission/bountyhunter/events/BountyHunterTargetTask.h"
#include "server/zone/objects/mission/bountyhunter/events/BountyTrackingTask.h"
#include "server/zone/objects/mission/bountyhunter/events/DroidSpawnProtectionTask.h"
#include "server/zone/objects/mission/bountyhunter/events/DroidScanCompletionTask.h"
#include "server/zone/managers/visibility/VisibilityManager.h"
#include "server/zone/managers/planet/PlanetManager.h"
#include "templates/params/creature/CreatureAttribute.h"
#include "conf/ConfigManager.h"

namespace {
	String getDisplayPlanetName(const String& zoneName) {
		if (zoneName == "corellia")
			return "Corellia";
		if (zoneName == "dantooine")
			return "Dantooine";
		if (zoneName == "dathomir")
			return "Dathomir";
		if (zoneName == "endor")
			return "Endor";
		if (zoneName == "lok")
			return "Lok";
		if (zoneName == "naboo")
			return "Naboo";
		if (zoneName == "rori")
			return "Rori";
		if (zoneName == "talus")
			return "Talus";
		if (zoneName == "tatooine")
			return "Tatooine";
		if (zoneName == "yavin4")
			return "Yavin IV";

		return zoneName;
	}
}

void BountyMissionObjectiveImplementation::setNpcTemplateToSpawn(SharedObjectTemplate* sp) {
	npcTemplateToSpawn = sp;
}

void BountyMissionObjectiveImplementation::activate() {
	Locker locker(&syncMutex);

	MissionObjectiveImplementation::activate();

	if (droidScanState != DROID_IDLE && (trackingDroid == nullptr || !trackingDroid->isInQuadTree())) {
		info(true) << "[AnonymousJediBounty] Stale droid state reconciled on activate state=" << droidScanState;
		cleanupDroidTracking("Mission reactivated", false);
	}

	if (isPlayerTarget()) {
		ManagedReference<MissionObject* > mission = this->mission.get();
		MissionManager* missionManager = getPlayerOwner()->getZoneServer()->getMissionManager();

		if (missionManager == nullptr || mission == nullptr || !missionManager->hasPlayerBountyTargetInList(mission->getTargetObjectId())
				|| !missionManager->hasBountyHunterInPlayerBounty(mission->getTargetObjectId(), getPlayerOwner()->getObjectID()) || !addPlayerTargetObservers()) {
			getPlayerOwner()->sendSystemMessage("@mission/mission_generic:failed"); // Mission failed
			abort();
			removeMissionFromPlayer();
		} else {
			WaypointObject* waypoint = mission->getWaypointToMission();
			if (waypoint != nullptr) {
				Locker wplocker(waypoint);
				waypoint->setActive(false);
			}

			info(true) << "[AnonymousJediBounty] Mission accepted hunter=" << getPlayerOwner()->getObjectID()
				<< " target=" << mission->getTargetObjectId() << " mission=" << mission->getObjectID();
		}
	} else {
		startNpcTargetTask();

		if (getObserverCount() == 2 && npcTarget == nullptr) {
			removeNpcTargetObservers();
		}
	}
}

void BountyMissionObjectiveImplementation::deactivate() {
	MissionObjectiveImplementation::deactivate();
	clearTrackingData("Mission deactivated", false);

	if (activeDroid != nullptr) {
		if (!activeDroid->isPlayerCreature()) {
			Locker locker(activeDroid);
			activeDroid->destroyObjectFromDatabase();
			activeDroid->destroyObjectFromWorld(true);
		}

		activeDroid = nullptr;
	}

	cancelAllTasks();

	if (!isPlayerTarget()) {
		removeNpcTargetObservers();
	}
}

void BountyMissionObjectiveImplementation::abort() {
	Locker locker(&syncMutex);

	ManagedReference<MissionObject*> strongRef = mission.get();

	MissionObjectiveImplementation::abort();
	clearTrackingData("Mission abandonment", false);
	info(true) << "[AnonymousJediBounty] Mission abandonment mission=" << (strongRef != nullptr ? strongRef->getObjectID() : (uint64)0);

	cancelAllTasks();

	if (activeDroid != nullptr) {
		if (!activeDroid->isPlayerCreature()) {
			Locker locker(activeDroid);
			activeDroid->destroyObjectFromDatabase();
			activeDroid->destroyObjectFromWorld(true);
		}

		activeDroid = nullptr;
	}

	if (strongRef == nullptr)
		return;

	WaypointObject* waypoint = strongRef->getWaypointToMission();
	if (waypoint != nullptr && waypoint->isActive()) {
		Locker wplocker(waypoint);
		waypoint->setActive(false);
	}

	//Remove observers
	if (hasObservers()) {
		if (isPlayerTarget()) {
			removePlayerTargetObservers();
		} else {
			removeNpcTargetObservers();
		}
	}
}

void BountyMissionObjectiveImplementation::complete() {
	Locker locker(&syncMutex);

	if (completedMission) {
		return;
	}

	cancelAllTasks();

	ManagedReference<MissionObject* > mission = this->mission.get();

	if(mission == nullptr)
		return;

	ManagedReference<CreatureObject*> owner = getPlayerOwner();
	//Award bountyhunter xp.

	int expGain = (mission->getRewardCredits() + mission->getBonusCredits()) / 50;

	owner->getZoneServer()->getPlayerManager()->awardExperience(owner, "bountyhunter", expGain, true, 1);

	owner->getZoneServer()->getMissionManager()->completePlayerBounty(mission->getTargetObjectId(), owner->getObjectID());
	clearTrackingData("Mission completion", false);
	info(true) << "[AnonymousJediBounty] Mission completion hunter=" << owner->getObjectID()
		<< " target=" << mission->getTargetObjectId() << " mission=" << mission->getObjectID();

	completedMission = true;

	locker.release();

	MissionObjectiveImplementation::complete();
}

void BountyMissionObjectiveImplementation::spawnTarget(const String& zoneName) {
	Locker locker(&syncMutex);

	const bool bountySpawnDbg = ConfigManager::instance()->getBool("Core3.MissionManager.BountyNpcSpawnDebug", false);

	ManagedReference<MissionObject* > mission = this->mission.get();

	if (mission == nullptr || (npcTarget != nullptr && npcTarget->isInQuadTree()) || isPlayerTarget()) {
		if (bountySpawnDbg) {
			info(true) << "[BountyNpcSpawnDebug] spawnTarget early return mission="
				<< (mission != nullptr ? mission->getObjectID() : (uint64)0)
				<< " npcInTree=" << (npcTarget != nullptr && npcTarget->isInQuadTree() ? "1" : "0")
				<< " playerTarget=" << (isPlayerTarget() ? "1" : "0");
		}
		return;
	}

	ManagedReference<CreatureObject*> ownerDbg = getPlayerOwner();

	ZoneServer* zoneServer = getPlayerOwner()->getZoneServer();
	Zone* zone = zoneServer->getZone(zoneName);

	if (zone == nullptr){
		error("null zone " + zoneName + " in BountyMissionObjective::spawnTarget");

		return;
	}

	CreatureManager* cmng = zone->getCreatureManager();

	if (npcTarget == nullptr) {
		Vector3 position = getTargetPosition();
		const float spawnZ = zone->getHeight(position.getX(), position.getY());

		if (bountySpawnDbg) {
			info(true) << "[BountyNpcSpawnDebug] spawnTarget spawnCreatureWithAi owner=" << (ownerDbg != nullptr ? ownerDbg->getObjectID() : 0)
				<< " mission=" << mission->getObjectID()
				<< " zone=" << zoneName
				<< " template=" << mission->getTargetOptionalTemplate()
				<< " xy=" << position.getX() << "," << position.getY() << " z=" << spawnZ
				<< " targetDisplayName=" << mission->getTargetName();
		}

		try {
			npcTarget = cast<AiAgent*>(zone->getCreatureManager()->spawnCreatureWithAi(mission->getTargetOptionalTemplate().hashCode(), position.getX(), spawnZ, position.getY(), 0));
		} catch (Exception& e) {
			fail();
			ManagedReference<CreatureObject*> player = getPlayerOwner();
			if (player != nullptr) {
				player->sendSystemMessage("ERROR: could not find template for target. Please report this on Mantis to help us track down the root cause.");
			}
			error("Template error: " + e.getMessage() + " Template = '" + mission->getTargetOptionalTemplate() +"'");
		}
		if (npcTarget != nullptr) {
			if (bountySpawnDbg) {
				info(true) << "[BountyNpcSpawnDebug] spawn OK oid=" << npcTarget->getObjectID()
					<< " inQuadTree=" << (npcTarget->isInQuadTree() ? "1" : "0")
					<< " worldPos=" << npcTarget->getWorldPosition().getX() << "," << npcTarget->getWorldPosition().getY()
					<< "," << npcTarget->getWorldPosition().getZ();
			}
			npcTarget->setCustomObjectName(mission->getTargetName(), true);

			// Set inventory loot ownership to mission owner so bounty mission completion works correctly
			SceneObject* targetInventory = npcTarget->getSlottedObject("inventory");
			if (targetInventory != nullptr) {
				ManagedReference<CreatureObject*> owner = getPlayerOwner();
				if (owner != nullptr) {
					GroupObject* group = owner->getGroup();
					// Set loot owner to player or their group
					ContainerPermissions* permissions = targetInventory->getContainerPermissionsForUpdate();
					if (group != nullptr) {
						permissions->setOwner(group->getObjectID());
					} else {
						permissions->setOwner(owner->getObjectID());
					}
				}
			}

			//TODO add observer to catch player kill and fail mission in that case.
			addObserverToCreature(ObserverEventType::OBJECTDESTRUCTION, npcTarget);
			addObserverToCreature(ObserverEventType::DAMAGERECEIVED, npcTarget);
		} else {
			if (bountySpawnDbg)
				info(true) << "[BountyNpcSpawnDebug] spawnCreatureWithAi returned null template=" << mission->getTargetOptionalTemplate();
			fail();
			ManagedReference<CreatureObject*> player = getPlayerOwner();
			if (player != nullptr) {
				player->sendSystemMessage("ERROR: could not find template for target. Please report this on Mantis to help us track down the root cause.");
			}
			error("Could not spawn template: '" + mission->getTargetOptionalTemplate() + "'");
		}
	}
}

int BountyMissionObjectiveImplementation::notifyObserverEvent(MissionObserver* observer, uint32 eventType, Observable* observable, ManagedObject* arg1, int64 arg2) {
	Locker locker(&syncMutex);

	if (eventType == ObserverEventType::OBJECTDESTRUCTION) {
		SceneObject* destroyed = cast<SceneObject*>(observable);

		if (trackingDroid != nullptr && destroyed != nullptr && destroyed->getObjectID() == trackingDroid->getObjectID()) {
			handleTrackingDroidDestroyed(observable, arg1);
		} else {
			handleNpcTargetKilled(observable);
		}
	} else if (eventType == ObserverEventType::DAMAGERECEIVED) {
		SceneObject* damaged = cast<SceneObject*>(observable);

		if (trackingDroid != nullptr && damaged != nullptr && damaged->getObjectID() == trackingDroid->getObjectID()) {
			ManagedReference<MissionObject*> missionRef = mission.get();
			info(true) << "[AnonymousJediBounty] Droid damage droid=" << trackingDroid->getObjectID()
				<< " mission=" << (missionRef != nullptr ? missionRef->getObjectID() : (uint64)0);
			return 0;
		}

		return handleNpcTargetReceivesDamage(arg1);
	} else if (eventType == ObserverEventType::PLAYERKILLED) {
		handlePlayerKilled(arg1, arg2);
	} else if (eventType == ObserverEventType::LOGGEDOUT) {
		ManagedReference<MissionObject*> mission = this->mission.get();
		SceneObject* loggedOut = cast<SceneObject*>(observable);
		ManagedReference<CreatureObject*> owner = getPlayerOwner();

		if (mission != nullptr && loggedOut != nullptr && loggedOut->getObjectID() == mission->getTargetObjectId()) {
			clearTrackingData("Target unavailable", true);
			info(true) << "[AnonymousJediBounty] Logout cleanup target=" << mission->getTargetObjectId()
				<< " mission=" << mission->getObjectID();
		} else {
			clearTrackingData("Logout cleanup", owner != nullptr && loggedOut != nullptr && loggedOut->getObjectID() != owner->getObjectID());
			if (mission != nullptr)
				info(true) << "[AnonymousJediBounty] Logout cleanup mission=" << mission->getObjectID();
		}
	}

	return 0;
}

void BountyMissionObjectiveImplementation::updateMissionStatus(int informantLevel) {
	Locker locker(&syncMutex);

	ManagedReference<MissionObject* > mission = this->mission.get();

	if (getPlayerOwner() == nullptr || mission == nullptr) {
		return;
	}

	switch (objectiveStatus) {
	case INITSTATUS:
		if (mission->getTargetOptionalTemplate() != "" && (targetTask == nullptr || !targetTask->isScheduled())) {
			startNpcTargetTask();
		}

		if (!isPlayerTarget() && informantLevel >= 1) {
			updateWaypoint();
		}
		objectiveStatus = HASBIOSIGNATURESTATUS;
		break;
	case HASBIOSIGNATURESTATUS:
		if (!isPlayerTarget() && informantLevel > 1) {
			updateWaypoint();
		}
		objectiveStatus = HASTALKED;
		break;
	case HASTALKED:
		if (!isPlayerTarget() && informantLevel > 1) {
			updateWaypoint();
		}
		break;
	default:
		break;
	}
}

void BountyMissionObjectiveImplementation::updateWaypoint() {
	Locker locker(&syncMutex);

	ManagedReference<MissionObject* > mission = this->mission.get();

	if(mission == nullptr)
		return;

	if (isPlayerTarget())
		return;

	WaypointObject* waypoint = mission->getWaypointToMission();

	Locker wplocker(waypoint);

	waypoint->setPlanetCRC(getTargetZoneName().hashCode());
	Vector3 position = getTargetPosition();
	waypoint->setPosition(position.getX(), 0, position.getY());
	waypoint->setActive(true);

	mission->updateMissionLocation();

	if (mission->getMissionLevel() == 1) {
		getPlayerOwner()->sendSystemMessage("@mission/mission_bounty_informant:target_location_received"); // Target Waypoint Received.
	}
}

void BountyMissionObjectiveImplementation::performDroidAction(int action, SceneObject* sceneObject, CreatureObject* player) {
	Locker locker(&syncMutex);

	if (!playerHasMissionOfCorrectLevel(action)) {
		player->sendSystemMessage("@mission/mission_generic:bounty_no_ability"); // You do not understand how to use this item.
		return;
	}

	if (droid == nullptr) {
		droid = new BountyHunterDroid();
	}

	Reference<Task*> task = droid->performAction(action, sceneObject, player, getMissionObject().get());

	if (task != nullptr)
		droidTasks.add(task);
}

bool BountyMissionObjectiveImplementation::hasArakydFindTask() {
	Locker locker(&syncMutex);

	for (int i = 0; i < droidTasks.size(); i++) {
		Reference<Task*> task = droidTasks.get(i);

		if (task != nullptr) {
			Reference<FindTargetTask*> findTask = task.castTo<FindTargetTask*>();

			if (findTask != nullptr) {
				if (!findTask->isCompleted() && findTask->isArakydTask())
					return true;
			}
		}
	}

	return false;
}

bool BountyMissionObjectiveImplementation::playerHasMissionOfCorrectLevel(int action) {
	Locker locker(&syncMutex);

	ManagedReference<MissionObject* > mission = this->mission.get();
	if(mission == nullptr)
		return false;

	int levelNeeded = 2;
	if (action == BountyHunterDroid::FINDANDTRACKTARGET) {
		levelNeeded = 3;
	}

	return mission->getMissionLevel() >= levelNeeded;
}

Vector3 BountyMissionObjectiveImplementation::getTargetPosition() {
	Locker locker(&syncMutex);

	Vector3 empty;

	ManagedReference<MissionObject* > mission = this->mission.get();

	if(mission == nullptr)
		return empty;

	if (isPlayerTarget()) {
		uint64 targetId = mission->getTargetObjectId();

		ZoneServer* zoneServer = getPlayerOwner()->getZoneServer();
		if (zoneServer != nullptr) {
			ManagedReference<CreatureObject*> creature = zoneServer->getObject(targetId).castTo<CreatureObject*>();

			if (creature != nullptr) {
				Vector3 targetPos = creature->getWorldPosition();
				targetPos.setZ(0);
				return targetPos;
			}
		}
	} else {
		if (targetTask != nullptr) {
			return targetTask->getTargetPosition();
		}
	}

	return empty;
}

void BountyMissionObjectiveImplementation::cancelAllTasks() {
	Locker locker(&syncMutex);

	if (targetTask != nullptr && targetTask->isScheduled()) {
		targetTask->cancel();
		targetTask = nullptr;
	}

	/*for (int i = 0; i < droidTasks.size(); i++) {
		Reference<Task*> droidTask = droidTasks.get(i);

		if (droidTask != nullptr && droidTask->isScheduled()) {
			droidTask->cancel();
		}
	}*/

	droidTasks.removeAll();

	if (trackingTask != nullptr && trackingTask->isScheduled()) {
		trackingTask->cancel();
	}

	trackingTask = nullptr;
}

void BountyMissionObjectiveImplementation::cancelCallArakydTask() {
	Locker locker(&syncMutex);

	for (int i = 0; i < droidTasks.size(); i++) {
		Reference<Task*> task = droidTasks.get(i);

		if (task != nullptr) {
			Reference<CallArakydTask*> callTask = task.castTo<CallArakydTask*>();

			if (callTask != nullptr && callTask->isScheduled()) {
				callTask->cancel();
			}
		}
	}
}

String BountyMissionObjectiveImplementation::getTargetZoneName() {
	Locker locker(&syncMutex);

	ManagedReference<MissionObject* > mission = this->mission.get();
	if(mission == nullptr)
		return "dungeon1";

	if (isPlayerTarget()) {
		uint64 targetId = mission->getTargetObjectId();

		ZoneServer* zoneServer = getPlayerOwner()->getZoneServer();
		if (zoneServer != nullptr) {
			ManagedReference<CreatureObject*> creature = zoneServer->getObject(targetId).castTo<CreatureObject*>();

			if (creature != nullptr && creature->getZone() != nullptr) {
				return creature->getZone()->getZoneName();
			}
		}
	} else {
		if (targetTask != nullptr) {
			return targetTask->getTargetZoneName();
		}
	}

	//No target task, return dungeon1 which is not able to find.
	return "dungeon1";
}

void BountyMissionObjectiveImplementation::removePlayerTargetObservers() {
	Locker locker(&syncMutex);

	ManagedReference<MissionObject* > mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();

	if(owner == nullptr || mission == nullptr)
		return;

	ZoneServer* zoneServer = owner->getZoneServer();
	ManagedReference<CreatureObject*> target = nullptr;

	if (zoneServer != nullptr) {
		target = zoneServer->getObject(mission->getTargetObjectId()).castTo<CreatureObject*>();
	}

	for (int i = getObserverCount() - 1; i >= 0; --i) {
		ManagedReference<MissionObserver*> observer = getObserver(i);

		if (owner != nullptr) {
			owner->dropObserver(ObserverEventType::PLAYERKILLED, observer);
			owner->dropObserver(ObserverEventType::LOGGEDOUT, observer);
		}

		if (target != nullptr) {
			target->dropObserver(ObserverEventType::PLAYERKILLED, observer);
			target->dropObserver(ObserverEventType::LOGGEDOUT, observer);
		}

		dropObserver(observer, true);
	}
}

void BountyMissionObjectiveImplementation::removeNpcTargetObservers() {
	if (npcTarget != nullptr) {
		ManagedReference<SceneObject*> npcHolder = npcTarget.get();
		Locker locker(npcTarget);

		removeObserver(1, ObserverEventType::DAMAGERECEIVED, npcTarget);
		removeObserver(0, ObserverEventType::OBJECTDESTRUCTION, npcTarget);

		npcTarget->destroyObjectFromDatabase();
		npcTarget->destroyObjectFromWorld(true);

		npcTarget = nullptr;
	} else {
		// NPC not spawned, remove observers anyway.
		Locker locker(&syncMutex);

		for (int i = getObserverCount() - 1; i >= 0; i--) {
			dropObserver(getObserver(i), true);
		}
	}
}

void BountyMissionObjectiveImplementation::removeObserver(int observerNumber, unsigned int observerType, CreatureObject* creature) {
	Locker locker(&syncMutex);

	if (getObserverCount() <= observerNumber) {
		//Observer does not exist.
		return;
	}

	ManagedReference<MissionObserver*> observer = getObserver(observerNumber);

	if (creature != nullptr)
		creature->dropObserver(observerType, observer);

	dropObserver(observer, true);
}

void BountyMissionObjectiveImplementation::addObserverToCreature(unsigned int observerType, CreatureObject* creature) {
	ManagedReference<MissionObserver*> observer = new MissionObserver(_this.getReferenceUnsafeStaticCast());
	addObserver(observer, true);

	creature->registerObserver(observerType, observer);
}

bool BountyMissionObjectiveImplementation::addPlayerTargetObservers() {
	Locker locker(&syncMutex);

	ManagedReference<MissionObject* > mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();

	if(mission == nullptr || owner == nullptr)
		return false;

	ZoneServer* zoneServer = owner->getZoneServer();

	if (zoneServer != nullptr) {
		ManagedReference<CreatureObject*> target = zoneServer->getObject(mission->getTargetObjectId()).castTo<CreatureObject*>();

		if (target != nullptr) {
			addObserverToCreature(ObserverEventType::PLAYERKILLED, target);

			addObserverToCreature(ObserverEventType::PLAYERKILLED, owner);

			addObserverToCreature(ObserverEventType::LOGGEDOUT, target);

			addObserverToCreature(ObserverEventType::LOGGEDOUT, owner);

			//Update status on target for bh. Attackability remains closed until tracking confirms the contract.
			target->sendPvpStatusTo(owner);

			return true;
		}
	}

	return false;
}

void BountyMissionObjectiveImplementation::startNpcTargetTask() {
	Locker locker(&syncMutex);

	ManagedReference<MissionObject* > mission = this->mission.get();

	if(mission == nullptr)
		return;

	if (targetTask == nullptr)
		targetTask = new BountyHunterTargetTask(mission, getPlayerOwner(), mission->getEndPlanet());

	if (targetTask != nullptr && !targetTask->isScheduled()) {
		targetTask->schedule(10 * 1000);
	}
}

bool BountyMissionObjectiveImplementation::isPlayerTarget() {
	ManagedReference<MissionObject* > mission = this->mission.get();
	if(mission == nullptr)
		return false;

	return mission->getTargetOptionalTemplate() == "";
}

bool BountyMissionObjectiveImplementation::handleArakydTrackingScan(CreatureObject* player) {
	Locker locker(&syncMutex);

	ManagedReference<MissionObject*> mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();

	if (player == nullptr || mission == nullptr || owner == nullptr || player->getObjectID() != owner->getObjectID() || !isPlayerTarget())
		return false;

	ZoneServer* zoneServer = owner->getZoneServer();
	if (zoneServer == nullptr)
		return false;

	MissionManager* missionManager = zoneServer->getMissionManager();
	if (missionManager == nullptr || !missionManager->hasPlayerBountyTargetInList(mission->getTargetObjectId())
			|| !missionManager->hasBountyHunterInPlayerBounty(mission->getTargetObjectId(), owner->getObjectID())) {
		clearTrackingData("Authorization cleanup", false);
		return false;
	}

	ManagedReference<CreatureObject*> target = zoneServer->getObject(mission->getTargetObjectId()).castTo<CreatureObject*>();

	if (target == nullptr || target->getZone() == nullptr || !target->isOnline() || !owner->isOnline()) {
		clearTrackingData("Target unavailable", true);
		info(true) << "[AnonymousJediBounty] Target unavailable hunter=" << owner->getObjectID()
			<< " target=" << mission->getTargetObjectId() << " mission=" << mission->getObjectID();
		return false;
	}

	String targetZone = target->getZone()->getZoneName();
	Zone* playerZone = player->getZone();
	String playerZoneName = playerZone != nullptr ? playerZone->getZoneName() : "";

	if (trackingPlanet == "" || trackingPlanet != targetZone || playerZoneName != targetZone) {
		clearTrackingData("Initial planet scan", false);
		trackingPlanet = targetZone;
		trackingState = TRACKING_PLANET_KNOWN;

		StringBuffer msg;
		msg << "Target located.\nPlanet: " << getDisplayPlanetName(targetZone);
		player->sendSystemMessage(msg.toString());
		player->sendSystemMessage("Target planet identified.");

		info(true) << "[AnonymousJediBounty] Initial planet scan hunter=" << owner->getObjectID()
			<< " target=" << target->getObjectID() << " planet=" << targetZone
			<< " mission=" << mission->getObjectID();
		return true;
	}

	info(true) << "[AnonymousJediBounty] Same-planet location scan hunter=" << owner->getObjectID()
		<< " target=" << target->getObjectID() << " planet=" << targetZone
		<< " mission=" << mission->getObjectID();

	return beginDroidTrackingScan(player, target);
}

bool BountyMissionObjectiveImplementation::beginDroidTrackingScan(CreatureObject* player, CreatureObject* target) {
	ManagedReference<MissionObject*> mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();

	if (player == nullptr || target == nullptr || mission == nullptr || owner == nullptr)
		return false;

	ZoneServer* zoneServer = owner->getZoneServer();
	if (zoneServer == nullptr)
		return false;

	MissionManager* missionManager = zoneServer->getMissionManager();
	if (missionManager == nullptr)
		return false;

	uint64 now = Time().getMiliTime();

	if (droidScanState != DROID_IDLE) {
		player->sendSystemMessage("A tracking droid is already active for this contract.");
		info(true) << "[AnonymousJediBounty] Droid deploy rejected (already active) hunter=" << owner->getObjectID()
			<< " target=" << target->getObjectID() << " mission=" << mission->getObjectID();
		return false;
	}

	uint64 relaunchCooldown = missionManager->getAnonymousJediBountyDroidRelaunchCooldown();

	if (droidLastDestroyedTime > 0 && now < droidLastDestroyedTime + relaunchCooldown) {
		player->sendSystemMessage("Tracking droid systems recharging. Try again shortly.");
		info(true) << "[AnonymousJediBounty] Droid deploy rejected (cooldown) hunter=" << owner->getObjectID()
			<< " target=" << target->getObjectID() << " remaining=" << (droidLastDestroyedTime + relaunchCooldown - now)
			<< " mission=" << mission->getObjectID();
		return false;
	}

	Zone* targetZone = target->getZone();
	if (targetZone == nullptr)
		return false;

	PlanetManager* planetManager = targetZone->getPlanetManager();
	Vector3 spawnPosition = target->getWorldPosition();

	if (planetManager != nullptr) {
		spawnPosition = planetManager->getInSightSpawnPoint(target, 5, missionManager->getAnonymousJediBountyDroidMaxDistanceFromTarget(), 15);
	}

	float spawnZ = targetZone->getHeight(spawnPosition.getX(), spawnPosition.getY());

	uint32 templateCRC = missionManager->getAnonymousJediBountyDroidTemplate().hashCode();

	ManagedReference<AiAgent*> newDroid = cast<AiAgent*>(targetZone->getCreatureManager()->spawnCreature(templateCRC, 0, spawnPosition.getX(), spawnZ, spawnPosition.getY(), 0));

	if (newDroid == nullptr) {
		error("Failed to spawn bounty tracking droid template");
		return false;
	}

	Locker droidLocker(newDroid);

	newDroid->addObjectFlag(ObjectFlag::STATIC);
	newDroid->setAITemplate();

	int configuredHealth = missionManager->getAnonymousJediBountyDroidHealth();

	if (configuredHealth > 0) {
		newDroid->setBaseHAM(CreatureAttribute::HEALTH, configuredHealth);
		newDroid->setHAM(CreatureAttribute::HEALTH, configuredHealth);
	}

	ManagedReference<MissionObserver*> observer = new MissionObserver(_this.getReferenceUnsafeStaticCast());
	addObserver(observer, true);
	newDroid->registerObserver(ObserverEventType::OBJECTDESTRUCTION, observer);
	newDroid->registerObserver(ObserverEventType::DAMAGERECEIVED, observer);
	droidObserver = observer;

	droidLocker.release();

	trackingDroid = newDroid;
	droidScanToken++;
	droidScanState = DROID_DEPLOYING;

	if (droidSpawnProtectionTask != nullptr && droidSpawnProtectionTask->isScheduled())
		droidSpawnProtectionTask->cancel();

	droidSpawnProtectionTask = new DroidSpawnProtectionTask(_this.getReferenceUnsafeStaticCast(), droidScanToken);
	droidSpawnProtectionTask->schedule(missionManager->getAnonymousJediBountyDroidSpawnProtection());

	player->sendSystemMessage("Deploying Arakyd probe droid...");

	info(true) << "[AnonymousJediBounty] Droid deployed hunter=" << owner->getObjectID()
		<< " target=" << target->getObjectID() << " droid=" << newDroid->getObjectID()
		<< " mission=" << mission->getObjectID();

	return true;
}

void BountyMissionObjectiveImplementation::endDroidSpawnProtection(uint64 token) {
	Locker locker(&syncMutex);

	if (token != droidScanToken || droidScanState != DROID_DEPLOYING) {
		info(true) << "[AnonymousJediBounty] Duplicate callback prevented (spawn protection) token=" << token
			<< " currentToken=" << droidScanToken << " state=" << droidScanState;
		return;
	}

	ManagedReference<MissionObject*> mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();

	if (mission == nullptr || owner == nullptr || trackingDroid == nullptr) {
		droidScanState = DROID_CANCELLED;
		cleanupDroidTracking("Scan cancelled", false);
		return;
	}

	ZoneServer* zoneServer = owner->getZoneServer();
	MissionManager* missionManager = zoneServer != nullptr ? zoneServer->getMissionManager() : nullptr;

	if (missionManager == nullptr) {
		droidScanState = DROID_CANCELLED;
		cleanupDroidTracking("Scan cancelled", false);
		return;
	}

	ManagedReference<CreatureObject*> target = zoneServer->getObject(mission->getTargetObjectId()).castTo<CreatureObject*>();

	if (target == nullptr || target->getZone() == nullptr || !target->isOnline() || target->isDead() || !owner->isOnline()) {
		droidScanState = DROID_CANCELLED;
		info(true) << "[AnonymousJediBounty] Scan cancelled (target unavailable) hunter=" << owner->getObjectID()
			<< " mission=" << mission->getObjectID();
		cleanupDroidTracking("Scan cancelled", false);
		return;
	}

	info(true) << "[AnonymousJediBounty] Droid spawn complete droid=" << trackingDroid->getObjectID()
		<< " mission=" << mission->getObjectID();

	droidScanState = DROID_SCANNING;

	uint64 scanDuration = missionManager->getAnonymousJediBountyDroidScanDuration();
	uint64 flagDuration = scanDuration + 5000;

	Locker targetLocker(target);
	target->addPersonalEnemyFlag(trackingDroid, flagDuration);
	targetLocker.release();

	Locker droidLocker(trackingDroid);
	trackingDroid->addPersonalEnemyFlag(target, flagDuration);
	trackingDroid->sendPvpStatusTo(target);
	droidLocker.release();

	info(true) << "[AnonymousJediBounty] Spawn protection ended droid=" << trackingDroid->getObjectID()
		<< " mission=" << mission->getObjectID();

	target->sendSystemMessage("An Arakyd probe droid is scanning your location.");

	info(true) << "[AnonymousJediBounty] Jedi warned target=" << target->getObjectID()
		<< " mission=" << mission->getObjectID();

	info(true) << "[AnonymousJediBounty] Scan started hunter=" << owner->getObjectID()
		<< " target=" << target->getObjectID() << " droid=" << trackingDroid->getObjectID()
		<< " duration=" << scanDuration << " mission=" << mission->getObjectID();

	if (droidScanTask != nullptr && droidScanTask->isScheduled())
		droidScanTask->cancel();

	droidScanTask = new DroidScanCompletionTask(_this.getReferenceUnsafeStaticCast(), droidScanToken);
	droidScanTask->schedule(scanDuration);
}

void BountyMissionObjectiveImplementation::completeDroidScan(uint64 token) {
	Locker locker(&syncMutex);

	if (token != droidScanToken || droidScanState != DROID_SCANNING) {
		info(true) << "[AnonymousJediBounty] Duplicate callback prevented (scan completion) token=" << token
			<< " currentToken=" << droidScanToken << " state=" << droidScanState;
		return;
	}

	ManagedReference<MissionObject*> mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();

	if (mission == nullptr || owner == nullptr) {
		droidScanState = DROID_CANCELLED;
		cleanupDroidTracking("Scan cancelled", false);
		return;
	}

	ZoneServer* zoneServer = owner->getZoneServer();
	MissionManager* missionManager = zoneServer != nullptr ? zoneServer->getMissionManager() : nullptr;

	if (missionManager == nullptr) {
		droidScanState = DROID_CANCELLED;
		cleanupDroidTracking("Scan cancelled", false);
		return;
	}

	ManagedReference<CreatureObject*> target = zoneServer->getObject(mission->getTargetObjectId()).castTo<CreatureObject*>();

	// Defense in depth - re-validate the target is still a valid, reachable scan target
	// (the completion timer is a one-shot and does not otherwise poll for planet changes/logout).
	if (target == nullptr || target->getZone() == nullptr || target->isDead() || !target->isOnline() || !owner->isOnline()
			|| owner->getZone() == nullptr || target->getZone()->getZoneName() != owner->getZone()->getZoneName()
			|| target->getZone()->getZoneName() != trackingPlanet) {
		droidScanState = DROID_CANCELLED;
		info(true) << "[AnonymousJediBounty] Scan cancelled (target unavailable) hunter=" << owner->getObjectID()
			<< " mission=" << mission->getObjectID();
		cleanupDroidTracking("Scan cancelled", false);
		return;
	}

	WaypointObject* waypoint = mission->getWaypointToMission();

	if (waypoint == nullptr) {
		droidScanState = DROID_CANCELLED;
		cleanupDroidTracking("Scan cancelled", false);
		return;
	}

	String targetZone = target->getZone()->getZoneName();

	float accuracy = missionManager->getAnonymousJediBountyWaypointAccuracy();
	float offsetX = 0.f;
	float offsetY = 0.f;

	if (accuracy > 0.f) {
		int scaledAccuracy = (int)(accuracy * 10.f);
		offsetX = (System::random(scaledAccuracy * 2) - scaledAccuracy) / 10.f;
		offsetY = (System::random(scaledAccuracy * 2) - scaledAccuracy) / 10.f;
	}

	Locker wplocker(waypoint);
	waypoint->setPlanetCRC(targetZone.hashCode());
	waypoint->setPosition(target->getWorldPositionX() + offsetX, 0, target->getWorldPositionY() + offsetY);
	waypoint->setActive(true);
	wplocker.release();

	mission->updateMissionLocation();

	owner->sendSystemMessage("Target signal acquired.");
	owner->sendSystemMessage("Approximate location marked.");

	info(true) << "[AnonymousJediBounty] Waypoint generated hunter=" << owner->getObjectID()
		<< " target=" << target->getObjectID() << " mission=" << mission->getObjectID();

	trackingState = TRACKING_WAYPOINT;
	trackingToken++;
	trackingAuthorizationExpires = 0;

	Vector3 ownerPosition = owner->getWorldPosition();
	ownerPosition.setZ(0);
	Vector3 targetPosition = target->getWorldPosition();
	targetPosition.setZ(0);

	if (ownerPosition.distanceTo(targetPosition) <= missionManager->getAnonymousJediBountyConfirmationRange()) {
		uint64 duration = missionManager->getAnonymousJediBountyTrackingDuration();
		trackingAuthorizationExpires = Time().getMiliTime() + duration;
		trackingState = TRACKING_CONFIRMED;
		trackingLockX = target->getWorldPositionX();
		trackingLockY = target->getWorldPositionY();

		owner->addPersonalEnemyFlag(target, duration);

		Locker targetLocker(target);
		target->addPersonalEnemyFlag(owner, duration);
		targetLocker.release();

		owner->sendSystemMessage("Target confirmed.");
		owner->sendSystemMessage("Engagement authorized.");
		target->sendPvpStatusTo(owner);
		owner->sendPvpStatusTo(target);

		info(true) << "[AnonymousJediBounty] Target confirmation hunter=" << owner->getObjectID()
			<< " target=" << target->getObjectID() << " mission=" << mission->getObjectID();
		info(true) << "[AnonymousJediBounty] PvP authorization granted hunter=" << owner->getObjectID()
			<< " target=" << target->getObjectID() << " duration=" << duration
			<< " mission=" << mission->getObjectID();
	}

	if (trackingTask != nullptr && trackingTask->isScheduled())
		trackingTask->cancel();

	trackingTask = new BountyTrackingTask(_this.getReferenceUnsafeStaticCast(), trackingToken);
	trackingTask->schedule(5 * 1000);

	info(true) << "[AnonymousJediBounty] Droid consumedOnSuccess=" << (missionManager->getAnonymousJediBountyDroidConsumedOnSuccess() ? "true" : "false")
		<< " mission=" << mission->getObjectID();

	uint64 despawnDelay = missionManager->getAnonymousJediBountyDroidDespawnDelay();
	ManagedReference<AiAgent*> droidRef = trackingDroid;

	if (droidRef != nullptr) {
		Core::getTaskManager()->scheduleTask([droidRef] {
			if (droidRef == nullptr)
				return;

			Locker locker(droidRef);

			if (droidRef->isInQuadTree()) {
				droidRef->destroyObjectFromDatabase();
				droidRef->destroyObjectFromWorld(true);
			}
		}, "BountyTrackingDroidDespawn", despawnDelay);
	}

	info(true) << "[AnonymousJediBounty] Droid scan completed hunter=" << owner->getObjectID()
		<< " target=" << target->getObjectID() << " droid=" << (droidRef != nullptr ? droidRef->getObjectID() : (uint64)0)
		<< " mission=" << mission->getObjectID();

	droidScanState = DROID_COMPLETED;
	cleanupDroidTracking("Droid cleanup", false);
}

void BountyMissionObjectiveImplementation::handleTrackingDroidDestroyed(Observable* observable, ManagedObject* attacker) {
	if (droidScanState != DROID_DEPLOYING && droidScanState != DROID_SCANNING) {
		info(true) << "[AnonymousJediBounty] Duplicate callback prevented (droid destruction) state=" << droidScanState;
		return;
	}

	ManagedReference<MissionObject*> mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();
	ManagedReference<CreatureObject*> target = nullptr;

	if (mission != nullptr && owner != nullptr && owner->getZoneServer() != nullptr) {
		target = owner->getZoneServer()->getObject(mission->getTargetObjectId()).castTo<CreatureObject*>();
	}

	CreatureObject* attackerCreo = cast<CreatureObject*>(attacker);

	info(true) << "[AnonymousJediBounty] Droid destroyed hunter=" << (owner != nullptr ? owner->getObjectID() : (uint64)0)
		<< " target=" << (target != nullptr ? target->getObjectID() : (uint64)0)
		<< " attacker=" << (attackerCreo != nullptr ? attackerCreo->getObjectID() : (uint64)0)
		<< " droid=" << (trackingDroid != nullptr ? trackingDroid->getObjectID() : (uint64)0)
		<< " mission=" << (mission != nullptr ? mission->getObjectID() : (uint64)0);

	droidScanState = DROID_DESTROYED;
	droidLastDestroyedTime = Time().getMiliTime();

	MissionManager* missionManager = (owner != nullptr && owner->getZoneServer() != nullptr) ? owner->getZoneServer()->getMissionManager() : nullptr;

	if (owner != nullptr)
		owner->sendSystemMessage("Tracking droid destroyed. Target location could not be acquired.");

	if (target != nullptr)
		target->sendSystemMessage("Tracking droid destroyed. The bounty hunter has temporarily lost your signal.");

	info(true) << "[AnonymousJediBounty] Scan cancelled (destroyed) mission=" << (mission != nullptr ? mission->getObjectID() : (uint64)0);

	if (missionManager != nullptr) {
		info(true) << "[AnonymousJediBounty] Cooldown applied hunter=" << (owner != nullptr ? owner->getObjectID() : (uint64)0)
			<< " duration=" << missionManager->getAnonymousJediBountyDroidRelaunchCooldown()
			<< " consumedOnDestruction=" << (missionManager->getAnonymousJediBountyDroidConsumedOnDestruction() ? "true" : "false")
			<< " mission=" << (mission != nullptr ? mission->getObjectID() : (uint64)0);
	}

	cleanupDroidTracking("Droid destroyed", false);
}

void BountyMissionObjectiveImplementation::cleanupDroidTracking(const String& reason, bool notifyPlayer) {
	bool hadActiveState = trackingDroid != nullptr || droidScanState != DROID_IDLE;

	if (droidSpawnProtectionTask != nullptr && droidSpawnProtectionTask->isScheduled())
		droidSpawnProtectionTask->cancel();

	droidSpawnProtectionTask = nullptr;

	if (droidScanTask != nullptr && droidScanTask->isScheduled())
		droidScanTask->cancel();

	droidScanTask = nullptr;

	droidScanToken++;

	if (trackingDroid != nullptr) {
		ManagedReference<AiAgent*> droidRef = trackingDroid;
		ManagedReference<MissionObject*> mission = this->mission.get();
		ManagedReference<CreatureObject*> owner = getPlayerOwner();
		ManagedReference<CreatureObject*> target = nullptr;

		if (mission != nullptr && owner != nullptr && owner->getZoneServer() != nullptr) {
			target = owner->getZoneServer()->getObject(mission->getTargetObjectId()).castTo<CreatureObject*>();
		}

		if (droidObserver != nullptr) {
			droidRef->dropObserver(ObserverEventType::OBJECTDESTRUCTION, droidObserver);
			droidRef->dropObserver(ObserverEventType::DAMAGERECEIVED, droidObserver);
			dropObserver(droidObserver, true);
			droidObserver = nullptr;
		}

		if (target != nullptr) {
			Locker targetLocker(target);
			target->removePersonalEnemyFlag(droidRef);
			targetLocker.release();

			Locker droidLocker(droidRef);
			droidRef->removePersonalEnemyFlag(target);
			droidLocker.release();
		}

		// The success path (DROID_COMPLETED) already scheduled its own delayed despawn with an
		// independent reference; avoid destroying the droid out from under that pending task here.
		if (droidScanState != DROID_COMPLETED) {
			Locker droidLocker(droidRef);

			if (droidRef->isInQuadTree()) {
				droidRef->destroyObjectFromDatabase();
				droidRef->destroyObjectFromWorld(true);
			}

			droidLocker.release();
		}
	}

	trackingDroid = nullptr;
	droidScanState = DROID_IDLE;

	if (hadActiveState)
		info(true) << "[AnonymousJediBounty] Droid cleanup reason=\"" << reason << "\"";
}

bool BountyMissionObjectiveImplementation::authorizeTrackedPlayerTarget(CreatureObject* player) {
	Locker locker(&syncMutex);

	ManagedReference<MissionObject*> mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();

	if (player == nullptr || mission == nullptr || owner == nullptr || player->getObjectID() != owner->getObjectID() || !isPlayerTarget())
		return false;

	ZoneServer* zoneServer = owner->getZoneServer();
	if (zoneServer == nullptr)
		return false;

	MissionManager* missionManager = zoneServer->getMissionManager();
	if (missionManager == nullptr || !missionManager->hasPlayerBountyTargetInList(mission->getTargetObjectId())
			|| !missionManager->hasBountyHunterInPlayerBounty(mission->getTargetObjectId(), owner->getObjectID())) {
		clearTrackingData("Authorization cleanup", false);
		return false;
	}

	ManagedReference<CreatureObject*> target = zoneServer->getObject(mission->getTargetObjectId()).castTo<CreatureObject*>();

	if (target == nullptr || target->getZone() == nullptr || owner->getZone() == nullptr || !target->isOnline() || !owner->isOnline()) {
		clearTrackingData("Target unavailable", true);
		return false;
	}

	String targetZone = target->getZone()->getZoneName();
	String ownerZone = owner->getZone()->getZoneName();

	if (targetZone != ownerZone) {
		player->sendSystemMessage("@mission/mission_generic:target_not_on_planet");
		return false;
	}

	trackingPlanet = targetZone;

	info(true) << "[AnonymousJediBounty] Same-planet location scan hunter=" << owner->getObjectID()
		<< " target=" << target->getObjectID() << " planet=" << targetZone
		<< " mission=" << mission->getObjectID();

	return beginDroidTrackingScan(player, target);
}

void BountyMissionObjectiveImplementation::validateTrackingLock(uint64 token) {
	Locker locker(&syncMutex);

	if (token != trackingToken || trackingState < TRACKING_WAYPOINT)
		return;

	ManagedReference<MissionObject*> mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();

	if (mission == nullptr || owner == nullptr)
		return;

	ZoneServer* zoneServer = owner->getZoneServer();
	if (zoneServer == nullptr)
		return;

	MissionManager* missionManager = zoneServer->getMissionManager();
	if (missionManager == nullptr || !missionManager->hasPlayerBountyTargetInList(mission->getTargetObjectId())
			|| !missionManager->hasBountyHunterInPlayerBounty(mission->getTargetObjectId(), owner->getObjectID())) {
		clearTrackingData("Authorization cleanup", false);
		return;
	}

	ManagedReference<CreatureObject*> target = zoneServer->getObject(mission->getTargetObjectId()).castTo<CreatureObject*>();

	if (target == nullptr || target->getZone() == nullptr || owner->getZone() == nullptr || !target->isOnline() || !owner->isOnline()) {
		clearTrackingData("Target unavailable", true);
		return;
	}

	String targetZone = target->getZone()->getZoneName();
	String ownerZone = owner->getZone()->getZoneName();

	if (trackingPlanet != "" && trackingPlanet != targetZone) {
		clearTrackingData("Target changed planets", true);
		trackingPlanet = "";
		trackingState = TRACKING_UNKNOWN;
		info(true) << "[AnonymousJediBounty] Planet change hunter=" << owner->getObjectID()
			<< " target=" << target->getObjectID() << " planet=" << targetZone
			<< " mission=" << mission->getObjectID();
		return;
	}

	if (ownerZone != targetZone) {
		trackingTask = new BountyTrackingTask(_this.getReferenceUnsafeStaticCast(), trackingToken);
		trackingTask->schedule(5 * 1000);
		return;
	}

	Vector3 ownerPosition = owner->getWorldPosition();
	ownerPosition.setZ(0);
	Vector3 targetPosition = target->getWorldPosition();
	targetPosition.setZ(0);

	float distance = ownerPosition.distanceTo(targetPosition);
	uint64 now = Time().getMiliTime();

	if (trackingState == TRACKING_CONFIRMED) {
		if (trackingAuthorizationExpires > 0 && now >= trackingAuthorizationExpires) {
			clearTrackingData("Tracking authorization expired", true);
			info(true) << "[AnonymousJediBounty] Authorization cleanup hunter=" << owner->getObjectID()
				<< " target=" << target->getObjectID() << " mission=" << mission->getObjectID();
			return;
		}

		Vector3 lockPosition;
		lockPosition.setX(trackingLockX);
		lockPosition.setY(trackingLockY);
		lockPosition.setZ(0);

		float targetMovedDistance = targetPosition.distanceTo(lockPosition);

		if (targetMovedDistance > missionManager->getAnonymousJediBountyTrackingLossDistance()) {
			clearTrackingData("Tracking signal lost", true);
			info(true) << "[AnonymousJediBounty] Tracking lost hunter=" << owner->getObjectID()
				<< " target=" << target->getObjectID() << " distance=" << targetMovedDistance
				<< " mission=" << mission->getObjectID();
			return;
		}

		trackingTask = new BountyTrackingTask(_this.getReferenceUnsafeStaticCast(), trackingToken);
		trackingTask->schedule(5 * 1000);
		return;
	}

	if (distance <= missionManager->getAnonymousJediBountyConfirmationRange()) {
		uint64 duration = missionManager->getAnonymousJediBountyTrackingDuration();
		trackingAuthorizationExpires = now + duration;
		trackingState = TRACKING_CONFIRMED;
		trackingLockX = target->getWorldPositionX();
		trackingLockY = target->getWorldPositionY();

		Locker ownerLocker(owner);
		owner->addPersonalEnemyFlag(target, duration);
		ownerLocker.release();

		Locker targetLocker(target);
		target->addPersonalEnemyFlag(owner, duration);
		targetLocker.release();

		owner->sendSystemMessage("Target confirmed.");
		owner->sendSystemMessage("Engagement authorized.");
		target->sendPvpStatusTo(owner);
		owner->sendPvpStatusTo(target);

		info(true) << "[AnonymousJediBounty] Target confirmation hunter=" << owner->getObjectID()
			<< " target=" << target->getObjectID() << " mission=" << mission->getObjectID();
		info(true) << "[AnonymousJediBounty] PvP authorization granted hunter=" << owner->getObjectID()
			<< " target=" << target->getObjectID() << " duration=" << duration
			<< " mission=" << mission->getObjectID();
	}

	trackingTask = new BountyTrackingTask(_this.getReferenceUnsafeStaticCast(), trackingToken);
	trackingTask->schedule(5 * 1000);
}

void BountyMissionObjectiveImplementation::clearTrackingData(const String& reason, bool notifyPlayer) {
	cleanupDroidTracking(reason, false);

	ManagedReference<MissionObject*> mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();
	ManagedReference<CreatureObject*> target = nullptr;

	if (mission != nullptr && owner != nullptr && owner->getZoneServer() != nullptr) {
		target = owner->getZoneServer()->getObject(mission->getTargetObjectId()).castTo<CreatureObject*>();
	}

	if (trackingTask != nullptr && trackingTask->isScheduled())
		trackingTask->cancel();

	trackingTask = nullptr;
	trackingToken++;

	if (mission != nullptr) {
		WaypointObject* waypoint = mission->getWaypointToMission();
		if (waypoint != nullptr) {
			Locker wplocker(waypoint);
			waypoint->setActive(false);
		}
	}

	if (owner != nullptr && target != nullptr) {
		Locker ownerLocker(owner);
		owner->removePersonalEnemyFlag(target);
		ownerLocker.release();

		Locker targetLocker(target);
		target->removePersonalEnemyFlag(owner);
		targetLocker.release();
	}

	if (notifyPlayer && owner != nullptr) {
		owner->sendSystemMessage(reason);
		owner->sendSystemMessage("Deploy another Arakyd Droid to reacquire the target.");
	}

	if ((reason == "Tracking signal lost" || reason == "Authorization cleanup" || reason == "Tracking authorization expired") && trackingPlanet != "") {
		trackingState = TRACKING_PLANET_KNOWN;
	} else {
		trackingPlanet = "";
		trackingState = TRACKING_UNKNOWN;
	}

	trackingAuthorizationExpires = 0;
	trackingLockX = 0;
	trackingLockY = 0;
	info(true) << "[AnonymousJediBounty] Authorization cleanup reason=\"" << reason << "\" mission=" << (mission != nullptr ? mission->getObjectID() : (uint64)0);
}

bool BountyMissionObjectiveImplementation::hasTrackingAuthorization(CreatureObject* hunter, CreatureObject* target) {
	if (hunter == nullptr || target == nullptr || trackingState != TRACKING_CONFIRMED)
		return false;

	ManagedReference<MissionObject*> mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();

	if (mission == nullptr || owner == nullptr)
		return false;

	if (owner->getObjectID() != hunter->getObjectID() || mission->getTargetObjectId() != target->getObjectID())
		return false;

	if (trackingAuthorizationExpires > 0 && Time().getMiliTime() >= trackingAuthorizationExpires)
		return false;

	return hunter->hasPersonalEnemyFlag(target) && target->hasPersonalEnemyFlag(hunter);
}

void BountyMissionObjectiveImplementation::handleNpcTargetKilled(Observable* observable) {
	CreatureObject* target =  cast<CreatureObject*>(observable);
	ManagedReference<CreatureObject*> owner = getPlayerOwner();

	if (owner == nullptr || target == nullptr)
		return;

	SceneObject* targetInventory = target->getSlottedObject("inventory");

	if (targetInventory == nullptr)
		return;

	uint64 lootOwnerID = targetInventory->getContainerPermissions()->getOwnerID();
	GroupObject* group = owner->getGroup();

	if (lootOwnerID == owner->getObjectID() || (group != nullptr && lootOwnerID == group->getObjectID())) {
		//Target killed by player, complete mission.
		complete();
	} else {
		//Target killed by other player, fail mission.
		owner->sendSystemMessage("@mission/mission_generic:failed"); // Mission failed
		abort();
		removeMissionFromPlayer();
	}
}

int BountyMissionObjectiveImplementation::handleNpcTargetReceivesDamage(ManagedObject* arg1) {
	CreatureObject* target = nullptr;

	target = cast<CreatureObject*>(arg1);

	ManagedReference<MissionObject* > mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();

	if (mission != nullptr && owner != nullptr && target != nullptr && target->getFirstName() == owner->getFirstName() &&
			target->isPlayerCreature() && objectiveStatus == HASBIOSIGNATURESTATUS) {
		updateMissionStatus(mission->getMissionLevel());

		String diffString = "easy";
		if (mission->getMissionLevel() == 3) {
			diffString = "hard";
		} else if (mission->getMissionLevel() == 2) {
			diffString = "medium";
		}

		target->getZoneServer()->getChatManager()->broadcastChatMessage(npcTarget, "@mission/mission_bounty_neutral_" + diffString + ":m" + String::valueOf(mission->getMissionNumber()) + "v", 0, 0, npcTarget->getMoodID());
		return 1;
	}

	return 0;
}

void BountyMissionObjectiveImplementation::handlePlayerKilled(ManagedObject* arg1, uint64 destructedID) {
	if (completedMission)
		return;

	CreatureObject* creo = cast<CreatureObject*>(arg1);

	if (creo == nullptr)
		return;

	CreatureObject* killer = nullptr;

	if (creo->isPet())
		killer = creo->getLinkedCreature().get();
	else
		killer = creo;

	if (killer == nullptr)
		return;

	ManagedReference<MissionObject*> mission = this->mission.get();
	ManagedReference<CreatureObject*> owner = getPlayerOwner();

	if (mission == nullptr || owner == nullptr)
		return;

	uint64 targetID = mission->getTargetObjectId();
	uint64 ownerID = owner->getObjectID();
	uint64 killerID = killer->getObjectID();

	if (destructedID == ownerID) {
		clearTrackingData("Tracking signal lost", false);
		info(true) << "[AnonymousJediBounty] Tracking lost hunter death hunter=" << ownerID
			<< " target=" << targetID << " mission=" << mission->getObjectID();
	}

	// Player died to DoT
	if (killerID == destructedID)
		return;

	// info(true) << "BountyMissionObjectiveImplementation::handlePlayerKilled -- Owner: " << ownerID << " Killer: " << killerID << " Mission Target ID: " << targetID << " Destructed ID: " << destructedID;

	// Fail Mission if the target killed the owner
	if (killerID == targetID && ownerID != killerID) {
		owner->sendSystemMessage("@mission/mission_generic:failed"); // Mission failed

		if (killer->isPlayerCreature())
			killer->sendSystemMessage("You have defeated a bounty hunter, ruining his mission against you!");

		fail();

		return;
	}

	// Killer must be the mission owner to return succesful
	if (killerID != ownerID)
		return;

	// Target killed by player, complete mission.
	ZoneServer* zoneServer = owner->getZoneServer();

	if (zoneServer == nullptr)
		return;

	ManagedReference<CreatureObject*> target = zoneServer->getObject(mission->getTargetObjectId()).castTo<CreatureObject*>();

	if (target == nullptr)
		return;

	int minXpLoss = -50000;
	int maxXpLoss = -500000;

	VisibilityManager::instance()->clearVisibility(target);
	int rewardCreds = mission->getRewardCredits() + mission->getBonusCredits();
	int xpLoss = rewardCreds * -2;

	if (xpLoss > minXpLoss)
		xpLoss = minXpLoss;
	else if (xpLoss < maxXpLoss)
		xpLoss = maxXpLoss;

	auto playerManager = zoneServer->getPlayerManager();

	if (playerManager != nullptr)
		playerManager->awardExperience(target, "jedi_general", xpLoss, true);

	StringIdChatParameter message("base_player", "prose_revoke_xp");
	message.setDI(xpLoss * -1);
	message.setTO("exp_n", "jedi_general");
	target->sendSystemMessage(message);

	// 24-hour visibility grace period for Jedi Padawans killed by a Bounty Hunter
	if (target->hasSkill("force_title_jedi_rank_02") && !target->hasSkill("force_title_jedi_rank_03")) {
		PlayerObject* targetGhost = target->getPlayerObject();
		if (targetGhost != nullptr) {
			uint64 graceEnd = Time().getMiliTime() + (24ULL * 60 * 60 * 1000);
			Locker ghostLocker(targetGhost);
			targetGhost->setScreenPlayData("BGBHKill", "visGraceEnd", String::valueOf(graceEnd));
		}
		target->sendSystemMessage("You have been slain by a Bounty Hunter. Your Force presence will remain dormant for 24 hours.");
	}

	complete();
}
