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
	// Call CityDecorationMenuComponent which adds "Place Decoration" / "Remove" / "Align"
	// options for mayors, in addition to the standard TangibleObjectMenuComponent items.
	CityDecorationMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	// Add the Holocron of Destiny specific menu option
	menuResponse->addRadialMenuItem(20, 3, "Unlock Random Branch");

	// Add lock/unlock options only when in player's inventory
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
	// Handle "Unlock Random Branch" option — only usable from inventory
	if (selectedID == 20) {
		if (!sceneObject->isASubChildOf(creature))
			return 0;
		JediManager::instance()->useItem(sceneObject, JediManager::ITEMHOLOCRONDESTINY, creature);
		return 0;
	}

	// Handle lock/unlock options — only usable from inventory
	if (selectedID == RADIAL_LOCK_ITEM || selectedID == RADIAL_UNLOCK_ITEM) {
		if (!sceneObject->isASubChildOf(creature))
			return 0;

		TangibleObject* tangible = dynamic_cast<TangibleObject*>(sceneObject);
		if (tangible == nullptr)
			return 0;

		if (selectedID == RADIAL_LOCK_ITEM) {
			tangible->setLuaStringData("item_locked", "1");
			tangible->addMagicBit(true);

			String itemName = sceneObject->getDisplayedName();
			if (itemName.isEmpty())
				itemName = sceneObject->getObjectNameStringIdName();

			creature->sendSystemMessage("Holocron locked: " + itemName + " - This item cannot be deleted or traded.");
			return 0;
		} else {
			tangible->deleteLuaStringData("item_locked");
			tangible->removeMagicBit(true);

			String itemName = sceneObject->getDisplayedName();
			if (itemName.isEmpty())
				itemName = sceneObject->getObjectNameStringIdName();

			creature->sendSystemMessage("Holocron unlocked: " + itemName + " - This item can now be deleted or traded normally.");
			return 0;
		}
	}

	// Route 233 (Place), 234 (Remove), 74-77 (Align) to CityDecorationMenuComponent.
	// This also handles the case where the Holocron is placed in the world (not in inventory),
	// which the old blanket isASubChildOf guard at the top would have silently dropped.
	return CityDecorationMenuComponent::handleObjectMenuSelect(sceneObject, creature, selectedID);
}
