/*
 * Bellum Gero — /dropinventory
 * Target a storage container placed inside a house, then /dropinventory.
 * Preview + confirm dialog -> DropInventoryConfirmSuiCallback (full revalidation + transfer).
 * Cooldown is configurable: Core3.CommandCooldown.dropinventory (ms, default 10000).
 */

#ifndef DROPINVENTORYCOMMAND_H_
#define DROPINVENTORYCOMMAND_H_

#include "server/zone/objects/creature/commands/QueueCommand.h"
#include "server/zone/objects/creature/commands/DropInventoryHelper.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/player/sui/callbacks/DropInventoryConfirmSuiCallback.h"

class DropInventoryCommand : public QueueCommand {
public:
	DropInventoryCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
		setCooldown(10000);
		setCooldownString("Please wait before using /dropinventory again.");
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (creature == nullptr || !creature->isPlayerCreature())
			return GENERALERROR;

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		PlayerObject* ghost = creature->getPlayerObject();

		if (ghost == nullptr)
			return GENERALERROR;

		if (DropInventoryHelper::playerBusy(creature)) {
			creature->sendSystemMessage("You cannot use /dropinventory right now.");
			return GENERALERROR;
		}

		// One operation at a time: an open confirmation means one is already in progress.
		if (ghost->hasSuiBoxWindowType(SuiWindowType::DROP_INVENTORY_CONFIRM)) {
			creature->sendSystemMessage("An inventory transfer is already in progress.");
			return GENERALERROR;
		}

		// Targeting check comes before the cooldown so a mistargeted attempt costs nothing.
		// The target ID is only a hint: it is resolved and fully validated server-side.
		uint64 targetID = target != 0 ? target : creature->getTargetID();

		if (targetID == 0) {
			creature->sendSystemMessage(DropInventoryHelper::targetMessage(DropInventoryHelper::TARGET_NONE));
			return GENERALERROR;
		}

		ManagedReference<SceneObject*> inventory = DropInventoryHelper::getInventory(creature);
		ManagedReference<SceneObject*> dest = server->getZoneServer()->getObject(targetID);

		if (inventory == nullptr) {
			creature->sendSystemMessage("Your inventory could not be found.");
			return GENERALERROR;
		}

		DropInventoryHelper::TargetStatus ts = DropInventoryHelper::validateTarget(creature, inventory, dest);

		if (ts != DropInventoryHelper::TARGET_OK) {
			creature->sendSystemMessage(DropInventoryHelper::targetMessage(ts));
			return GENERALERROR;
		}

		if (!checkCooldown(creature))
			return GENERALERROR;

		DropInventoryHelper::Result r;

		{
			Locker invLocker(inventory, creature);
			r = DropInventoryHelper::scan(creature, inventory, dest);
		}

		int free = DropInventoryHelper::freeSlots(dest);
		int protectedCount = r.locked + r.equipped + r.containers + r.restricted;

		if (r.eligible.size() == 0) {
			creature->sendSystemMessage("You do not have any eligible items to transfer.");
			return GENERALERROR;
		}

		if (free <= 0) {
			creature->sendSystemMessage("The selected container does not have enough available space.");
			return GENERALERROR;
		}

		StringBuffer text;
		text << "Destination: " << DropInventoryHelper::itemLabel(dest) << "\n\n"
			<< "Eligible Items: " << r.eligible.size() << "\n"
			<< "Protected Items: " << protectedCount << "\n"
			<< "Available Capacity: " << free << "\n\n";

		if (r.eligible.size() > free)
			text << "Only " << free << " of the eligible items will fit. The rest will stay in your inventory.\n\n";

		text << "Transfer eligible inventory items into the targeted container? "
			<< "Equipped items, locked items, and other containers are never moved.";

		ManagedReference<SuiMessageBox*> box = new SuiMessageBox(creature, SuiWindowType::DROP_INVENTORY_CONFIRM);
		box->setCallback(new DropInventoryConfirmSuiCallback(server->getZoneServer()));
		box->setPromptTitle("Drop Inventory Into Container");
		box->setPromptText(text.toString());
		box->setUsingObject(dest);
		box->setOkButton(true, "Confirm");
		box->setCancelButton(true, "@cancel");

		ghost->addSuiBox(box);
		creature->sendMessage(box->generateMessage());

		return SUCCESS;
	}
};

#endif /* DROPINVENTORYCOMMAND_H_ */
