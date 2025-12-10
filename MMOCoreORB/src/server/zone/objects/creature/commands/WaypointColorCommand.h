/*
 * WaypointColorCommand.h
 *
 * Command to change waypoint colors via SUI dialog
 * Usage: /waypointcolor
 */

#ifndef WAYPOINTCOLORCOMMAND_H_
#define WAYPOINTCOLORCOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/callbacks/DatapadWaypointListSuiCallback.h"

class WaypointColorCommand : public QueueCommand {
public:
	WaypointColorCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature)) {
			return INVALIDSTATE;
		}

		if (!checkInvalidLocomotions(creature)) {
			return INVALIDLOCOMOTION;
		}

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

		if (ghost == nullptr) {
			return GENERALERROR;
		}

		// Check if player has any waypoints
		if (ghost->getWaypointListSize() == 0) {
			creature->sendSystemMessage("You have no waypoints to manage.");
			return GENERALERROR;
		}

		// Create SUI listbox for waypoint selection
		ManagedReference<SuiListBox*> suiBox = new SuiListBox(creature, SuiWindowType::NONE);
		suiBox->setPromptTitle("Waypoint Color Manager");
		suiBox->setPromptText("Select a waypoint to change its color:");
		suiBox->setForceCloseDistance(32.0f);

		// Add all waypoints to the list
		for (int i = 0; i < ghost->getWaypointListSize(); i++) {
			ManagedReference<WaypointObject*> waypoint = ghost->getWaypoint(i);
			if (waypoint != nullptr) {
				StringBuffer waypointName;
				waypointName << waypoint->getCustomObjectName().toString();

				// Add color indicator
				byte color = waypoint->getColor();
				String colorName;
				switch (color) {
					case 0x00: colorName = " [White]"; break;
					case 0x01: colorName = " [Blue]"; break;
					case 0x02: colorName = " [Green]"; break;
					case 0x03: colorName = " [Orange]"; break;
					case 0x04: colorName = " [Yellow]"; break;
					case 0x05: colorName = " [Purple]"; break;
					case 0x06: colorName = " [White2]"; break;
					case 0x07: colorName = " [Space]"; break;
					default: colorName = ""; break;
				}
				waypointName << colorName;

				suiBox->addMenuItem(waypointName.toString(), waypoint->getObjectID());
			}
		}

		// Set callback
		suiBox->setCallback(new DatapadWaypointListSuiCallback(creature->getZoneServer()));

		// Add to player's active SUI windows
		ghost->addSuiBox(suiBox);
		creature->sendMessage(suiBox->generateMessage());

		return SUCCESS;
	}
};

#endif // WAYPOINTCOLORCOMMAND_H_
