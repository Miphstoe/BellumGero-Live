/*
 				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

/**
 * AreaTrackTask.h
 *
 *  Created: Sat Feb 5
 *   Author: Kyle
 *
 */

#ifndef AREATRACKTASK_H_
#define AREATRACKTASK_H_

#include "server/zone/objects/player/sui/callbacks/AreaTrackResultsSuiCallback.h"

class AreaTrackTask: public Task {
	ManagedReference<CreatureObject*> player;
	int type;
	Coordinate initialPosition;

public:
	AreaTrackTask(CreatureObject* cr, int index) {
		player = cr;
		type = index;
		Vector3 worldPosition = player->getWorldPosition();
		initialPosition.setPosition(worldPosition.getX(), worldPosition.getZ(), worldPosition.getY());
	}

	void run() {
		Locker locker(player);

		try {

			player->removePendingTask("areatrack");

			if (!player->isPlayerCreature())
				return;

			Zone* zone = player->getZone();
			if (zone == nullptr)
				return;

			if (player->getDistanceTo(&initialPosition) > 1) {
				player->sendSystemMessage("@skl_use:sys_scan_moved"); // Your attempt to gather information has been disrupted by moving around too much.
				return;
			}

			if (player->isInCombat()) {
				player->sendSystemMessage("@skl_use:sys_scan_combat"); // Your attempt to gather information has been disrupted by combat!
				return;
			}

			if (type > AreaTrackResultsSuiCallback::getMaxTrackType(player)) {
				return;
			}

			ManagedReference<PlayerObject*> ghost = player->getPlayerObject();
			if (ghost == nullptr)
				return;

			// A new search invalidates any older, still-open results window.
			ghost->closeSuiWindowType(SuiWindowType::RANGER_TRACK_RESULTS);

			ManagedReference<SuiListBox*> rangerTrackResults = new SuiListBox(player, SuiWindowType::RANGER_TRACK_RESULTS);
			Reference<AreaTrackResultsSuiCallback*> resultsCallback = new AreaTrackResultsSuiCallback(player->getZoneServer(), type);

			rangerTrackResults->setPromptTitle("@skl_use:scan_results_t"); // Area Track Results
			rangerTrackResults->setPromptText("You have examined the tracks and clues in the area for information about what kinds of creatures might be nearby. This is what you have determined.\n\nSelect a result and press Mark to place a tracking waypoint at its current location. These results expire in 60 seconds.");
			rangerTrackResults->setCallback(resultsCallback);
			rangerTrackResults->setOkButton(true, "Mark");
			rangerTrackResults->setCancelButton(true, "@cancel");
			StringBuffer results;

			bool canGetDirection = player->hasSkill("outdoors_ranger_harvest_01");
		    bool canGetDistance = player->hasSkill("outdoors_ranger_harvest_03");
			bool canGetLevel = player->hasSkill("outdoors_ranger_master");

			// World position so the scan centres correctly when tracking from a mount or vehicle.
			Vector3 worldPosition = player->getWorldPosition();
			ManagedReference<SceneObject*> mount = player->isRidingMount() ? player->getParent().get() : nullptr;

			SortedVector<ManagedReference<TreeEntry*> > objects(512, 512);
			zone->getInRangeObjects(worldPosition.getX(), worldPosition.getZ(), worldPosition.getY(), 1024, &objects, true);

			for (int i = 0; i < objects.size(); ++i) {
				SceneObject* object = static_cast<SceneObject*>(objects.get(i).get());
				results.deleteAll();

				if(object == player || object == mount || !object->isCreatureObject()) {
					continue;
				}

				CreatureObject* creature = cast<CreatureObject*>(object);
				if(!AreaTrackResultsSuiCallback::isTrackableType(creature, type))
					continue;

				results << creature->getDisplayedName();

				// Master Rangers read creature/NPC levels; never shown for player targets.
				if(canGetLevel && !creature->isPlayerCreature()) {
					int level = creature->getLevel();
					results << " - Level " << level;

					if(level >= 300)
						results << " \\#FF3333[HIGH THREAT]\\#.";
				}

				String direction = "", distance = "";

				if(canGetDirection)
					direction = getDirection(player, creature);
				if(canGetDistance)
					distance = getDistance(player, creature);

				if(!distance.isEmpty() || !direction.isEmpty()) {
					results << " (" << direction << distance << ")";
				}

				rangerTrackResults->addMenuItem(results.toString(), creature->getObjectID());
				resultsCallback->addTarget(creature->getObjectID());
			}

			if(rangerTrackResults->getMenuSize() == 0) {
				player->sendSystemMessage("@skl_use:sys_scan_nothing"); // You aren't able to determine anything from the tracks in the area.
			} else {
				ghost->addSuiBox(rangerTrackResults);
				player->sendMessage(rangerTrackResults->generateMessage());
			}

		} catch (Exception& e) {
			player->error("unreported exception caught in AreaTrackTask::run()");
		}
	}

	String getDirection(CreatureObject* tracker, CreatureObject* trackee) {
		String direction;
		auto trackeeWorldPosition = trackee->getWorldPosition();
		auto trackerWorldPosition = tracker->getWorldPosition();

		float trackerX = trackerWorldPosition.getX();
		float trackerY = trackerWorldPosition.getY();
		float trackeeX = trackeeWorldPosition.getX();
		float trackeeY = trackeeWorldPosition.getY();

		// transform points so the origin is the tracker's position
		float transformedX = trackeeX - trackerX;
		float transformedY = trackeeY - trackerY;

		// normalize the transformed points which will give us points on the unit circle
		// in the direction of the trackee
		float length = sqrt(transformedX * transformedX + transformedY * transformedY);
		if(length > 0) {
			float pointOnUnitCircleX = transformedX / length;
			float pointOnUnitCircleY = transformedY / length;

			// inverse cos of the pointOnUnitCircleX will give the angle
			float directionAngleInDegrees = ((float)acos(pointOnUnitCircleX) * 180) / M_PI;

			// if the point is in the 3rd or 4th quadrant, 360 - directionAngleInDegrees will give the correct angle value
			// with the origin at (1,0) on the unit circle
			if(pointOnUnitCircleY < 0)
				directionAngleInDegrees = 360 - directionAngleInDegrees;

			if((directionAngleInDegrees >= 0 && directionAngleInDegrees <= 22.5) || (directionAngleInDegrees >= 337.5 && directionAngleInDegrees <= 360))
				direction = "east";
			else if(directionAngleInDegrees >= 22.5 && directionAngleInDegrees <= 67.5)
				direction = "northeast";
			else if(directionAngleInDegrees >= 67.5 && directionAngleInDegrees <= 112.5)
				direction = "north";
			else if(directionAngleInDegrees >= 112.5 && directionAngleInDegrees <= 157.5)
				direction = "northwest";
			else if(directionAngleInDegrees >= 157.5 && directionAngleInDegrees <= 202.5)
				direction = "west";
			else if(directionAngleInDegrees >= 202.5 && directionAngleInDegrees <= 247.5)
				direction = "southwest";
			else if(directionAngleInDegrees >= 247.5 && directionAngleInDegrees <= 292.5)
				direction = "south";
			else if(directionAngleInDegrees >= 292.5 && directionAngleInDegrees <= 337.5)
				direction = "southeast";
			else
				direction = "Error: Report this to Kyle Please";
		} else {
			direction = "north";  // this is for trackees that have the same position as the tracker's position
		}

		return direction;
	}

	String getDistance(CreatureObject* tracker, CreatureObject* trackee) {
		int distance = (int)tracker->getDistanceTo(trackee);

		StringBuffer strBuffer;
		strBuffer << " " << distance << "m";
		String result = strBuffer.toString();
		return result;
	}
};

#endif /* AREATRACKTASK_H_ */
