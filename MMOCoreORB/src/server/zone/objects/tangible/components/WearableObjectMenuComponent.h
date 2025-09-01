/*
 * WearableObjectMenuComponent.h
 *
 *  Created on: 1/17/2012
 *      Author: kyle
 */

#ifndef WEARABLEOBJECTMENUCOMPONENT_H_
#define WEARABLEOBJECTMENUCOMPONENT_H_

#include "TangibleObjectMenuComponent.h"

// ADD THESE so types are complete in this header:
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/creature/CreatureObject.h"

#include <unordered_map>
#include <cstdint>

// Per-item color trackers (in-memory; resets on server restart)
static std::unordered_map<uint64, uint8_t> BG_ColorCycle_Primary;
static std::unordered_map<uint64, uint8_t> BG_ColorCycle_Secondary;

// Helper: ownership check (equipped or in player inventory)
static inline bool bgOwnsWearable(CreatureObject* player, TangibleObject* item) {
	if (!player || !item) return false;
	if (item->isASubChildOf(player)) return true;
	uint64 parentId = item->getParentID();
	return parentId != 0 && parentId == player->getObjectID();
}

class WearableObjectMenuComponent : public TangibleObjectMenuComponent {
public:
	/**
	 * Fills the radial options, needs to be overriden
	 * @pre { this object is locked }
	 * @post { this object is locked, menuResponse is complete}
	 * @param menuResponse ObjectMenuResponse that will be sent to the client
	 */
	virtual void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;

	/**
	 * Handles the radial selection sent by the client, must be overriden by inherited objects
	 * @pre { this object is locked, player is locked }
	 * @post { this object is locked, player is locked }
	 * @param player PlayerCreature that selected the option
	 * @param selectedID selected menu id
	 * @returns 0 if successfull
	 */
	virtual int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;
};

#endif /* WEARABLEOBJECTMENUCOMPONENT_H_ */
