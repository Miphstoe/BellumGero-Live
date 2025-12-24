/*
 * ItemLockMenuComponent.cpp
 */

#include "ItemLockMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"

void ItemLockMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	// Always call parent to add default options (rename, slicing, etc.)
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	// Lock/unlock options only for items in player's inventory
	if (!sceneObject->isASubChildOf(player))
		return;

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
	// Handle lock/unlock (only for items in inventory)
	if (sceneObject->isASubChildOf(player) && (selectedID == RADIAL_LOCK_ITEM || selectedID == RADIAL_UNLOCK_ITEM)) {
		TangibleObject* tangible = dynamic_cast<TangibleObject*>(sceneObject);
		if (tangible == nullptr)
			return 0;

		if (selectedID == RADIAL_LOCK_ITEM) {
			// Lock the item
			tangible->setLuaStringData("item_locked", "1");

			// Set yellow highlight to show item is locked (using addMagicBit)
			tangible->addMagicBit(true);

			// Get item name for message
			String itemName = sceneObject->getDisplayedName();
			if (itemName.isEmpty())
				itemName = sceneObject->getObjectNameStringIdName();

			player->sendSystemMessage("Item locked: " + itemName + " - This item cannot be deleted or traded.");

			return 0;
		} else if (selectedID == RADIAL_UNLOCK_ITEM) {
			// Unlock the item
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
	}

	// For all other selections (rename, slicing, etc.), pass to parent
	return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
}
