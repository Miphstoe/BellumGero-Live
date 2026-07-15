/*
 * RobeObjectMenuComponent.cpp
 *
 *  Created on: Apr 5, 2012
 *      Author: katherine
 */

#include "RobeObjectMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/player/sui/callbacks/ExtractSEASuiCallback.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "templates/SharedObjectTemplate.h"

namespace {
	static const uint8 MENU_EXTRACT_SEA = 165;

	bool isSEATool(SceneObject* sceneObject) {
		if (sceneObject == nullptr)
			return false;

		SharedObjectTemplate* tmpl = sceneObject->getObjectTemplate();
		if (tmpl == nullptr)
			return false;

		return tmpl->getFullTemplateString().indexOf("sea_removal_tool.iff") != -1;
	}

	bool containerHasSEATool(SceneObject* container) {
		if (container == nullptr)
			return false;

		const int size = container->getContainerObjectsSize();

		for (int i = 0; i < size; ++i) {
			SceneObject* child = container->getContainerObject(i);

			if (child == nullptr)
				continue;

			if (isSEATool(child))
				return true;

			if (child->isContainerObject() && containerHasSEATool(child))
				return true;
		}

		return false;
	}
}

void RobeObjectMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	if (sceneObject == nullptr || player == nullptr || !sceneObject->isWearableObject())
		return;

	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");

	if (inventory != nullptr && sceneObject->isASubChildOf(inventory) && containerHasSEATool(inventory))
		menuResponse->addRadialMenuItem(MENU_EXTRACT_SEA, 3, "Extract SEA(s) (destroys item)");
}


int RobeObjectMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (selectedID == MENU_EXTRACT_SEA) {
		if (sceneObject == nullptr || player == nullptr)
			return 0;

		ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");

		if (inventory == nullptr || !containerHasSEATool(inventory)) {
			player->sendSystemMessage("SEA: You need a SEA Removal Tool in your inventory.");
			return 0;
		}

		if (!sceneObject->isASubChildOf(inventory)) {
			player->sendSystemMessage("SEA: Robe must be in your inventory.");
			return 0;
		}

		ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return 0;

		ManagedReference<SuiMessageBox*> box = new SuiMessageBox(player, SuiWindowType::NONE);
		box->setPromptText("This will extract all skill modifiers into new attachments, and DESTROY the robe and the tool. Proceed?");
		box->setOkButton(true, "@ok");
		box->setCancelButton(true, "@cancel");
		box->setUsingObject(sceneObject);
		box->setCallback(new ExtractSEASuiCallback(player->getZoneServer()));

		ghost->addSuiBox(box);
		player->sendMessage(box->generateMessage());
		return 0;
	}

	return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
}
