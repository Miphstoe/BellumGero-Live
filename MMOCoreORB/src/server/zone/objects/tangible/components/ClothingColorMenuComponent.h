/*
 * ClothingColorMenuComponent.h
 * Radial: Cycle Primary/Secondary color for clothing wearables (not armor).
 */

#ifndef CLOTHINGCOLORMENUCOMPONENT_H_
#define CLOTHINGCOLORMENUCOMPONENT_H_

#include "server/zone/objects/scene/components/ObjectMenuComponent.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/tangible/wearables/WearableObject.h"
#include "server/zone/objects/creature/CreatureObject.h"

#include <unordered_map>
#include <cstdint>

class ClothingColorMenuComponent : public ObjectMenuComponent {
public:
	// Menu IDs: choose values unlikely to collide with other components
	static const uint8 RADIAL_CYCLE_PRIMARY   = 120;
	static const uint8 RADIAL_CYCLE_SECONDARY = 121;

	virtual void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
		ObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

		if (!sceneObject || !sceneObject->isTangibleObject())
			return;

		TangibleObject* tano = cast<TangibleObject*>(sceneObject);
		if (!tano || !tano->isWearableObject())
			return;

		// Exclude armor – mirror armor's after-creation recolor UX but only for clothing.
		if (tano->isArmorObject())
			return;

		// Only if player owns the item (equipped or in inventory/backpack)
		if (!ownsItem(player, tano))
			return;

		// Show both radials; setting a non-existent slot is a safe client no-op.
		menuResponse->addRadialMenuItem(RADIAL_CYCLE_PRIMARY, 3, "Cycle Primary Color");
		menuResponse->addRadialMenuItem(RADIAL_CYCLE_SECONDARY, 3, "Cycle Secondary Color");
	}

	virtual int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
		if (!sceneObject || !sceneObject->isTangibleObject())
			return 0;

		TangibleObject* tano = cast<TangibleObject*>(sceneObject);
		if (!tano || !tano->isWearableObject())
			return 0;

		// Respect ownership
		if (!ownsItem(player, tano)) {
			player->sendSystemMessage("You must own or have this item equipped.");
			return 0;
		}

		if (tano->isArmorObject())
			return 0; // leave armor to its existing flow

		// Determine slot and cycle using an in-memory tracker keyed by object id.
		String var;
		bool isPrimary = false;
		if (selectedID == RADIAL_CYCLE_PRIMARY) { var = "/private/index_color_1"; isPrimary = true; }
		else if (selectedID == RADIAL_CYCLE_SECONDARY) { var = "/private/index_color_2"; isPrimary = false; }
		else return 0;

		const uint64 oid = sceneObject->getObjectID();
		const uint64_t key = static_cast<uint64_t>(oid);

		uint8 current = 0;
		if (isPrimary) {
			current = getPrimaryMap()[key];
			current = static_cast<uint8>((current + 1) & 0xFF);
			getPrimaryMap()[key] = current;
		} else {
			current = getSecondaryMap()[key];
			current = static_cast<uint8>((current + 1) & 0xFF);
			getSecondaryMap()[key] = current;
		}

		tano->setCustomizationVariable(var, static_cast<short>(current), /*notifyClient=*/true);

		player->sendSystemMessage("Set " + var + " to " + String::valueOf(static_cast<int>(current)) + ".");
		return 1;
	}

private:
	// Per-item, per-slot color index trackers (in-memory; resets on server restart)
	static std::unordered_map<uint64_t, uint8>& getPrimaryMap() {
		static std::unordered_map<uint64_t, uint8> m;
		return m;
	}
	static std::unordered_map<uint64_t, uint8>& getSecondaryMap() {
		static std::unordered_map<uint64_t, uint8> m;
		return m;
	}

	static bool ownsItem(CreatureObject* player, TangibleObject* item) {
		if (!player || !item) return false;

		// Equipped (item is a sub-child of the player) OR directly in player's inventory
		if (item->isASubChildOf(player))
			return true;

		uint64 parentId = item->getParentID();
		if (parentId == 0)
			return false;

		return parentId == player->getObjectID();
	}
};

#endif /* CLOTHINGCOLORMENUCOMPONENT_H_ */
