/*
 * DatapadMenuComponent.cpp
 *
 * Handles radial menu options for datapad objects
 */

#include "DatapadMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/callbacks/DatapadWaypointListSuiCallback.h"

void DatapadMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	if (sceneObject == nullptr || player == nullptr) {
		return;
	}

	// Call parent to add default options
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	// Add "Manage Waypoint Colors" option to radial menu (using radial ID 82)
	menuResponse->addRadialMenuItem(82, 3, "Manage Waypoint Colors");
}

int DatapadMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (sceneObject == nullptr || player == nullptr) {
		return 0;
	}

	// Handle "Manage Waypoint Colors" selection
	if (selectedID == 82) {
		ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

		if (ghost == nullptr) {
			return 0;
		}

		// Check if player has any waypoints
		if (ghost->getWaypointListSize() == 0) {
			player->sendSystemMessage("You have no waypoints to manage.");
			return 0;
		}

		// Create SUI listbox for waypoint selection
		ManagedReference<SuiListBox*> suiBox = new SuiListBox(player, SuiWindowType::NONE);
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
		suiBox->setCallback(new DatapadWaypointListSuiCallback(player->getZoneServer()));

		// Add to player's active SUI windows
		ghost->addSuiBox(suiBox);
		player->sendMessage(suiBox->generateMessage());
	}

	return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
}
