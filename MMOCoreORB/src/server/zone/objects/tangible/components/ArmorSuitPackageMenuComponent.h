/*
 * ArmorSuitPackageMenuComponent.h
 *
 * Bellum Gero full-suit crafting package radial.
 */

#ifndef ARMORSUITPACKAGEMENUCOMPONENT_H_
#define ARMORSUITPACKAGEMENUCOMPONENT_H_

#include "TangibleObjectMenuComponent.h"

class ArmorSuitPackageMenuComponent : public TangibleObjectMenuComponent {
public:
	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse,
		CreatureObject* player) const;

	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player,
		byte selectedID) const;
};

#endif /* ARMORSUITPACKAGEMENUCOMPONENT_H_ */
