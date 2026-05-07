/*
 * ViewHouseStorageSuiCallback.h
 *
 * Callback for handling player interaction with the View House Storage SUI
 * Allows players to view all items in a house, with options to move items
 */

#ifndef VIEWHOUSESTORAGESUICALLBACK_H_
#define VIEWHOUSESTORAGESUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/objectcontroller/ObjectController.h"

class ViewHouseStorageSuiCallback : public SuiCallback {
public:
	ViewHouseStorageSuiCallback(ZoneServer* server, BuildingObject* building) : SuiCallback(server), building(building) {
	}

	void run(CreatureObject* player, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (player == nullptr || sui == nullptr || !sui->isListBox() || cancelPressed)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(sui);
		if (listBox == nullptr || building == nullptr)
			return;

		if (!building->isOnAdminList(player)) {
			player->sendSystemMessage("@player_structure:admin_move_only");
			return;
		}

		// Get selected index from args
		if (args == nullptr || args->size() == 0)
			return;

		int selectedIndex = Integer::valueOf(args->get(0).toString());

		// Get the selected item and move to player inventory
		if (selectedIndex < 0 || selectedIndex >= storedItems.size()) {
			player->sendSystemMessage("Invalid item selection.");
			return;
		}

		ManagedReference<SceneObject*> selectedItem = storedItems.elementAt(selectedIndex);
		if (selectedItem == nullptr) {
			player->sendSystemMessage("Item no longer exists in the house.");
			return;
		}

		try {
			// Get the item's location cell
			ManagedReference<SceneObject*> itemParent = selectedItem->getParent().castTo<SceneObject*>();

			// Store the item location for display
			String itemLocationInfo = "";
			if (itemParent != nullptr && itemParent->isCellObject()) {
				CellObject* cell = cast<CellObject*>(itemParent.get());
				if (cell != nullptr) {
					itemLocationInfo = "Cell " + String::valueOf(cell->getCellNumber());
				}
			}

			// Determine destination: containers go to datapad, regular items to inventory
			ManagedReference<SceneObject*> destination = nullptr;
			String destinationName = "";

			if (selectedItem->isContainerObject()) {
				// Containers go to datapad
				destination = player->getSlottedObject("datapad");
				destinationName = "datapad";
			} else {
				// Regular items go to inventory
				destination = player->getSlottedObject("inventory");
				destinationName = "inventory";
			}

			if (destination == nullptr) {
				StringBuffer msg;
				msg << "You do not have a " << destinationName << " to store this item.";
				player->sendSystemMessage(msg.toString());
				return;
			}

			// Check if destination has space
			if (destination->getContainerObjectsSize() >= 80) {
				StringBuffer msg;
				msg << "Your " << destinationName << " is full.";
				player->sendSystemMessage(msg.toString());
				return;
			}

			// Move item to player inventory using the ObjectController's transfer method
			Locker itemLocker(selectedItem);
			Locker parentLocker(itemParent);
			Locker destLocker(destination);

			// Get the zone server to use the proper ObjectController transfer method
			ManagedReference<Zone*> zone = player->getZone();
			if (zone == nullptr) {
				player->sendSystemMessage("Unable to access zone - transfer failed.");
				return;
			}

			ZoneServer* zoneServer = zone->getZoneServer();
			if (zoneServer == nullptr) {
				player->sendSystemMessage("Unable to access zone server - transfer failed.");
				return;
			}

			// Use ObjectController's transferObject which properly handles transfers between containers
			// This is the standard method used for moving items in the game
			bool transferSuccess = zoneServer->getObjectController()->transferObject(
				selectedItem,    // What to move
				destination,     // Where to move it
				-1,              // containmentType (-1 = volume container)
				true,            // notifyClient (update nearby players)
				false            // allowOverflow (don't bypass size limits)
			);

			if (transferSuccess) {
				String itemName = selectedItem->getDisplayedName();
				if (itemName.isEmpty())
					itemName = "Unknown Item";

				StringBuffer message;
				if (selectedItem->isContainerObject()) {
					message << "You retrieved '" << itemName << "' to your datapad.";
				} else {
					message << "You retrieved '" << itemName << "' to your inventory.";
				}
				player->sendSystemMessage(message.toString());

				// Send success feedback with location info
				StringBuffer feedback;
				feedback << "Item location was: " << itemLocationInfo;
				if (selectedItem->isContainerObject()) {
					feedback << " (Container with " << selectedItem->getContainerObjectsSize() << " items inside)";
				}
				player->sendSystemMessage(feedback.toString());
			} else {
				player->sendSystemMessage("Failed to move the item to your inventory.");
			}

		} catch (Exception& e) {
			player->sendSystemMessage("Error moving item: " + String(e.getMessage()));
		}
	}

	void setStoredItems(Vector<ManagedReference<SceneObject*>>& items) {
		storedItems = items;
	}

private:
	ManagedReference<BuildingObject*> building;
	Vector<ManagedReference<SceneObject*>> storedItems;
};

#endif //VIEWHOUSESTORAGESUICALLBACK_H_
