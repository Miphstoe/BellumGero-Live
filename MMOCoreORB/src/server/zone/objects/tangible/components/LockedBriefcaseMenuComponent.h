/*
 * LockedBriefcaseMenuComponent.h
 *
 *  Created on: 02/22/2026
 *      Author: Miphstoe
 *
 * Handles the radial menu and slice initiation for the Locked Briefcase junk item.
 * Restricts the Slice option to smugglers (combat_smuggler_novice) and tags the
 * object for tiered credit reward handling in SlicingSessionImplementation.
 */

#ifndef LOCKEDBRIEFCASEMENUCOMPONENT_H_
#define LOCKEDBRIEFCASEMENUCOMPONENT_H_

#include "TangibleObjectMenuComponent.h"

class LockedBriefcaseMenuComponent : public TangibleObjectMenuComponent {
public:
	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;
	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;
};

#endif /* LOCKEDBRIEFCASEMENUCOMPONENT_H_ */
