/*
 * WaypointColorSuiCallback.h
 *
 * Handles the callback when a player selects a waypoint color from the SUI listbox
 */

#ifndef WAYPOINTCOLORSUICALLBACK_H_
#define WAYPOINTCOLORSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/PlayerObject.h"

class WaypointColorSuiCallback : public SuiCallback {
public:
	WaypointColorSuiCallback(ZoneServer* serv) : SuiCallback(serv) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (!suiBox->isListBox() || player == nullptr) {
			return;
		}

		if (cancelPressed) {
			return;
		}

		if (args->size() < 1) {
			return;
		}

		int index = Integer::valueOf(args->get(0).toString());

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);

		if (listBox == nullptr) {
			return;
		}

		ManagedReference<SceneObject*> usingObject = suiBox->getUsingObject().get();

		if (usingObject == nullptr || !usingObject->isWaypointObject()) {
			player->sendSystemMessage("Unable to change waypoint color.");
			return;
		}

		ManagedReference<WaypointObject*> waypoint = usingObject.castTo<WaypointObject*>();

		if (waypoint == nullptr) {
			player->sendSystemMessage("Unable to change waypoint color.");
			return;
		}

		// Get the selected color from the menu item ID
		uint64 menuObjectID = listBox->getMenuObjectID(index);
		byte selectedColor = (byte)menuObjectID;

		// Validate color is in range (0x00 to 0x07)
		if (selectedColor > 0x07) {
			player->sendSystemMessage("Invalid color selected.");
			return;
		}

		Locker wlock(waypoint, player);

		// Set the new color
		waypoint->setColor(selectedColor);

		// Get the PlayerObject and update the waypoint
		ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

		if (ghost != nullptr) {
			// Force an update to the client by toggling the waypoint
			bool wasActive = waypoint->isActive();
			ghost->updateWaypoint(waypoint->getObjectID());

			// Restore active state if needed
			if (wasActive != waypoint->isActive()) {
				waypoint->setActive(wasActive);
				ghost->updateWaypoint(waypoint->getObjectID());
			}
		}

		// Send confirmation message
		StringBuffer colorName;
		switch (selectedColor) {
			case 0x00: // COLOR_WHITE
				colorName << "White";
				break;
			case 0x01: // COLOR_BLUE
				colorName << "Blue";
				break;
			case 0x02: // COLOR_GREEN
				colorName << "Green";
				break;
			case 0x03: // COLOR_ORANGE
				colorName << "Orange";
				break;
			case 0x04: // COLOR_YELLOW
				colorName << "Yellow";
				break;
			case 0x05: // COLOR_PURPLE
				colorName << "Purple";
				break;
			case 0x06: // COLOR_WHITE2
				colorName << "White (Alt)";
				break;
			case 0x07: // COLOR_SPACE
				colorName << "Space";
				break;
			default:
				colorName << "Unknown";
				break;
		}

		StringBuffer message;
		message << "Waypoint color changed to " << colorName.toString() << ".";
		player->sendSystemMessage(message.toString());
	}
};

#endif /* WAYPOINTCOLORSUICALLBACK_H_ */
