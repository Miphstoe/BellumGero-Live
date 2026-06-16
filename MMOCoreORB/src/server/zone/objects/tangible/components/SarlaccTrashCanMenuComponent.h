/*
 * SarlaccTrashCanMenuComponent.h
 *
 *  Created on: 06/15/2026
 *      Author: Miphstoe
 */

#ifndef SARLACCTRASHCANMENUCOMPONENT_H_
#define SARLACCTRASHCANMENUCOMPONENT_H_

#include "TangibleObjectMenuComponent.h"

class SarlaccTrashCanMenuComponent : public TangibleObjectMenuComponent {
public:
	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;
	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;
};

#endif /* SARLACCTRASHCANMENUCOMPONENT_H_ */
