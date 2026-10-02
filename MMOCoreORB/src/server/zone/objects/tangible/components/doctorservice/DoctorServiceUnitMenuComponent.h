/*
 * DoctorServiceUnitMenuComponent.h
 *
 * Bellum Gero - FMDoctorBot
 */

#ifndef DOCTORSERVICEUNITMENUCOMPONENT_H_
#define DOCTORSERVICEUNITMENUCOMPONENT_H_

#include "server/zone/objects/tangible/components/TangibleObjectMenuComponent.h"

class DoctorServiceUnitMenuComponent : public TangibleObjectMenuComponent {
public:
	enum MenuIds {
		MENU_ROOT = 180,
		MENU_BUY_STANDARD = 181,
		MENU_AVAILABILITY = 182,
		MENU_OPEN_HOPPER = 183,
		MENU_SAFETY_STATUS = 188,
		MENU_DECOMMISSION = 189,
		MENU_INVENTORY = 190,
		MENU_BUY_JANTA = 191,
		MENU_PET_SERVICES = 195,
		MENU_MEDICAL_SERVICES = 198,
		MENU_OWNER_CONFIG = 202,
		MENU_STATION_MENU = 203
	};

	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const override;
	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const override;

	static bool isPlayerWithinUseRange(SceneObject* station, CreatureObject* player, bool notify = true);

	// Public SUI navigation/callback entry points.
	static void showStationMainMenu(SceneObject* station, CreatureObject* player);
	static void showPetServicesMenu(SceneObject* station, CreatureObject* player);
	static void showMedicalServicesMenu(SceneObject* station, CreatureObject* player);
	static void showOwnerConfigMenu(SceneObject* station, CreatureObject* player);
	static void showPetTargetMenu(SceneObject* station, CreatureObject* player, bool useJanta);

	static void handleMainMenuSelection(SceneObject* station, CreatureObject* player, uint64 actionId);
	static void handlePetServiceSelection(SceneObject* station, CreatureObject* player, int index);
	static void handleMedicalServiceSelection(SceneObject* station, CreatureObject* player, int index);
	static void handleOwnerConfigSelection(SceneObject* station, CreatureObject* player, int index);
	static void handlePetTargetSelection(SceneObject* station, CreatureObject* player, bool useJanta, uint64 petObjectId);
	static void handleRebuffConfirmation(SceneObject* station, CreatureObject* player, bool useJanta, uint64 petObjectId);

private:
	static bool isPlacementValid(SceneObject* station, String* reason = nullptr);
	static void purchaseBuffs(SceneObject* station, CreatureObject* player, bool useJanta, bool confirmed = false);
	static void purchasePetBuffs(SceneObject* station, CreatureObject* player, bool useJanta, uint64 petObjectId, bool confirmed = false);
	static void purchaseResistance(SceneObject* station, CreatureObject* player, bool poison);
	static void purchaseWoundHealing(SceneObject* station, CreatureObject* player);
	static void showRebuffConfirm(SceneObject* station, CreatureObject* player, bool useJanta, uint64 petObjectId);
	static void showAvailability(SceneObject* station, CreatureObject* player);
	static void showInventory(SceneObject* station, CreatureObject* player);
	static void sendSafetyStatus(SceneObject* station, CreatureObject* player);
	static void decommission(SceneObject* station, CreatureObject* player);
};

#endif /* DOCTORSERVICEUNITMENUCOMPONENT_H_ */
