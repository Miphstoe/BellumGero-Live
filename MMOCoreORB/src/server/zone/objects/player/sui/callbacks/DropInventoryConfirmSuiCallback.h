/*
 * Bellum Gero — /dropinventory step 3: confirmed. Revalidate EVERYTHING, then transfer.
 * Nothing from the earlier preview is trusted; every item is reclassified.
 */

#ifndef DROPINVENTORYCONFIRMSUICALLBACK_H_
#define DROPINVENTORYCONFIRMSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/creature/commands/DropInventoryHelper.h"

class DropInventoryConfirmSuiCallback : public SuiCallback {
public:
	DropInventoryConfirmSuiCallback(ZoneServer* serv) : SuiCallback(serv) {
	}

	void run(CreatureObject* creature, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (creature == nullptr || sui == nullptr || !sui->isMessageBox() || cancelPressed)
			return;

		if (DropInventoryHelper::playerBusy(creature)) {
			creature->sendSystemMessage("You cannot use /dropinventory right now.");
			return;
		}

		ManagedReference<SceneObject*> inventory = DropInventoryHelper::getInventory(creature);
		ManagedReference<SceneObject*> dest = sui->getUsingObject().get();

		if (inventory == nullptr || dest == nullptr) {
			creature->sendSystemMessage("The selected container is no longer accessible.");
			return;
		}

		// Re-run every target check (structure, range, permissions) at confirm time.
		DropInventoryHelper::TargetStatus ts = DropInventoryHelper::validateTarget(creature, inventory, dest);

		if (ts != DropInventoryHelper::TARGET_OK) {
			creature->sendSystemMessage(DropInventoryHelper::targetMessage(ts));
			return;
		}

		DropInventoryHelper::Result r;

		{
			Locker invLocker(inventory, creature);
			r = DropInventoryHelper::execute(creature, inventory, dest);
		}

		creature->info() << "/dropinventory: moved " << r.moved << " into " << dest->getObjectID()
			<< " locked=" << r.locked << " equipped=" << r.equipped << " restricted=" << r.restricted
			<< " containers=" << r.containers << " capacity=" << r.capacity << (r.aborted ? " ABORTED" : "");

		if (r.aborted)
			creature->sendSystemMessage("The transfer was stopped because of an inventory error. Please check your items and report this to staff.");

		if (r.moved == 0 && !r.aborted) {
			creature->sendSystemMessage("You do not have any eligible items to transfer.");
			return;
		}

		creature->sendSystemMessage("Inventory Transfer Complete - Destination: " + dest->getDisplayedName());
		creature->sendSystemMessage("Items moved: " + String::valueOf(r.moved) + "   Locked skipped: " + String::valueOf(r.locked) + "   Equipped skipped: " + String::valueOf(r.equipped));
		creature->sendSystemMessage("Restricted skipped: " + String::valueOf(r.restricted) + "   Containers skipped: " + String::valueOf(r.containers) + "   Capacity skips: " + String::valueOf(r.capacity));
	}
};

#endif /* DROPINVENTORYCONFIRMSUICALLBACK_H_ */
