/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#include "VisibilityManager.h"
#include "server/zone/managers/mission/MissionManager.h"
#include "server/zone/managers/collision/CollisionManager.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/managers/visibility/tasks/VisibilityDecayTask.h"
#include "server/zone/Zone.h"
#include "server/zone/managers/director/DirectorManager.h"
#include "conf/ConfigManager.h"

const String VisibilityManager::factionStringRebel = "rebel";
const String VisibilityManager::factionStringImperial = "imperial";
const unsigned int VisibilityManager::factionRebel = STRING_HASHCODE("rebel");
const unsigned int VisibilityManager::factionImperial = STRING_HASHCODE("imperial");

float VisibilityManager::calculateVisibilityIncrease(CreatureObject* creature) {
	Zone* zone = creature->getZone();

	float visibilityIncrease = 0;

	if (zone == nullptr)
		return visibilityIncrease;


	SortedVector<TreeEntry*> closeObjects;
	CloseObjectsVector* closeObjectsVector = (CloseObjectsVector*) creature->getCloseObjects();
	if (closeObjectsVector == nullptr) {
		zone->getInRangeObjects(creature->getWorldPositionX(), creature->getWorldPositionZ(), creature->getWorldPositionY(), 32, &closeObjects, true);
	} else {
		closeObjectsVector->safeCopyReceiversTo(closeObjects, CloseObjectsVector::CREOTYPE);
	}

	bool disableGroupVis = ConfigManager::instance()->getBool("Core3.PlayerManager.DisableGroupVisibility", false);

	for (int i = 0; i < closeObjects.size(); ++i) {
		SceneObject* obj = static_cast<SceneObject*>(closeObjects.get(i));

		if (obj == nullptr)
			continue;

		if (obj->getObjectID() == creature->getObjectID())
			continue;

		CreatureObject* c = obj->asCreatureObject();

		if (c == nullptr || (!c->isNonPlayerCreatureObject() && !c->isPlayerCreature()))
			continue;

		if (c->isDead() || c->isIncapacitated() || (c->isPlayerCreature() && c->getPlayerObject()->hasGodMode()))
			continue;

		if (disableGroupVis && creature->isGrouped()) {
			ManagedReference<GroupObject*> group = creature->getGroup();

			if (group != nullptr && group->hasMember(c))
				continue;
		}

		if (!creature->isInRange(c, 32) || !CollisionManager::checkLineOfSight(creature, c))
			continue;

		if (creature->getFaction() == 0 || (c->getFaction() != factionImperial && c->getFaction() != factionRebel)) {
			visibilityIncrease += 0.5;
			//info(c->getCreatureName().toString() + " generating a 0.5 visibility modifier", true);
		} else {
			if (creature->getFaction() == c->getFaction()) {
				visibilityIncrease += 0.25;
				//info(c->getCreatureName().toString() + " generating a 0.25 visibility modifier", true);
			} else {
				visibilityIncrease += 1;
				//info( c->getCreatureName().toString() + " generating a 1.0 visibility modifier", true);
			}
		}

	}

	//info("Increasing visibility for player " + String::valueOf(creature->getObjectID()) + " with " + String::valueOf(visibilityIncrease), true);
	return visibilityIncrease;
}

void VisibilityManager::decreaseVisibility(CreatureObject* creature) {

	Reference<PlayerObject*> ghost = creature->getSlottedObject("ghost").castTo<PlayerObject*>();

	if (ghost != nullptr) {
		Locker locker(ghost);
		if (ghost->getVisibility() > 0)
		{

			//info("VisDecayTickRate: " + String::valueOf(visDecayTickRate) + " DecayPerTick: " + String::valueOf(visDecayPerTick), true);
			float visibilityDecrease = (((ghost->getLastVisibilityUpdateTimestamp().miliDifference() / 1000.0f) / visDecayTickRate) * visDecayPerTick);

			//info("Decreasing visibility of player " + creature->getFirstName() + " by " + String::valueOf(visibilityDecrease), true);
			if (ghost->getVisibility() <= visibilityDecrease) {
				clearVisibility(creature);
			} else {
				ghost->setVisibility(ghost->getVisibility() - visibilityDecrease);
			}
		}
	}
}

VisibilityManager::VisibilityManager() : Logger("VisibilityManager") {
	loadConfiguration();

	Reference<Task*> decayTask = new VisibilityDecayTask();
	decayTask->schedule(visDecayTickRate * 1000);
}

void VisibilityManager::addToVisibilityList(CreatureObject* creature) {
	//info("Logging in " + creature->getFirstName(), true);
	Reference<PlayerObject*> ghost = creature->getSlottedObject("ghost").castTo<PlayerObject*>();

	if (ghost != nullptr) {
		decreaseVisibility(creature);

		Locker locker(&visibilityListLock);

		if ((ghost->getVisibility() > 0) && (!visibilityList.contains(creature->getObjectID()))) {
			//info("Adding player " + String::valueOf(creature->getObjectID()) + " to visibility list.", true);
			visibilityList.put(creature->getObjectID(), creature);
		}

		locker.release();
	}
}

float VisibilityManager::getTerminalVisThreshold() {
	return terminalVisThreshold;
}

void VisibilityManager::removeFromVisibilityList(CreatureObject* creature) {
	//info("Logging out " + creature->getFirstName(), true);
	Locker locker(&visibilityListLock);

	if (visibilityList.contains(creature->getObjectID())) {
		//info("Dropping player " + String::valueOf(creature->getObjectID()) + " from visibility list.", true);
		visibilityList.drop(creature->getObjectID());
	}
}

void VisibilityManager::increaseVisibility(CreatureObject* creature, int visibilityMultiplier) {
	// Existing behavior: adjust player ghost visibility and keep them in the list
	Reference<PlayerObject*> ghost = creature->getSlottedObject("ghost").castTo<PlayerObject*>();

	float baseVis = 0.f;
	float newVis  = 0.f;

	if (ghost != nullptr && !ghost->hasGodMode()) {
		Locker locker(ghost);

		// Your current tick decay before increase
		decreaseVisibility(creature);

		baseVis = ghost->getVisibility();

		float addVis = calculateVisibilityIncrease(creature) * visibilityMultiplier;
		newVis = Math::min(maxVisibility, baseVis + addVis);

		ghost->setVisibility(newVis);
		// info("New visibility for " + creature->getFirstName() + " is " + String::valueOf(ghost->getVisibility()), true);

		locker.release();

		addToVisibilityList(creature);
	}

	// ---- Threshold gating + once-per-hour C++ gate ----
	if (!creature->isPlayerCreature())
		return;

	// Read the threshold from config; default to 1500 if not set
	// Add to your server config (e.g., core3 config) as:
	// JediKnightEncounterVisibilityThreshold=1500
	const int threshold = ConfigManager::instance()->getInt("JediKnightEncounterVisibilityThreshold", 1500);

	// Recommended behavior: eligible whenever newVis is at/above the threshold
	bool eligible = (newVis >= threshold);

	// If you prefer edge-only (only on crossing upward), replace the line above with:
	// bool eligible = (baseVis < threshold && newVis >= threshold);

	if (!eligible)
		return;

	// Per-player 1-hour gate (to avoid repeated Lua calls)
	uint64 oid = creature->getObjectID();
	uint64 now = (uint64) time(nullptr);
	const uint64 ONE_HOUR = 60 * 60;

	{
		Locker guard(&jkvNextAllowedLock);

		uint64* nextPtr = jkvNextAllowed.get(oid);
		uint64 nextAllowed = nextPtr == nullptr ? 0 : *nextPtr;

		if (now < nextAllowed) {
			return; // still on cooldown; don't call Lua
		}

		// Arm cooldown BEFORE Lua call to avoid re-entrancy/double-fires
		jkvNextAllowed.put(oid, now + ONE_HOUR);
	}

	// Call the screenplay hook (same pattern as PlayerTriggers/HelperDroid)
	Lua* lua = DirectorManager::instance()->getLuaInstance();
	if (lua == nullptr)
		return;

	Reference<LuaFunction*> onVis = lua->createFunction("JediKnightVisibilityEncounter", "onVisibilityIncreased", 0);
	if (onVis == nullptr)
		return;

	*onVis << creature;     // pass CreatureObject* to Lua
	onVis->callFunction();  // Lua will enforce login grace + Knight skill and spawn the encounter
}

void VisibilityManager::clearVisibility(CreatureObject* creature) {
	Reference<PlayerObject*> ghost = creature->getSlottedObject("ghost").castTo<PlayerObject*>();

	if (ghost != nullptr  && !ghost->hasGodMode()) {
		//info("Clearing visibility for player " + String::valueOf(creature->getObjectID()), true);

		Locker locker(ghost);
		ghost->setVisibility(0);
		locker.release();

		removeFromVisibilityList(creature);
	}
}

void VisibilityManager::performVisiblityDecay() {
	//info("Performing visibility decay (List Size: " + String::valueOf(visibilityList.size()) +")", true);
	Locker locker(&visibilityListLock);

	for (int i = 0; i < visibilityList.size(); i++) {
		ManagedReference<CreatureObject*> creature = visibilityList.get(i);
		decreaseVisibility(creature);
	}
}

void VisibilityManager::loadConfiguration() {
	try {

		Lua* lua = new Lua();
		lua->init();

		lua->runFile("scripts/managers/jedi/visibility_manager.lua");

		maxVisibility  = (float)lua->getGlobalInt(String("maxVisibility"));
		terminalVisThreshold = (float)lua->getGlobalInt(String("termThreshold"));
		falloffThreshold = (float)lua->getGlobalInt(String("falloffThreshold"));
		pvpRatingDivisor = (float)lua->getGlobalInt(String("pvpRatingDivisor"));

		totalDecayTimeInDays = lua->getGlobalInt(String("totalDecayTimeInDays"));
		visDecayTickRate = lua->getGlobalInt(String("tickRateInSeconds"));

		visDecayPerTick = (maxVisibility / ((totalDecayTimeInDays * (float)(60*60*24) / visDecayTickRate)));

		delete lua;

	} catch (Exception& e) {
		error(e.getMessage());
	}
}

