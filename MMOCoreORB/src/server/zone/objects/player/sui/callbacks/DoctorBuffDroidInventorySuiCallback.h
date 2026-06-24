#ifndef DOCTORBUFFDROIDINVENTORYSUICALLBACK_H_
#define DOCTORBUFFDROIDINVENTORYSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/BuffAttribute.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"

class DoctorBuffDroidInventorySuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> droidRef;
	Vector<int> entryServiceTypes;
	Vector<int> entryAttrs;
	Vector<int> entryMaxQtys;
	// Index of the "Remove My Active Doctor Buffs" row in the list.
	int removeBuffsIndex;

public:
	DoctorBuffDroidInventorySuiCallback(ZoneServer* serv, SceneObject* droid,
		const Vector<int>& serviceTypes, const Vector<int>& attrs, const Vector<int>& maxQtys, int removeIdx)
		: SuiCallback(serv), droidRef(droid),
		  entryServiceTypes(serviceTypes), entryAttrs(attrs), entryMaxQtys(maxQtys),
		  removeBuffsIndex(removeIdx) {}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) override {
		if (eventIndex == 1 || !suiBox->isListBox() || args == nullptr || args->size() < 1)
			return;

		if (player == nullptr)
			return;

		int index = Integer::valueOf(args->get(0).toString());

		// Remove-buffs row: clear all active doctor enhancement buffs from this player.
		if (index == removeBuffsIndex) {
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
		if (index < 0 || index >= entryServiceTypes.size())
			return;

		SceneObject* droid = droidRef.get();
		if (droid == nullptr)
			return;

		DoctorBuffDroidDataComponent* data = DoctorBuffDroidMenuComponent::getDroidData(droid);
		if (data == nullptr || !data->isOwner(player)) {
			player->sendSystemMessage("Only the owning Master Doctor can withdraw supplies from this droid.");
			return;
		}

		int svcInt = entryServiceTypes.get(index);
		if (svcInt < 0) {
			// Informational-only row (e.g. empty droid notice).
			return;
		}

		DoctorBuffDroidDataComponent::ServiceType svc =
			(DoctorBuffDroidDataComponent::ServiceType)svcInt;
		byte attr = (byte)entryAttrs.get(index);
		int maxQty = entryMaxQtys.get(index);

		DoctorBuffDroidMenuComponent::promptWithdrawQuantity(droid, player, svc, attr, maxQty);
	}
};

#endif
