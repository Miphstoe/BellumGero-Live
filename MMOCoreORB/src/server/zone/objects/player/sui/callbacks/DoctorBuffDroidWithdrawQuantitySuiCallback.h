#ifndef DOCTORBUFFDROIDWITHDRAWQUANTITYSUICALLBACK_H_
#define DOCTORBUFFDROIDWITHDRAWQUANTITYSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"

class DoctorBuffDroidWithdrawQuantitySuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> droidRef;
	uint64 itemObjectId;
	int maxQty;

public:
	DoctorBuffDroidWithdrawQuantitySuiCallback(ZoneServer* serv, SceneObject* droid, uint64 itemId, int max)
		: SuiCallback(serv), droidRef(droid), itemObjectId(itemId), maxQty(max) {}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) override {
		if (eventIndex == 1 || !suiBox->isInputBox() || args == nullptr || args->size() < 1)
			return;

		if (player == nullptr)
			return;

		SceneObject* droid = droidRef.get();
		if (droid == nullptr)
			return;

		DoctorBuffDroidDataComponent* data = DoctorBuffDroidMenuComponent::getDroidData(droid);
		if (data == nullptr || !data->isOwner(player)) {
			player->sendSystemMessage("Only the owning Master Doctor can withdraw supplies from this droid.");
			return;
		}

		try {
			int qty = Integer::valueOf(args->get(0).toString());
			if (qty <= 0) {
				player->sendSystemMessage("Please enter a quantity greater than zero.");
				return;
			}
			if (qty > maxQty)
				qty = maxQty;
			DoctorBuffDroidMenuComponent::withdrawBuffStock(droid, player, data, itemObjectId, qty);
		} catch (Exception& e) {
			player->sendSystemMessage("Invalid quantity entered.");
		}
	}
};

#endif
