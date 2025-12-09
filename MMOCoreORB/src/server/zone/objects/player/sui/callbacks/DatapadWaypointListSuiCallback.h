/*
 * DatapadWaypointListSuiCallback.h
 *
 * Handles the callback when a player selects a waypoint from the datapad management list
 */

#ifndef DATAPADWAYPOINTLISTSUICALLBACK_H_
#define DATAPADWAYPOINTLISTSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/callbacks/WaypointColorSuiCallback.h"

class DatapadWaypointListSuiCallback : public SuiCallback {
public:
	DatapadWaypointListSuiCallback(ZoneServer* serv) : SuiCallback(serv) {
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

		// Get the selected waypoint ID
		uint64 waypointID = listBox->getMenuObjectID(index);

		ManagedReference<WaypointObject*> waypoint = server->getObject(waypointID).castTo<WaypointObject*>();

		if (waypoint == nullptr) {
			player->sendSystemMessage("Unable to find selected waypoint.");
			return;
		}

		// Now show the color selection UI for this waypoint
		ManagedReference<SuiListBox*> colorBox = new SuiListBox(player, SuiWindowType::NONE);
		colorBox->setPromptTitle("Waypoint Color");

		StringBuffer promptText;
		promptText << "Select a color for waypoint: " << waypoint->getCustomObjectName().toString();
		colorBox->setPromptText(promptText.toString());

		colorBox->setUsingObject(waypoint);
		colorBox->setForceCloseDistance(32.0f);

		// Add color options
		colorBox->addMenuItem("White", 0x00);
		colorBox->addMenuItem("Blue", 0x01);
		colorBox->addMenuItem("Green", 0x02);
		colorBox->addMenuItem("Orange", 0x03);
		colorBox->addMenuItem("Yellow", 0x04);
		colorBox->addMenuItem("Purple", 0x05);
		colorBox->addMenuItem("White (Alt)", 0x06);
		colorBox->addMenuItem("Space", 0x07);

		// Set callback
		colorBox->setCallback(new WaypointColorSuiCallback(server));

		// Add to player's active SUI windows
		ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

		if (ghost != nullptr) {
			ghost->addSuiBox(colorBox);
			player->sendMessage(colorBox->generateMessage());
		}
	}
};

#endif /* DATAPADWAYPOINTLISTSUICALLBACK_H_ */
