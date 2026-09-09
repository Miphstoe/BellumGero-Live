/*
 * DestroyCommandSuiCallback.h
 *
 *  Created on: Nov 3, 2010
 *      Author: crush
 */

#ifndef DESTROYCOMMANDSUICALLBACK_H_
#define DESTROYCOMMANDSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/managers/structure/StructureManager.h"

class DestroyCommandSuiCallback : public SuiCallback {
public:
	DestroyCommandSuiCallback(ZoneServer* server)
		: SuiCallback(server) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (!suiBox->isMessageBox() || cancelPressed)
			return;

		ManagedReference<SceneObject*> obj = suiBox->getUsingObject().get();

		if (obj == nullptr)
			return;

		if (obj->isPlayerCreature()) {
			creature->sendSystemMessage("Destroying players with this command is prohibited.");
			return;
		}


		// BELLUM_GERO_STRUCTURE_WORLD_REMOVAL_GUARD_BUILD32A_EXTERNAL_AUTH
		// /destroy intentionally bypasses StructureManager::destroyStructure, so
		// persistent buildings must explicitly authorize this one removal.
		if (obj->isBuildingObject() && obj->getPersistenceLevel() > 0) {
			ManagedReference<StructureObject*> structure = obj.castTo<StructureObject*>();
			StructureManager* structureManager = StructureManager::instance();

			if (structure != nullptr && structureManager != nullptr) {
				Locker structureLocker(structure);
				structureManager->authorizePersistentStructureWorldRemoval(structure);
				structure->destroyObjectFromWorld(true);
				structure->destroyObjectFromDatabase(true);

				creature->sendSystemMessage("The object has been successfully destroyed from the database.");
				return;
			}

			creature->sendSystemMessage("Persistent structure destruction was refused because the structure removal guard was unavailable.");
			return;
		}

		obj->destroyObjectFromWorld(true);

		obj->destroyObjectFromDatabase(true);

		creature->sendSystemMessage("The object has been successfully destroyed from the database.");
	}
};

#endif /* DESTROYCOMMANDSUICALLBACK_H_ */
