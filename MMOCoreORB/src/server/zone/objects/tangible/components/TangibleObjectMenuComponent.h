/*
 * TangibleObjectMenuComponent.h
 *
 *  Created on: 26/05/2011
 *      Author: victor
 */

#ifndef TANGIBLEOBJECTMENUCOMPONENT_H_
#define TANGIBLEOBJECTMENUCOMPONENT_H_

#include "server/zone/objects/scene/components/ObjectMenuComponent.h"
#include "server/zone/managers/radial/RadialOptions.h"

namespace server {
 namespace zone {
  namespace objects {
   namespace tangible {
    class TangibleObject;
   }
  }
 }
}

using namespace server::zone::objects::tangible;

class TangibleObjectMenuComponent : public ObjectMenuComponent {
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

	/**
	 * Checks if the player has permission to rename the given object
	 * @param player The player attempting to rename
	 * @param object The tangible object being renamed
	 * @returns true if player has permission (object in inventory or admin in structure)
	 */
	static bool hasRenamePermission(CreatureObject* player, TangibleObject* object);

	/**
	 * Prompts the player with a rename dialog for the given object
	 * @param player The player to show the dialog to
	 * @param object The tangible object to rename
	 */
	static void promptRenameObject(CreatureObject* player, TangibleObject* object);

	/**
	 * Unstacks a stackable item into individual items
	 * @param sceneObject The stacked object
	 * @param player The player unstacking the items
	 * @param tano The tangible object being unstacked
	 */
	void unstackItems(SceneObject* sceneObject, CreatureObject* player, TangibleObject* tano) const;

};


#endif /* TANGIBLEOBJECTMENUCOMPONENT_H_ */
