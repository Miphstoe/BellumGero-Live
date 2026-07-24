/*
 * ManageStructuresAddPowerSuiCallback.h
 *
 * Handles power deposits opened from /managestructures and returns the player
 * to the combined structure-management list afterward.
 */

#ifndef MANAGESTRUCTURESADDPOWERSUICALLBACK_H_
#define MANAGESTRUCTURESADDPOWERSUICALLBACK_H_

#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/installation/InstallationObject.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/structure/StructureObject.h"

class ManageStructuresAddPowerSuiCallback : public SuiCallback {
public:
	ManageStructuresAddPowerSuiCallback(ZoneServer* server) : SuiCallback(server) {
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

		int64 requestedAmount = Long::valueOf(args->get(1).toString());
		if (requestedAmount <= 0 || requestedAmount > 0xFFFFFFFFLL) {
			creature->sendSystemMessage("Please enter a valid power amount greater than zero.");
			creature->enqueueCommand(STRING_HASHCODE("managestructures"), 0, 0, "");
			return;
		}

		ManagedReference<StructureObject*> structure = sui->getStructureObject().get();
		if (structure == nullptr || !structure->isInstallationObject()) {
			creature->sendSystemMessage("That installation is no longer available.");
			creature->enqueueCommand(STRING_HASHCODE("managestructures"), 0, 0, "");
			return;
		}

		InstallationObject* installation = cast<InstallationObject*>(structure.get());
		if (installation == nullptr)
			return;

		StructureManager* structureManager = StructureManager::instance();
		if (structureManager == nullptr)
			return;

		{
			Locker installationLocker(installation, creature);
			structureManager->addRemotePower(installation, creature, (uint32)requestedAmount);
		}

		creature->enqueueCommand(STRING_HASHCODE("managestructures"), 0, 0, "");
	}
};

#endif // MANAGESTRUCTURESADDPOWERSUICALLBACK_H_
