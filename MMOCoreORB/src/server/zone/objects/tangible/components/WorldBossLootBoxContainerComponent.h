/*
 * WorldBossLootBoxContainerComponent.h
 *
 * Custom container component for world boss loot boxes
 * Integrates with Lua-based loot manager for eligibility checking and loot distribution
 */

#ifndef WORLDBOSSLOOTBOXCONTAINERCOMPONENT_H_
#define WORLDBOSSLOOTBOXCONTAINERCOMPONENT_H_

#include "server/zone/objects/scene/components/ContainerComponent.h"

class WorldBossLootBoxContainerComponent : public ContainerComponent {
public:
	int notifyObjectInserted(SceneObject* sceneObject, SceneObject* object) const;
	int notifyObjectRemoved(SceneObject* sceneObject, SceneObject* object, SceneObject* destination) const;
	bool checkContainerPermission(SceneObject* sceneObject, CreatureObject* creature, uint16 permission) const;
	int canAddObject(SceneObject* sceneObject, SceneObject* object, int containmentType, String& errorDescription) const;
	int notifyContainerOpened(SceneObject* sceneObject, CreatureObject* player) const;
};

#endif /* WORLDBOSSLOOTBOXCONTAINERCOMPONENT_H_ */
