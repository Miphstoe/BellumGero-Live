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
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/managers/jedi/JediManager.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"

void HolocronDestinyMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	// Call parent implementation first
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	// Add the Holocron of Destiny specific menu option
	menuResponse->addRadialMenuItem(20, 3, "Unlock Random Branch");

	// Add lock/unlock options (only for items in player's inventory)
	if (!sceneObject->isASubChildOf(player))
		return;

	TangibleObject* tangible = dynamic_cast<TangibleObject*>(sceneObject);
	if (tangible == nullptr)
		return;

	// Check if item is locked
	String lockValue = tangible->getLuaStringData("item_locked");
	bool isLocked = !lockValue.isEmpty() && Integer::valueOf(lockValue) == 1;

	if (isLocked) {
		menuResponse->addRadialMenuItem(RADIAL_UNLOCK_ITEM, 3, "Unlock Item");
	} else {
		menuResponse->addRadialMenuItem(RADIAL_LOCK_ITEM, 3, "Lock Item");
	}
}

int HolocronDestinyMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* creature, byte selectedID) const {
	if (!sceneObject->isASubChildOf(creature))
		return 0;

	// Handle "Unlock Random Branch" option
	if (selectedID == 20) {
		JediManager::instance()->useItem(sceneObject, JediManager::ITEMHOLOCRONDESTINY, creature);
		return 0;
	}

	// Handle lock/unlock options
	if (selectedID == RADIAL_LOCK_ITEM || selectedID == RADIAL_UNLOCK_ITEM) {
		TangibleObject* tangible = dynamic_cast<TangibleObject*>(sceneObject);
		if (tangible == nullptr)
			return 0;

		if (selectedID == RADIAL_LOCK_ITEM) {
			// Lock the item
			tangible->setLuaStringData("item_locked", "1");

			// Set yellow highlight to show item is locked
			tangible->addMagicBit(true);

			// Get item name for message
			String itemName = sceneObject->getDisplayedName();
			if (itemName.isEmpty())
				itemName = sceneObject->getObjectNameStringIdName();

			creature->sendSystemMessage("Holocron locked: " + itemName + " - This item cannot be deleted or traded.");

			return 0;
		} else if (selectedID == RADIAL_UNLOCK_ITEM) {
			// Unlock the item
			tangible->deleteLuaStringData("item_locked");

			// Remove yellow highlight
			tangible->removeMagicBit(true);

			// Get item name for message
			String itemName = sceneObject->getDisplayedName();
			if (itemName.isEmpty())
				itemName = sceneObject->getObjectNameStringIdName();

			creature->sendSystemMessage("Holocron unlocked: " + itemName + " - This item can now be deleted or traded normally.");

			return 0;
		}
	}

	return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, creature, selectedID);
}
