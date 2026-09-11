/*
 * MannequinMenuComponent.h
 *
 * Bellum Gero - Persistent Player Display Mannequin (Phase 2 PoC)
 *
 * Radial menu for a deployed mannequin. Management options are only shown to, and only
 * acted on for, authorized players (mannequin owner / structure ADMIN list / privileged).
 */

#ifndef MANNEQUINMENUCOMPONENT_H_
#define MANNEQUINMENUCOMPONENT_H_

#include "server/zone/objects/tangible/components/TangibleObjectMenuComponent.h"

class MannequinMenuComponent : public TangibleObjectMenuComponent {
public:
	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const override;

	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const override;

private:
	void sendEquipList(SceneObject* mannequin, CreatureObject* player, bool weaponMode) const;
	void sendRemoveList(SceneObject* mannequin, CreatureObject* player) const;
	void removeAll(SceneObject* mannequin, CreatureObject* player) const;
	void pickUp(SceneObject* mannequin, CreatureObject* player) const;
};

#endif /* MANNEQUINMENUCOMPONENT_H_ */
