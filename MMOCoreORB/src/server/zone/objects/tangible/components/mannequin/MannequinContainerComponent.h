/*
 * MannequinContainerComponent.h
 *
 * Bellum Gero - Persistent Player Display Mannequin (Phase 2 PoC)
 *
 * Gates who may move items on/off a mannequin and restricts its slots to real
 * wearable / weapon objects. It deliberately does NOT extend PlayerContainerComponent
 * and never calls applySkillModsTo / applyEncumbrancies / addWearableObject, so
 * equipment displayed on a mannequin produces ZERO gameplay effect. Slot-conflict
 * validation is inherited unchanged from ContainerComponent (fails safe, never
 * destroys a conflicting item).
 */

#ifndef MANNEQUINCONTAINERCOMPONENT_H_
#define MANNEQUINCONTAINERCOMPONENT_H_

#include "server/zone/objects/scene/components/ContainerComponent.h"

class MannequinContainerComponent : public ContainerComponent {
public:
	int canAddObject(SceneObject* sceneObject, SceneObject* object, int containmentType, String& errorDescription) const override;

	bool checkContainerPermission(SceneObject* sceneObject, CreatureObject* creature, uint16 permission) const override;

	// True when player is the mannequin owner, on the enclosing structure's ADMIN list, or privileged.
	static bool isAuthorized(SceneObject* mannequin, CreatureObject* player);
};

#endif /* MANNEQUINCONTAINERCOMPONENT_H_ */
