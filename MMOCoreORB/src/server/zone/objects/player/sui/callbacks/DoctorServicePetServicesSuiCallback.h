#ifndef DOCTORSERVICEPETSERVICESSUICALLBACK_H_
#define DOCTORSERVICEPETSERVICESSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/components/doctorservice/DoctorServiceUnitMenuComponent.h"

class DoctorServicePetServicesSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> stationRef;

public:
	DoctorServicePetServicesSuiCallback(
		ZoneServer* server, SceneObject* station)
		: SuiCallback(server), stationRef(station) {
	}

	void run(
		CreatureObject* player, SuiBox* suiBox,
		uint32 eventIndex, Vector<UnicodeString>* args) override {

		SceneObject* station = stationRef.get();

		if (station == nullptr || player == nullptr)
			return;

		if (!DoctorServiceUnitMenuComponent::isPlayerWithinUseRange(
				station, player))
			return;

		if (eventIndex == 1) {
			DoctorServiceUnitMenuComponent::showStationMainMenu(
				station, player);
			return;
		}

		if (suiBox == nullptr || !suiBox->isListBox() ||
				args == nullptr || args->size() < 1)
			return;

		try {
			int index =
				Integer::valueOf(args->get(0).toString());

			DoctorServiceUnitMenuComponent::handlePetServiceSelection(
				station, player, index);
		} catch (Exception& e) {
			player->sendSystemMessage(
				"Unable to select that pet-buff service.");
		}
	}
};

#endif
