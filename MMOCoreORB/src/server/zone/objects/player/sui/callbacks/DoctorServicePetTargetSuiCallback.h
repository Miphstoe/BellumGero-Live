#ifndef DOCTORSERVICEPETTARGETSUICALLBACK_H_
#define DOCTORSERVICEPETTARGETSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/tangible/components/doctorservice/DoctorServiceUnitMenuComponent.h"

class DoctorServicePetTargetSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> stationRef;
	bool useJanta;

public:
	DoctorServicePetTargetSuiCallback(
		ZoneServer* server, SceneObject* station,
		bool janta)
		: SuiCallback(server),
		  stationRef(station), useJanta(janta) {
	}

	void run(
		CreatureObject* player, SuiBox* suiBox,
		uint32 eventIndex, Vector<UnicodeString>* args) override {

		SceneObject* station = stationRef.get();

		if (station == nullptr || player == nullptr)
			return;

		if (eventIndex == 1) {
			DoctorServiceUnitMenuComponent::showPetServicesMenu(
				station, player);
			return;
		}

		if (suiBox == nullptr || !suiBox->isListBox() ||
				args == nullptr || args->size() < 1)
			return;

		SuiListBox* listBox =
			cast<SuiListBox*>(suiBox);

		if (listBox == nullptr)
			return;

		try {
			int index =
				Integer::valueOf(args->get(0).toString());

			if (index < 0 ||
					index >= listBox->getMenuSize())
				return;

			uint64 petObjectId =
				listBox->getMenuObjectID(index);

			DoctorServiceUnitMenuComponent::handlePetTargetSelection(
				station, player,
				useJanta, petObjectId);
		} catch (Exception& e) {
			player->sendSystemMessage(
				"Unable to select that active pet.");
		}
	}
};

#endif
