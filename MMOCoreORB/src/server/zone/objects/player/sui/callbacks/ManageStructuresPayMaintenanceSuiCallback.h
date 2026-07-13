/*
 * ManageStructuresPayMaintenanceSuiCallback.h
 *
 * Handles maintenance deposits opened from /managestructures and returns the
 * player to the combined structure-management list afterward.
 */

#ifndef MANAGESTRUCTURESPAYMAINTENANCESUICALLBACK_H_
#define MANAGESTRUCTURESPAYMAINTENANCESUICALLBACK_H_

#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/structure/StructureObject.h"

class ManageStructuresPayMaintenanceSuiCallback : public SuiCallback {
public:
	ManageStructuresPayMaintenanceSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* creature, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (creature == nullptr || sui == nullptr || !sui->isTransferBox())
			return;

		bool cancelPressed = (eventIndex == 1);

		if (cancelPressed) {
			creature->enqueueCommand(STRING_HASHCODE("managestructures"), 0, 0, "");
			return;
		}

		if (args == nullptr || args->size() < 2)
			return;

		int amount = Integer::valueOf(args->get(1).toString());
		if (amount < 0)
			return;

		ManagedReference<StructureObject*> structure = sui->getStructureObject().get();
		if (structure == nullptr) {
			creature->sendSystemMessage("That structure is no longer available.");
			creature->enqueueCommand(STRING_HASHCODE("managestructures"), 0, 0, "");
			return;
		}

		StructureManager* structureManager = StructureManager::instance();
		if (structureManager == nullptr)
			return;

		{
			Locker structureLocker(structure, creature);
			structureManager->payRemoteMaintenance(structure, creature, amount);
		}

		creature->enqueueCommand(STRING_HASHCODE("managestructures"), 0, 0, "");
	}
};

#endif // MANAGESTRUCTURESPAYMAINTENANCESUICALLBACK_H_
