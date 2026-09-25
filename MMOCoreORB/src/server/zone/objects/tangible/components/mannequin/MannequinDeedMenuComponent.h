/*
 * MannequinDeedMenuComponent.h
 *
 * Bellum Gero - Persistent Player Display Mannequin (Phase 2 PoC)
 *
 * Radial "Deploy Mannequin" for a mannequin deed. The deed may only be deployed while
 * the player stands inside a player structure cell they administer. Deploy creates the
 * persistent MannequinObject as a child of that cell and consumes the deed.
 */

#ifndef MANNEQUINDEEDMENUCOMPONENT_H_
#define MANNEQUINDEEDMENUCOMPONENT_H_

#include "server/zone/objects/tangible/components/TangibleObjectMenuComponent.h"

class MannequinDeedMenuComponent : public TangibleObjectMenuComponent {
public:
	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const override;

	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const override;
};

#endif /* MANNEQUINDEEDMENUCOMPONENT_H_ */
