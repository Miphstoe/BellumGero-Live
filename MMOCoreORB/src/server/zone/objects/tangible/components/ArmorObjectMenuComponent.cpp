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

void ArmorObjectMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	// Allow any wearable (armor or clothing)
	if (!sceneObject || !sceneObject->isWearableObject())
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

	// Primary color picker
	menuResponse->addRadialMenuItem(81, 3, "Color Change");

	// Secondary color picker (will fall back safely if the item has no index_color_2)
	menuResponse->addRadialMenuItem(82, 3, "Color Change (Secondary)");

	// Preserve normal wearable/tangible menu behavior
	WearableObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);
}

int ArmorObjectMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {

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

			// Choose palette:
			//  - For 81, prefer key containing "index_color_1"
			//  - For 82, prefer key containing "index_color_2"
			//  - Fallback to first available variable if specific one not found
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
