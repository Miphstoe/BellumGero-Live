#ifndef DOCTORBUFFDROIDPRICESUICALLBACK_H_
#define DOCTORBUFFDROIDPRICESUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"
#include "server/zone/objects/tangible/components/doctorservice/DoctorServiceUnitMenuComponent.h"

class DoctorBuffDroidPriceSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> droidRef;

public:
	DoctorBuffDroidPriceSuiCallback(
		ZoneServer* serv, SceneObject* droid)
		: SuiCallback(serv), droidRef(droid) {
	}

	void run(
		CreatureObject* player, SuiBox* suiBox,
		uint32 eventIndex, Vector<UnicodeString>* args) override {

		SceneObject* droid = droidRef.get();
		if (droid == nullptr || player == nullptr)
			return;

		bool station =
			DoctorBuffDroidMenuComponent::isDoctorServiceUnit(droid);

		if (station &&
				!DoctorServiceUnitMenuComponent::isPlayerWithinUseRange(droid, player))
			return;

		if (eventIndex == 1) {
			if (station)
				DoctorServiceUnitMenuComponent::showOwnerConfigMenu(
					droid, player);
			return;
		}

		if (!suiBox->isListBox() ||
				args == nullptr || args->size() < 1)
			return;

		int index =
			Integer::valueOf(args->get(0).toString());

		switch (index) {
		case 0:
			DoctorBuffDroidMenuComponent::promptPriceInput(
				droid, player,
				DoctorBuffDroidDataComponent::SERVICE_BUFFS);
			break;
		case 1:
			DoctorBuffDroidMenuComponent::promptPriceInput(
				droid, player,
				DoctorBuffDroidDataComponent::SERVICE_JANTA);
			break;
		case 2:
			DoctorBuffDroidMenuComponent::promptPriceInput(
				droid, player,
				DoctorBuffDroidDataComponent::SERVICE_WOUNDS);
			break;
		case 3:
			DoctorBuffDroidMenuComponent::promptPriceInput(
				droid, player,
				DoctorBuffDroidDataComponent::SERVICE_POISON);
			break;
		case 4:
			DoctorBuffDroidMenuComponent::promptPriceInput(
				droid, player,
				DoctorBuffDroidDataComponent::SERVICE_DISEASE);
			break;
		default:
			break;
		}
	}
};

#endif
