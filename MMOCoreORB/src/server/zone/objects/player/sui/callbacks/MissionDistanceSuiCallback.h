/*
 * MissionDistanceSuiCallback.h
 *
 * Callback for the "Filter Missions by Distance" mission terminal SUI
 * (see MissionTerminalImplementation.cpp, radial ID 117). This is a display
 * filter, not an accept action: it stores the player's chosen distance
 * bracket (see MissionDistanceFilter.h) and triggers the same mission-list
 * refresh the client's native Refresh uses, so mission generation itself
 * only leaves matching missions in the player's mission_bag. The existing
 * "Accept Top 6 Missions" feature is untouched and automatically operates on
 * whatever the filter left behind.
 */

#ifndef MISSIONDISTANCESUICALLBACK_H_
#define MISSIONDISTANCESUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/tangible/terminal/mission/MissionTerminal.h"
#include "server/zone/managers/mission/MissionDistanceFilter.h"
#include "server/zone/managers/mission/MissionManager.h"
#include "server/zone/objects/mission/MissionObject.h"
#include "templates/faction/Factions.h"
#include "system/lang/Time.h"

class MissionDistanceSuiCallback: public SuiCallback {

public:
	MissionDistanceSuiCallback(ZoneServer* serv) : SuiCallback(serv) {

	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (!suiBox->isListBox() || cancelPressed)
			return;

		if (args->size() < 1)
			return;

		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();
		if (object == nullptr || !object->isMissionTerminal())
			return;

		int index = Integer::valueOf(args->get(0).toString());

		// 0-4 are the distance brackets, 5 is the "Any Distance" clear option
		if (index < 0 || index > MISSION_DISTANCE_RANGE_COUNT)
			return;

		MissionTerminal* terminal = cast<MissionTerminal*>(object.get());
		if (terminal == nullptr)
			return;

		Locker _lock(terminal, player);

		bool clearingFilter = (index == MISSION_DISTANCE_RANGE_COUNT);

		MissionDistanceFilterState state;
		if (!clearingFilter) {
			const MissionDistanceRangeEntry& range = MISSION_DISTANCE_RANGES[index];
			state.enabled = true;
			state.minDistance = range.minDistance;
			state.maxDistance = range.maxDistance;
		}

		writeMissionDistanceFilter(player, state);

		if (clearingFilter)
			player->sendSystemMessage("Distance filter cleared.");
		else
			player->sendSystemMessage("Distance filter set to " + String(MISSION_DISTANCE_RANGES[index].label) + ".");

		MissionManager* missionManager = server->getMissionManager();
		if (missionManager == nullptr)
			return;

		int counter = (int) Time().getTime();
		missionManager->handleMissionListRequest(terminal, player, counter);

		if (!clearingFilter)
			warnIfNoMissionsMatched(terminal, player);
	}

private:
	// The filter is applied silently during generation, so if it just produced zero
	// matching missions, the player needs explicit feedback rather than an empty list.
	void warnIfNoMissionsMatched(MissionTerminal* terminal, CreatureObject* player) {
		SceneObject* missionBag = player->getSlottedObject("mission_bag");
		if (missionBag == nullptr)
			return;

		uint32 expectedFaction = Factions::FACTIONNEUTRAL;
		if (terminal->isImperialTerminal())
			expectedFaction = Factions::FACTIONIMPERIAL;
		else if (terminal->isRebelTerminal())
			expectedFaction = Factions::FACTIONREBEL;

		for (int i = 0; i < missionBag->getContainerObjectsSize(); ++i) {
			SceneObject* obj = missionBag->getContainerObject(i);
			if (obj == nullptr || !obj->isMissionObject())
				continue;

			MissionObject* mission = cast<MissionObject*>(obj);
			if (mission != nullptr && mission->getTypeCRC() != 0 && mission->getFaction() == expectedFaction)
				return;
		}

		player->sendSystemMessage("No missions were found within the selected distance range. Try another range or refresh the terminal.");
	}
};

#endif /* MISSIONDISTANCESUICALLBACK_H_ */
