/*
 				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

/**
 * LogoutTask.h
 *
 *  Created: Sat Oct  8 09:18:00 EDT 2011
 *   Author: lordkator
 *
 *  Description: Task created by LogoutServerCommand to implement the /logout process
 */

#ifndef LOGOUTTASK_H_
#define LOGOUTTASK_H_

#include "server/zone/packets/player/LogoutMessage.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/cell/CellObject.h"

class LogoutTask: public Task {
	ManagedReference<CreatureObject*> creature;
	int timeLeft;

public:
	LogoutTask(CreatureObject* cr) {
		creature = cr;
		timeLeft = 30; // 30 seconds with messages in 5 second intervals

		StringIdChatParameter stringId("logout", "time_left");
		stringId.setDI(30);

		creature->sendSystemMessage(stringId); // You have %DI seconds left until you may log out safely.
	}

	void cancelLogout() {
		creature->removePendingTask("logout");

		if(isScheduled())
			cancel();

		StringIdChatParameter abortMsg("logout", "aborted");
		creature->sendSystemMessage(abortMsg); // Your attempt to log out safely has been aborted.
	}

	void findSecuredItems(SceneObject* container, uint64 buildingOID, Vector<ManagedReference<SceneObject*>>& items) {
		if (container == nullptr)
			return;

		for (int i = 0; i < container->getContainerObjectsSize(); i++) {
			SceneObject* child = container->getContainerObject(i);
			if (child == nullptr)
				continue;

			// Check if secured to this building
			TangibleObject* tangible = child->asTangibleObject();
			if (tangible != nullptr) {
				String securedValue = tangible->getLuaStringData("item_secured");
				if (!securedValue.isEmpty() && UnsignedLong::valueOf(securedValue) == buildingOID) {
					items.add(child);
				}
			}

			// Recurse into nested containers
			if (child->getContainerObjectsSize() > 0) {
				findSecuredItems(child, buildingOID, items);
			}
		}
	}

	void dropSecuredItemsFromInventory(CreatureObject* player, uint64 buildingOID, SceneObject* dropCell) {
		SceneObject* inventory = player->getSlottedObject("inventory");
		if (inventory == nullptr)
			return;

		Vector<ManagedReference<SceneObject*>> itemsToDrop;

		// Recursively find secured items
		findSecuredItems(inventory, buildingOID, itemsToDrop);

		// Drop each item to player's current cell
		for (int i = 0; i < itemsToDrop.size(); i++) {
			SceneObject* item = itemsToDrop.get(i);
			if (item != nullptr && dropCell != nullptr) {
				dropCell->transferObject(item, -1, true);
				item->setPosition(player->getPositionX(), player->getPositionY(), player->getPositionZ());
			}
		}
	}

	void run() {
		Locker creatureLocker(creature);

		PlayerObject* player = creature->getPlayerObject();

		try {
			// TODO: Research do things like bleeding, poison etc stop a /logout ??
			if (player->isLinkDead() || creature->isBleeding() || creature->isPoisoned() || creature->isDiseased() || creature->isOnFire() || !creature->isSitting()) {
				cancelLogout();
				return;
			}

			timeLeft -= 5;

			// Done waiting yet?
			if (timeLeft <= 0) {
				// Not 100% certain if this is right place to call this but seems like it should get called...
				player->setLoggingOut();

				StringIdChatParameter safeMsg("logout", "safe_to_log_out");
				creature->sendSystemMessage(safeMsg); // You may now log out safely.

				creature->removePendingTask("logout");

				// Drop secured items if player is in a building
				ManagedReference<SceneObject*> parentCell = creature->getParent().get();
				if (parentCell != nullptr && parentCell->isCellObject()) {
					SceneObject* building = creature->getRootParent();
					if (building != nullptr && building->isBuildingObject()) {
						dropSecuredItemsFromInventory(creature, building->getObjectID(), parentCell);
					}
				}

				// Send the client the Logout Packet
				creature->sendMessage(new LogoutMessage());

				player->info(creature->getFirstName() + " Logged out");

				return;
			}

			// Let them know how much time they have left before they log out...
			StringIdChatParameter timeLeftMsg("logout", "time_left");
			timeLeftMsg.setDI(timeLeft);

			creature->sendSystemMessage(timeLeftMsg); // You have %DI seconds left until you may log out safely.

			// run() again in 5 seconds
			reschedule(5000);
		} catch (Exception& e) {
			creature->error("unreported exception caught in LogoutTask::run()");
		}
	}
};

#endif /* LOGOUTTASK_H_ */
