/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

/**
 * AreaTrackResultsSuiCallback.h
 *
 * Handles selection of an entry in the Area Track Results window and
 * places a single static Ranger tracking waypoint at the target's position.
 *
 * The result set (object IDs, track type, creation time) lives only in this
 * callback, which is attached to the one-shot results SuiBox. SuiManager
 * removes the box before running the callback, so a response can be used at
 * most once, and a box closed or replaced by a newer search is gone entirely.
 */

#ifndef AREATRACKRESULTSSUICALLBACK_H_
#define AREATRACKRESULTSSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/zone/Zone.h"

class AreaTrackResultsSuiCallback : public SuiCallback {
	int type;
	Time created;
	Vector<uint64> targetIDs;

public:
	static const int RESULT_LIFETIME_MS = 60000;
	static constexpr float MAX_WAYPOINT_RANGE = 2048.f;

	enum {
		TRACKABLE = 0,
		NOT_TRACKABLE,
		TARGET_GONE,
		TARGET_DEAD,
		TARGET_OTHER_PLANET,
		TARGET_OUT_OF_RANGE,
		TARGET_INDOORS
	};

	AreaTrackResultsSuiCallback(ZoneServer* serv, int trackType) : SuiCallback(serv) {
		type = trackType;
	}

	void addTarget(uint64 objectID) {
		targetIDs.add(objectID);
	}

	// Highest track type (0 animal, 1 npc, 2 player) the tracker is currently trained for.
	static int getMaxTrackType(CreatureObject* tracker) {
		if (tracker->hasSkill("outdoors_ranger_harvest_04"))
			return 2;

		if (tracker->hasSkill("outdoors_ranger_harvest_02"))
			return 1;

		return 0;
	}

	// Existing Area Track eligibility rules, shared by the results scan and the selection re-check.
	static bool isTrackableType(CreatureObject* creature, int trackType) {
		if (creature == nullptr || creature->isInvisible())
			return false;

		if (trackType == 0) {
			if (!creature->isCreature())
				return false;
			if (creature->isDroidSpecies() || creature->isWalkerSpecies())
				return false;
		} else if (trackType == 1) {
			if (!creature->isNonPlayerCreatureObject())
				return false;
			if (creature->isVendor() || creature->isProbotSpecies())
				return false;
		} else if (trackType == 2) {
			if (!creature->isPlayerCreature())
				return false;
		} else {
			return false;
		}

		return true;
	}

	static int validateTarget(CreatureObject* tracker, CreatureObject* target, int trackType) {
		if (target == nullptr || target == tracker)
			return TARGET_GONE;

		Zone* zone = target->getZone();

		if (zone == nullptr)
			return TARGET_GONE;

		if (zone != tracker->getZone())
			return TARGET_OTHER_PLANET;

		if (target->isDead())
			return TARGET_DEAD;

		if (!isTrackableType(target, trackType))
			return NOT_TRACKABLE;

		ManagedReference<SceneObject*> parent = target->getParent().get();

		if (parent != nullptr && parent->isCellObject())
			return TARGET_INDOORS;

		if (tracker->getWorldPosition().distanceTo2d(target->getWorldPosition()) > MAX_WAYPOINT_RANGE)
			return TARGET_OUT_OF_RANGE;

		return TRACKABLE;
	}

	void run(CreatureObject* player, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (!sui->isListBox() || cancelPressed || args == nullptr || args->size() < 1)
			return;

		if (!player->isPlayerCreature() || server == nullptr)
			return;

		ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return;

		if (created.miliDifference() > RESULT_LIFETIME_MS) {
			player->sendSystemMessage("These tracking results have expired. Perform Area Tracking again.");
			return;
		}

		int index = Integer::valueOf(args->get(0).toString());

		if (index < 0 || index >= targetIDs.size())
			return;

		if (!player->hasSkill("outdoors_ranger_novice") || type > getMaxTrackType(player))
			return;

		Zone* zone = player->getZone();

		if (zone == nullptr)
			return;

		ManagedReference<SceneObject*> object = server->getObject(targetIDs.get(index));
		CreatureObject* target = nullptr;

		if (object != nullptr && object->isCreatureObject())
			target = object->asCreatureObject();

		switch (validateTarget(player, target, type)) {
		case TRACKABLE:
			break;
		case TARGET_OUT_OF_RANGE:
			player->sendSystemMessage("Tracking failed: Target is outside tracking range.");
			return;
		case TARGET_INDOORS:
		case NOT_TRACKABLE:
			player->sendSystemMessage("Tracking failed: Target is no longer detectable.");
			return;
		default:
			player->sendSystemMessage("Tracking failed: Target is no longer available.");
			return;
		}

		String targetName = target->getDisplayedName();
		Vector3 position = target->getWorldPosition();

		ManagedReference<WaypointObject*> waypoint = server->createObject(0xc456e788, 1).castTo<WaypointObject*>(); // object/waypoint/base/shared_base_waypoint.iff

		if (waypoint == nullptr) {
			player->sendSystemMessage("Tracking failed: Unable to create waypoint.");
			return;
		}

		Locker locker(waypoint);

		waypoint->setPlanetCRC(zone->getZoneName().hashCode());
		waypoint->setPosition(position.getX(), 0, position.getY());
		waypoint->setCustomObjectName("Tracking: " + targetName, false);
		waypoint->setSpecialTypeID(WaypointObject::SPECIALTYPE_RANGERTRACK);
		waypoint->setActive(true);

		// checkName = false: only the previous SPECIALTYPE_RANGERTRACK waypoint is replaced, never a same-named personal one.
		ghost->addWaypoint(waypoint, false, true);

		player->sendSystemMessage("Tracking waypoint created: " + targetName);
	}
};

#endif /* AREATRACKRESULTSSUICALLBACK_H_ */
