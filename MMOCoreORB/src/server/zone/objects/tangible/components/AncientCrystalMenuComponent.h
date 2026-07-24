/*
 * AncientCrystalMenuComponent.h
 *
 *  Created on: 07/08/2026
 *      Author: Miphstoe
 */

#ifndef ANCIENTCRYSTALMENUCOMPONENT_H_
#define ANCIENTCRYSTALMENUCOMPONENT_H_

#include "TangibleObjectMenuComponent.h"

class AncientCrystalMenuComponent : public TangibleObjectMenuComponent {
public:
	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;
	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;
};

#endif /* ANCIENTCRYSTALMENUCOMPONENT_H_ */
