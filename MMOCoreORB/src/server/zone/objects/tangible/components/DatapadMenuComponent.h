/*
 * DatapadMenuComponent.h
 *
 * Handles radial menu options for datapad objects
 */

#ifndef DATAPADMENUCOMPONENT_H_
#define DATAPADMENUCOMPONENT_H_

#include "TangibleObjectMenuComponent.h"

class DatapadMenuComponent : public TangibleObjectMenuComponent {
public:
	/**
	 * Fills the radial options for datapad objects
	 * @pre { this object is locked }
	 * @post { this object is locked, menuResponse is complete}
	 * @param sceneObject the datapad object
	 * @param menuResponse ObjectMenuResponse that will be sent to the client
	 * @param player the player using the object
	 */
	virtual void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const;

	/**
	 * Handles the radial selection sent by the client
	 * @pre { this object is locked, player is locked }
	 * @post { this object is locked, player is locked }
	 * @param sceneObject the datapad object
	 * @param player PlayerCreature that selected the option
	 * @param selectedID selected menu id
	 * @returns 0 if successful
	 */
	virtual int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const;
};

#endif /* DATAPADMENUCOMPONENT_H_ */
