/*
 * WorldBossLootBoxContainerComponent.cpp
 *
 * Custom container component for world boss loot boxes
 * Integrates with Lua-based loot manager for eligibility checking and loot distribution
 */

#include "WorldBossLootBoxContainerComponent.h"
#include "server/zone/objects/tangible/Container.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/stringid/StringIdManager.h"
#include "server/zone/managers/director/DirectorManager.h"

int WorldBossLootBoxContainerComponent::notifyObjectInserted(SceneObject* sceneObject, SceneObject* object) const {
	return 0;
}

int WorldBossLootBoxContainerComponent::notifyObjectRemoved(SceneObject* sceneObject, SceneObject* object, SceneObject* destination) const {
	return 0;
}

bool WorldBossLootBoxContainerComponent::checkContainerPermission(SceneObject* sceneObject, CreatureObject* creature, uint16 permission) const {
	if (!sceneObject->isContainerObject())
		return false;

	ManagedReference<Container*> container = cast<Container*>(sceneObject);

	if (permission == ContainerPermissions::MOVEIN) {
		return false;
	} else if (permission == ContainerPermissions::MOVEOUT) {
		return false;
	} else if (permission == ContainerPermissions::OPEN) {
		return !container->isContainerLocked();
	}

	return false;
}

int WorldBossLootBoxContainerComponent::canAddObject(SceneObject* sceneObject, SceneObject* object, int containmentType, String& errorDescription) const {
	errorDescription = "You cannot add items to this loot box.";
	return TransferErrorCode::INVALIDTYPE;
}

int WorldBossLootBoxContainerComponent::notifyContainerOpened(SceneObject* sceneObject, CreatureObject* player) const {
	if (sceneObject == nullptr || player == nullptr)
		return 1;

	if (!player->isPlayerCreature())
		return 1;

	Lua* lua = DirectorManager::instance()->getLuaInstance();

	if (lua == nullptr)
		return 1;

	Reference<LuaFunction*> onPlayerInteract = lua->createFunction("WorldBossLootManager", "onPlayerInteract", 0);

	if (onPlayerInteract == nullptr) {
		player->sendSystemMessage("Error: WorldBossLootManager not loaded.");
		return 1;
	}

	*onPlayerInteract << sceneObject;
	*onPlayerInteract << player;

	onPlayerInteract->callFunction();

	return 0;
}
