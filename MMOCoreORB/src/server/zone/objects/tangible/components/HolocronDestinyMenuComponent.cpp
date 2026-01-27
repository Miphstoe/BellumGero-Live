/*
 * HolocronDestinyMenuComponent.cpp
 *
 *  Created on: 01/23/2026
 *      Author: Miphstoe
 */

#include "HolocronDestinyMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/managers/jedi/JediManager.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"

void HolocronDestinyMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	// Call parent implementation first
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	// Add the Holocron of Destiny specific menu option
	menuResponse->addRadialMenuItem(20, 3, "Unlock Random Branch");
}

int HolocronDestinyMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* creature, byte selectedID) const {
	if (!sceneObject->isASubChildOf(creature))
		return 0;

	// Handle "Unlock Random Branch" option
	if (selectedID == 20) {
		JediManager::instance()->useItem(sceneObject, JediManager::ITEMHOLOCRONDESTINY, creature);
		return 0;
	}

	return 0;
}
