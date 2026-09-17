/*
 * DestroyCommandSuiCallback.h
 *
 *  Created on: Nov 3, 2010
 *      Author: crush
 */

#ifndef DESTROYCOMMANDSUICALLBACK_H_
#define DESTROYCOMMANDSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/deed/structure/StructureDeed.h"

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

		// House Pack-Up safety: a deed still holding packed structure contents is the
		// only reference that can recover those items. Refuse to destroy it outright
		// rather than silently stranding hundreds of player objects; a GM who is sure
		// this deed's contents are truly gone should first clear it via /housepackinfo
		// review, not this generic destroy tool.
		if (StructureDeed* packedDeed = dynamic_cast<StructureDeed*>(obj.get())) {
			if (packedDeed->isPackedWithContents()) {
				creature->sendSystemMessage("This deed still holds packed structure contents (state="
					+ String::valueOf(packedDeed->getHousePackState()) + ", "
					+ String::valueOf((int)packedDeed->getHousePackedItemCount()) + " item(s)). "
					"Destroying it would strand that player's property. Use /housepackinfo to review it first.");
				return;
			}
		}

		obj->destroyObjectFromWorld(true);

		obj->destroyObjectFromDatabase(true);

		creature->sendSystemMessage("The object has been successfully destroyed from the database.");
	}
};

#endif /* DESTROYCOMMANDSUICALLBACK_H_ */
