/*
 * RemoteStructurePayMaintenanceSuiCallback.h
 */

#ifndef REMOTESTRUCTUREPAYMAINTENANCESUICALLBACK_H_
#define REMOTESTRUCTUREPAYMAINTENANCESUICALLBACK_H_

#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/structure/StructureObject.h"

class RemoteStructurePayMaintenanceSuiCallback : public SuiCallback {
public:
	RemoteStructurePayMaintenanceSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* creature, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (creature == nullptr || sui == nullptr || !sui->isTransferBox())
			return;

		bool cancelPressed = (eventIndex == 1);

		// Return to the main management list when the player cancels the
		// maintenance payment window. The command rebuilds the list using the
		// current structure and credit values.
		if (cancelPressed) {
			creature->enqueueCommand(STRING_HASHCODE("managemaintenance"), 0, 0, "");
			return;
		}

		if (args == nullptr || args->size() < 2)
			return;

		int amount = Integer::valueOf(args->get(1).toString());
		if (amount < 0)
			return;

		// The transfer box is intentionally bound to the character so the client
		// does not range-check a distant or off-planet structure. The selected
		// structure is retained in SuiBox::structureObject instead.
		ManagedReference<StructureObject*> structure = sui->getStructureObject().get();
		if (structure == nullptr) {
			creature->sendSystemMessage("That structure is no longer available.");
			return;
		}

		// The creature is already locked by SuiManager. Lock the selected
		// structure and revalidate ownership inside payRemoteMaintenance().
		{
			Locker structureLocker(structure, creature);
			StructureManager::instance()->payRemoteMaintenance(structure, creature, amount);
		}

		// Return the player to the main management list. Re-running the command
		// rebuilds every row from the live structure values, so the maintenance
		// pool, remaining time, power status, and available funds are refreshed.
		creature->enqueueCommand(STRING_HASHCODE("managemaintenance"), 0, 0, "");
	}
};

#endif // REMOTESTRUCTUREPAYMAINTENANCESUICALLBACK_H_