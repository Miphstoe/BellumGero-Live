/*
 * ItemLockMenuComponent.cpp
 */

#include "ItemLockMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"

void ItemLockMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	if (!sceneObject->isASubChildOf(player))
		return;

	// Call parent to add default options
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	// Check if item is locked
	TangibleObject* tangible = dynamic_cast<TangibleObject*>(sceneObject);
	if (tangible == nullptr)
		return;

	String lockValue = tangible->getLuaStringData("item_locked");
	bool isLocked = !lockValue.isEmpty() && Integer::valueOf(lockValue) == 1;

	if (isLocked) {
		menuResponse->addRadialMenuItem(RADIAL_UNLOCK_ITEM, 3, "Unlock Item");
	} else {
		menuResponse->addRadialMenuItem(RADIAL_LOCK_ITEM, 3, "Lock Item");
	}
}

int ItemLockMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (!sceneObject->isASubChildOf(player))
		return 0;

	if (selectedID == RADIAL_LOCK_ITEM) {
		// Lock the item
		TangibleObject* tangible = dynamic_cast<TangibleObject*>(sceneObject);
		if (tangible == nullptr)
			return 0;

		tangible->setLuaStringData("item_locked", "1");

		// Set yellow highlight to show item is locked (using addMagicBit)
		tangible->addMagicBit(true);

		// Get item name for message
		String itemName = sceneObject->getDisplayedName();
		if (itemName.isEmpty())
			itemName = sceneObject->getObjectNameStringIdName();

		player->sendSystemMessage("Item locked: " + itemName + " - This item cannot be deleted or traded.");

		return 0;
	}
	else if (selectedID == RADIAL_UNLOCK_ITEM) {
		// Unlock the item
		TangibleObject* tangible = dynamic_cast<TangibleObject*>(sceneObject);
		if (tangible == nullptr)
			return 0;

		tangible->deleteLuaStringData("item_locked");

		// Remove yellow highlight (using removeMagicBit)
		tangible->removeMagicBit(true);

		// Get item name for message
		String itemName = sceneObject->getDisplayedName();
		if (itemName.isEmpty())
			itemName = sceneObject->getObjectNameStringIdName();

		player->sendSystemMessage("Item unlocked: " + itemName + " - This item can now be deleted or traded normally.");

		return 0;
	}

	return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
}
