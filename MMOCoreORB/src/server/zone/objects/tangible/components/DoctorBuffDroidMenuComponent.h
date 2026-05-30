#ifndef DOCTORBUFFDROIDMENUCOMPONENT_H_
#define DOCTORBUFFDROIDMENUCOMPONENT_H_

#include "server/zone/objects/tangible/components/TangibleObjectMenuComponent.h"
#include "DoctorBuffDroidDataComponent.h"

class DoctorBuffDroidMenuComponent : public TangibleObjectMenuComponent {
public:
	enum MenuIds {
		MENU_ROOT = 70,
		MENU_BUFFS = 71,
		MENU_WOUNDS = 72,
		MENU_POISON = 73,
		MENU_DISEASE = 74,
		MENU_PRICES = 75,
		MENU_LOAD = 76,
		MENU_STOCK = 77,
		MENU_CONFIG_PRICES = 78,
		MENU_CONFIG_DISCOUNT = 79,
		MENU_TOGGLE_SERVICES = 80,
		MENU_EARNINGS = 81,
		MENU_WITHDRAW = 82,
		MENU_STORE = 83,
		MENU_JANTA_BUFFS = 84,
		MENU_LOAD_JANTA = 85,
		MENU_SET_AD = 86,
		MENU_TOGGLE_AD = 87,
		MENU_PET_BUFFS = 88,
		MENU_PET_JANTA_BUFFS = 89
	};

	enum LoadMode {
		LOAD_STANDARD = 0,
		LOAD_JANTA_ONLY = 1
	};

	static DoctorBuffDroidDataComponent* getDroidData(SceneObject* sceneObject);
	static void sendOwnerOnlyMessage(CreatureObject* player);
	static void sendPriceSummary(CreatureObject* player, DoctorBuffDroidDataComponent* data);
	static void sendStockSummary(CreatureObject* player, DoctorBuffDroidDataComponent* data);
	static void sendEarningsSummary(CreatureObject* player, DoctorBuffDroidDataComponent* data);
	static bool storeDroid(SceneObject* sceneObject, CreatureObject* player);
	static bool loadSupplies(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data, LoadMode mode = LOAD_STANDARD);
	static void promptPriceSelection(SceneObject* sceneObject, CreatureObject* player);
	static void promptPriceInput(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent::ServiceType service);
	static void promptDiscountInput(SceneObject* sceneObject, CreatureObject* player);
	static void promptToggleSelection(SceneObject* sceneObject, CreatureObject* player);
	static bool performMedicalBuff(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data, bool useJanta = false);
	static bool performWoundHealing(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data);
	static bool performResistance(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data, DoctorBuffDroidDataComponent::ServiceType type);
	static bool performPetBuff(SceneObject* sceneObject, CreatureObject* player, DoctorBuffDroidDataComponent* data, bool useJanta = false);
	static void promptAdTextInput(SceneObject* sceneObject, CreatureObject* player);

	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const override;
	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const override;
};

#endif
