#ifndef DOCTORBUFFDROIDPRICESUICALLBACK_H_
#define DOCTORBUFFDROIDPRICESUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"

class DoctorBuffDroidPriceSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> droidRef;

public:
	DoctorBuffDroidPriceSuiCallback(ZoneServer* serv, SceneObject* droid) : SuiCallback(serv), droidRef(droid) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) override {
		if (eventIndex == 1 || !suiBox->isListBox() || args->size() < 1)
			return;

		SceneObject* droid = droidRef.get();
		if (droid == nullptr)
			return;

		int index = Integer::valueOf(args->get(0).toString());

		switch (index) {
		case 0:
			DoctorBuffDroidMenuComponent::promptPriceInput(droid, player, DoctorBuffDroidDataComponent::SERVICE_BUFFS);
			break;
		case 1:
			DoctorBuffDroidMenuComponent::promptPriceInput(droid, player, DoctorBuffDroidDataComponent::SERVICE_JANTA);
			break;
		case 2:
			DoctorBuffDroidMenuComponent::promptPriceInput(droid, player, DoctorBuffDroidDataComponent::SERVICE_WOUNDS);
			break;
		case 3:
			DoctorBuffDroidMenuComponent::promptPriceInput(droid, player, DoctorBuffDroidDataComponent::SERVICE_POISON);
			break;
		case 4:
			DoctorBuffDroidMenuComponent::promptPriceInput(droid, player, DoctorBuffDroidDataComponent::SERVICE_DISEASE);
			break;
		default:
			break;
		}
	}
};

#endif
