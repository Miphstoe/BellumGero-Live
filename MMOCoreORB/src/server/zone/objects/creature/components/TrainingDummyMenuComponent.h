/*
 * TrainingDummyMenuComponent.h
 *
 * Manual reset radial for Bellum Gero Training Dummies.
 */

#ifndef TRAININGDUMMYMENUCOMPONENT_H_
#define TRAININGDUMMYMENUCOMPONENT_H_

#include "server/zone/objects/creature/components/TrainerMenuComponent.h"

class TrainingDummyMenuComponent : public TrainerMenuComponent {
public:
	enum MenuOption : byte {
		RESET_TRAINING_DUMMY = 20
	};

	void fillObjectMenuResponse(
		SceneObject* sceneObject,
		ObjectMenuResponse* menuResponse,
		CreatureObject* player
	) const override;

	int handleObjectMenuSelect(
		SceneObject* sceneObject,
		CreatureObject* player,
		byte selectedID
	) const override;
};

#endif /* TRAININGDUMMYMENUCOMPONENT_H_ */

