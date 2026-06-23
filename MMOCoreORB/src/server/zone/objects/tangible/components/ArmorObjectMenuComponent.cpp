/*
 * ArmorObjectMenuComponent.cpp
 *
 *  Created on: 2/4/2013
 *      Author: bluree
 *      Credits: TA & Valk
 */

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/player/sui/colorbox/SuiColorBox.h"
#include "ArmorObjectMenuComponent.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/player/sui/callbacks/ColorArmorSuiCallback.h"
#include "server/zone/ZoneServer.h"
#include "templates/customization/AssetCustomizationManagerTemplate.h"

// SEA extraction bits
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/player/sui/callbacks/ExtractSEASuiCallback.h"
#include "templates/SharedObjectTemplate.h"

// ---------- SEA constants & helpers ----------
namespace {
	static const uint8 MENU_EXTRACT_SEA    = 165;
	static const uint8 ARMOR_LOCK_ITEM     = 220;
	static const uint8 ARMOR_UNLOCK_ITEM   = 221;
	static const char* TOOL_SERVER_IFF = "object/tangible/item/sea_removal_tool.iff";
	static const char* TOOL_SHARED_IFF = "object/tangible/item/shared_sea_removal_tool.iff";

	inline bool isSEATool(SceneObject* so) {
		if (so == nullptr) return false;
		SharedObjectTemplate* tmpl = so->getObjectTemplate();
		if (!tmpl) return false;
		const String full = tmpl->getFullTemplateString();
		// Be tolerant: some forks report the shared path; others the server path.
		return full == TOOL_SERVER_IFF || full == TOOL_SHARED_IFF ||
		       full.indexOf("sea_removal_tool.iff") != -1;
	}

	// Depth-first search for the tool anywhere under this container
	bool containerHasSEATool(SceneObject* container) {
		if (container == nullptr) return false;

		const int n = container->getContainerObjectsSize();
		for (int i = 0; i < n; ++i) {
			SceneObject* child = container->getContainerObject(i);
			if (!child) continue;

			if (isSEATool(child))
				return true;

			if (child->isContainerObject()) {
				if (containerHasSEATool(child))
					return true;
			}
		}
		return false;
	}
} // namespace
// --------------------------------------------

void ArmorObjectMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	// Allow any wearable (armor or clothing)
	if (!sceneObject || !sceneObject->isWearableObject() || player == nullptr)
		return;

	// Ownership / admin checks (same as before)
	ManagedReference<SceneObject*> parent = sceneObject->getParent().get();

	if (parent != nullptr && parent->isCellObject()) {
		ManagedReference<SceneObject*> obj = parent->getParent().get();

		if (obj != nullptr && obj->isBuildingObject()) {
			ManagedReference<BuildingObject*> buio = cast<BuildingObject*>(obj.get());

			if (!buio->isOnAdminList(player))
				return;
		}
	} else {
		if (!sceneObject->isASubChildOf(player))
			return;
	}

	// ----- SEA extraction radial (when item is anywhere in player's inventory and tool exists) -----
	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");
	if (inventory != nullptr && sceneObject->isASubChildOf(inventory)) {
		if (containerHasSEATool(inventory)) {
			menuResponse->addRadialMenuItem(MENU_EXTRACT_SEA, 3, "Extract SEA(s) (destroys item)");
		}
	}
	// -----------------------------------------------------------------------------------------------

	// Your existing color options
	menuResponse->addRadialMenuItem(81, 3, "Color Change");
	menuResponse->addRadialMenuItem(82, 3, "Color Change (Secondary)");

	// Lock / Unlock option
	if (sceneObject->isASubChildOf(player)) {
		TangibleObject* tangible = dynamic_cast<TangibleObject*>(sceneObject);
		if (tangible != nullptr) {
			String lockValue = tangible->getLuaStringData("item_locked");
			bool isLocked = !lockValue.isEmpty() && Integer::valueOf(lockValue) == 1;
			if (isLocked)
				menuResponse->addRadialMenuItem(ARMOR_UNLOCK_ITEM, 3, "Unlock Item");
			else
				menuResponse->addRadialMenuItem(ARMOR_LOCK_ITEM, 3, "Lock Item");
		}
	}

	// Preserve normal wearable/tangible menu behavior
	WearableObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);
}

int ArmorObjectMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (!sceneObject || player == nullptr)
		return 0;

	// ----- SEA extraction flow -----
	if (selectedID == MENU_EXTRACT_SEA) {
		ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");
		if (inventory == nullptr) return 0;

		// verify tool present (recursive, works inside backpacks)
		if (!containerHasSEATool(inventory)) {
			player->sendSystemMessage("SEA: You need a SEA Removal Tool in your inventory.");
			return 0;
		}

		// Confirm SUI
		ManagedReference<SuiMessageBox*> box = new SuiMessageBox(player, SuiWindowType::NONE);
		box->setPromptText("This will extract all skill modifiers into new attachments, and DESTROY the wearable and the tool. Proceed?");
		box->setOkButton(true, "@ok");
		box->setCancelButton(true, "@cancel");

		// ‘using object’ = the wearable; callback will fetch it from the SUI
		box->setUsingObject(sceneObject);
		box->setCallback(new ExtractSEASuiCallback(player->getZoneServer()));

		player->getPlayerObject()->addSuiBox(box);
		player->sendMessage(box->generateMessage());
		return 0;
	}
	// -------------------------------------------------------------------

	// Lock / Unlock handling
	if (selectedID == ARMOR_LOCK_ITEM || selectedID == ARMOR_UNLOCK_ITEM) {
		if (sceneObject->isASubChildOf(player)) {
			TangibleObject* tangible = dynamic_cast<TangibleObject*>(sceneObject);
			if (tangible != nullptr) {
				if (selectedID == ARMOR_LOCK_ITEM) {
					tangible->setLuaStringData("item_locked", "1");
					tangible->addMagicBit(true);
					player->sendSystemMessage("Item locked: " + tangible->getDisplayedName() + " - This item cannot be deleted or traded.");
				} else {
					tangible->deleteLuaStringData("item_locked");
					tangible->removeMagicBit(true);
					player->sendSystemMessage("Item unlocked: " + tangible->getDisplayedName() + " - This item can now be deleted or traded normally.");
				}
				return 0;
			}
		}
	}

	// Existing color logic (unchanged)
	if (selectedID == 81 || selectedID == 82) {
		ManagedReference<SceneObject*> parent = sceneObject->getParent().get();

		if (parent == nullptr)
			return 0;

		// Original equip/inventory/location rules
		if (parent->isPlayerCreature()) {
			player->sendSystemMessage("@armor_rehue:equipped");
			return 0;
		}

		if (parent->isCellObject()) {
			ManagedReference<SceneObject*> obj = parent->getParent().get();

			if (obj != nullptr && obj->isBuildingObject()) {
				ManagedReference<BuildingObject*> buio = cast<BuildingObject*>(obj.get());

				if (!buio->isOnAdminList(player))
					return 0;
			}
		} else {
			if (!sceneObject->isASubChildOf(player))
				return 0;
		}

		ZoneServer* server = player->getZoneServer();

		if (server != nullptr) {
			// Gather customization variables for this wearable's appearance
			String appearanceFilename = sceneObject->getObjectTemplate()->getAppearanceFilename();
			VectorMap<String, Reference<CustomizationVariable*> > variables;
			AssetCustomizationManagerTemplate::instance()->getCustomizationVariables(appearanceFilename.hashCode(), variables, false);

			// Choose palette key
			String palette;
			for (int i = 0; i < variables.size(); ++i) {
				String key = variables.elementAt(i).getKey();
				if (selectedID == 81 && key.indexOf("index_color_1") != -1) { palette = key; break; }
				if (selectedID == 82 && key.indexOf("index_color_2") != -1) { palette = key; break; }
			}
			if (palette.isEmpty() && variables.size() > 0)
				palette = variables.elementAt(0).getKey();
			if (palette.isEmpty())
				return 0; // nothing we can edit

			// Build the color picker SUI
			ManagedReference<SuiColorBox*> cbox = new SuiColorBox(player, SuiWindowType::COLOR_ARMOR);
			cbox->setCallback(new ColorArmorSuiCallback(server));
			cbox->setColorPalette(palette);
			cbox->setUsingObject(sceneObject);

			// Skill cap (kept as your original)
			int skillMod = 255; // player->getSkillMod("armor_customization");
			cbox->setSkillMod(skillMod);

			// Send to player
			ManagedReference<PlayerObject*> ghost = player->getPlayerObject();
			if (ghost != nullptr) {
				ghost->addSuiBox(cbox);
				player->sendMessage(cbox->generateMessage());
			}
		}
	}

	// Defer other options to the base wearable menu component
	return WearableObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
}
