/*
 * WearableObjectMenuComponent.cpp
 *
 * Clothing now uses the ArmorObjectMenuComponent UI/logic for color changes.
 * This component just preserves the default wearable/tangible menu behavior.
 */

#include "server/zone/objects/tangible/components/WearableObjectMenuComponent.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/tangible/wearables/WearableObject.h"
#include "server/zone/objects/creature/CreatureObject.h"

void WearableObjectMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	// Keep the normal wearable/tangible menu
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);
	// No extra clothing color entries here — clothing will use ArmorObjectMenuComponent instead.
}

int WearableObjectMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	// Defer to the base handler. Armor-style color handling will be done by ArmorObjectMenuComponent
	// when clothing is wired to use it (see steps below).
	return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
}
