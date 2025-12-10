/*
 * WaypointMenuComponent.cpp
 *
 * Handles radial menu options for waypoint objects, including color selection
 */

#include "WaypointMenuComponent.h"
#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/callbacks/WaypointColorSuiCallback.h"

void WaypointMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	if (sceneObject == nullptr || !sceneObject->isWaypointObject() || player == nullptr) {
		return;
	}

	Logger::console.info("WaypointMenuComponent::fillObjectMenuResponse called!", true);

	// Add waypoint menu options
	menuResponse->addRadialMenuItem(20, 3, "@ui_radial:waypoint_activate"); // Activate
	menuResponse->addRadialMenuItem(21, 3, "@ui_radial:waypoint_set_name"); // Set Name
	menuResponse->addRadialMenuItem(22, 3, "@examine"); // Examine
	menuResponse->addRadialMenuItem(83, 3, "Set Color"); // Set Color
	menuResponse->addRadialMenuItem(69, 3, "@ui_radial:item_destroy"); // Destroy

	Logger::console.info("WaypointMenuComponent: Added 5 menu items", true);
}

int WaypointMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (!sceneObject->isWaypointObject() || player == nullptr) {
		return 0;
	}

	ManagedReference<WaypointObject*> waypoint = cast<WaypointObject*>(sceneObject);

	if (waypoint == nullptr) {
		return 0;
	}

	ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

	if (ghost == nullptr) {
		return 0;
	}

	switch (selectedID) {
		case 20: // Activate
			waypoint->setActive(true);
			ghost->updateWaypoint(waypoint->getObjectID());
			player->sendSystemMessage("@base_player:waypoint_activated"); // Waypoint activated.
			break;

		case 21: // Set Name
			// This is handled client-side through a text input box
			break;

		case 22: // Examine
			// This is handled by the base object examine functionality
			break;

		case 83: // Set Color
			{
				// Create SUI listbox for color selection
				ManagedReference<SuiListBox*> suiBox = new SuiListBox(player, SuiWindowType::NONE);
				suiBox->setPromptTitle("Waypoint Color");

				StringBuffer promptText;
				promptText << "Select a color for waypoint: " << waypoint->getCustomObjectName().toString();
				suiBox->setPromptText(promptText.toString());

				suiBox->setUsingObject(waypoint);
				suiBox->setForceCloseDistance(32.0f);

				// Add color options
				suiBox->addMenuItem("White", 0x00);
				suiBox->addMenuItem("Blue", 0x01);
				suiBox->addMenuItem("Green", 0x02);
				suiBox->addMenuItem("Orange", 0x03);
				suiBox->addMenuItem("Yellow", 0x04);
				suiBox->addMenuItem("Purple", 0x05);
				suiBox->addMenuItem("White (Alt)", 0x06);
				suiBox->addMenuItem("Space", 0x07);

				// Set callback
				suiBox->setCallback(new WaypointColorSuiCallback(player->getZoneServer()));

				// Add to player's active SUI windows
				ghost->addSuiBox(suiBox);
				player->sendMessage(suiBox->generateMessage());
			}
			break;

		case 69: // Destroy
			ghost->removeWaypoint(waypoint->getObjectID());
			player->sendSystemMessage("@base_player:waypoint_removed"); // Waypoint removed.
			break;
	}

	return 0;
}
