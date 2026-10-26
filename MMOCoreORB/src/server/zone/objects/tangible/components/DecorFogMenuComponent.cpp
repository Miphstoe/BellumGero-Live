/*
 * DecorFogMenuComponent.cpp
 */

#include "DecorFogMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "templates/params/OptionBitmask.h"

bool DecorFogMenuComponent::canToggleFog(SceneObject* sceneObject, CreatureObject* player) {
	if (sceneObject->isASubChildOf(player))
		return true;

	ManagedReference<SceneObject*> rootParent = sceneObject->getRootParent();

	if (rootParent == nullptr || !rootParent->isBuildingObject())
		return false;

	BuildingObject* building = cast<BuildingObject*>(rootParent.get());

	return building != nullptr && (building->isOwnerOf(player) || building->isOnAdminList(player));
}

void DecorFogMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	if (!sceneObject->isTangibleObject() || !canToggleFog(sceneObject, player))
		return;

	menuResponse->addRadialMenuItem(RADIAL_TOGGLE_FOG, 3, "Toggle Fog");
}

int DecorFogMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (selectedID != RADIAL_TOGGLE_FOG)
		return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);

	if (!sceneObject->isTangibleObject() || !canToggleFog(sceneObject, player))
		return 0;

	TangibleObject* tano = cast<TangibleObject*>(sceneObject);

	Locker locker(tano, player);

	if (tano->getOptionsBitmask() & OptionBitmask::ACTIVATED) {
		tano->clearOptionBit(OptionBitmask::ACTIVATED, true);
		player->sendSystemMessage("The fog fades away.");
	} else {
		tano->setOptionBit(OptionBitmask::ACTIVATED, true);
		player->sendSystemMessage("A cold fog begins to drift.");
	}

	return 0;
}
