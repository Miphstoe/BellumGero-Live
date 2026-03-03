/*
 * CityFactionTroopMenuComponent.cpp
 */

#include "server/zone/objects/creature/CreatureObject.h"
#include "CityFactionTroopMenuComponent.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/managers/city/CityRemoveFactionTroopTask.h"

void CityFactionTroopMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	ManagedReference<CityRegion*> city = sceneObject->getCityRegion().get();

	if (city != nullptr && city->isMayor(player->getObjectID()))
		menuResponse->addRadialMenuItem(72, 3, "@city/city:mt_remove"); // Remove
}

int CityFactionTroopMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (selectedID == 72) {
		ManagedReference<CityRegion*> city = sceneObject->getCityRegion().get();

		if (city != nullptr && city->isMayor(player->getObjectID())) {
			CityRemoveFactionTroopTask* task = new CityRemoveFactionTroopTask(sceneObject, city);
			task->execute();
			player->sendSystemMessage("@city/city:mt_removed"); // The object has been removed from the city.
		}

		return 0;
	}

	return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
}