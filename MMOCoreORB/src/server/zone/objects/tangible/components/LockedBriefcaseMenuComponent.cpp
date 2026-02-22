/*
 * LockedBriefcaseMenuComponent.cpp
 *
 *  Created on: 02/22/2026
 *      Author: Miphstoe
 *
 * Handles the radial menu and slice initiation for the Locked Briefcase junk item.
 * Only smugglers (combat_smuggler_novice) can see and use the Slice option.
 * On initiation the object is tagged with LuaStringData so SlicingSessionImplementation
 * can identify it and apply the tiered credit reward on success or destroy it on failure.
 */

#include "LockedBriefcaseMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/player/sessions/SlicingSession.h"
#include "server/zone/objects/scene/SessionFacadeType.h"

void LockedBriefcaseMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	// Delegate to TangibleObjectMenuComponent which correctly handles sliceable
	// inventory items. It will add the Slice option (menu ID 69) for any item
	// where isSliceable() returns true. handleObjectMenuSelect then guards the
	// actual session start behind combat_smuggler_novice.
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);
}

int LockedBriefcaseMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (selectedID == 69) { // Slice
		if (!player->hasSkill("combat_smuggler_novice")) {
			player->sendSystemMessage("You lack the slicing expertise to crack open this briefcase.");
			return 0;
		}

		if (player->containsActiveSession(SessionFacadeType::SLICING)) {
			player->sendSystemMessage("@slicing/slicing:already_slicing");
			return 0;
		}

		// Item must be in the player's inventory
		ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");
		if (inventory == nullptr || !inventory->hasObjectInContainer(sceneObject->getObjectID())) {
			player->sendSystemMessage("The briefcase must be in your inventory to slice it.");
			return 0;
		}

		TangibleObject* tano = dynamic_cast<TangibleObject*>(sceneObject);
		if (tano == nullptr)
			return 0;

		if (!tano->isSliceable())
			tano->setSliceable(true);

		// Tag so SlicingSessionImplementation can identify this as a credit-bearing briefcase
		tano->setLuaStringData("is_credit_briefcase", "1");

		// Start the standard cable slicing mini-game
		ManagedReference<SlicingSession*> session = new SlicingSession(player);
		session->initalizeSlicingMenu(player, tano);

		return 0;
	}

	return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
}
