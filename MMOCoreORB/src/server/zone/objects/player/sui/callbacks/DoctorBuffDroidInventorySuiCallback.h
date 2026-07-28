#ifndef DOCTORBUFFDROIDINVENTORYSUICALLBACK_H_
#define DOCTORBUFFDROIDINVENTORYSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/BuffAttribute.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"

class DoctorBuffDroidInventorySuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> droidRef;

public:
	DoctorBuffDroidInventorySuiCallback(ZoneServer* serv, SceneObject* droid)
		: SuiCallback(serv), droidRef(droid) {}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) override {
		if (eventIndex == 1 || !suiBox->isListBox() || args == nullptr || args->size() < 1)
			return;

		if (player == nullptr)
			return;

		int index = Integer::valueOf(args->get(0).toString());
		if (index < 0)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);
		if (listBox == nullptr)
			return;

		uint64 itemObjectId = listBox->getMenuObjectID(index);

		// Rows with no attached object ID (0 is never a real object ID) are the
		// "Remove My Active Doctor Buffs" row.
		if (itemObjectId == 0) {
			int removed = 0;
			for (uint8 attr = 0; attr <= (uint8)BuffAttribute::DISEASE; ++attr) {
				String buffname = "medical_enhance_" + BuffAttribute::getName(attr);
				uint32 buffcrc = buffname.hashCode();
				if (player->hasBuff(buffcrc)) {
					player->removeBuff(buffcrc);
					++removed;
				}
			}
			if (removed > 0)
				player->sendSystemMessage("Your active Doctor Buff Droid enhancement buffs have been removed.");
			else
				player->sendSystemMessage("You have no active Doctor Buff Droid enhancement buffs to remove.");
			return;
		}

		// Supply row: only the owner can withdraw.
		SceneObject* droid = droidRef.get();
		if (droid == nullptr)
			return;

		DoctorBuffDroidDataComponent* data = DoctorBuffDroidMenuComponent::getDroidData(droid);
		if (data == nullptr || !data->isOwner(player)) {
			player->sendSystemMessage("Only the owning Master Doctor can withdraw supplies from this droid.");
			return;
		}

		int maxQty = DoctorBuffDroidMenuComponent::getLoadedItemQuantity(droid, itemObjectId);
		if (maxQty <= 0) {
			player->sendSystemMessage("That supply is no longer loaded in the droid.");
			return;
		}

		DoctorBuffDroidMenuComponent::promptWithdrawQuantity(droid, player, itemObjectId, maxQty);
	}
};

#endif
