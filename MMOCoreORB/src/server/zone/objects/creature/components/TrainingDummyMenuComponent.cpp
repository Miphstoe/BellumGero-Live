/*
 * TrainingDummyMenuComponent.cpp
 *
 * Manual reset radial for Bellum Gero Training Dummies.
 */

#include "TrainingDummyMenuComponent.h"

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "templates/params/creature/CreaturePosture.h"
#include "templates/params/creature/CreatureState.h"

namespace {
	void clearTrainingState(CreatureObject* dummy, uint64 state) {
		if (dummy == nullptr)
			return;

		dummy->removeStateBuff(state);
		dummy->clearState(state, true);
	}
}

void TrainingDummyMenuComponent::fillObjectMenuResponse(
	SceneObject* sceneObject,
	ObjectMenuResponse* menuResponse,
	CreatureObject* player
) const {
	TrainerMenuComponent::fillObjectMenuResponse(
		sceneObject,
		menuResponse,
		player
	);

	if (sceneObject == nullptr || player == nullptr)
		return;

	menuResponse->addRadialMenuItem(
		RESET_TRAINING_DUMMY,
		3,
		"Reset Training Dummy"
	);
}

int TrainingDummyMenuComponent::handleObjectMenuSelect(
	SceneObject* sceneObject,
	CreatureObject* player,
	byte selectedID
) const {
	if (selectedID != RESET_TRAINING_DUMMY)
		return TrainerMenuComponent::handleObjectMenuSelect(
			sceneObject,
			player,
			selectedID
		);

	if (
		sceneObject == nullptr ||
		player == nullptr ||
		!sceneObject->isCreatureObject()
	) {
		return 0;
	}

	CreatureObject* dummy = cast<CreatureObject*>(sceneObject);

	if (dummy == nullptr)
		return 0;

	if (!player->isInRange(dummy, 8.f)) {
		player->sendSystemMessage(
			"You are too far away to reset the Training Dummy."
		);
		return 0;
	}

	dummy->clearCombatState(true);
	dummy->setTargetID(0, true);
	dummy->clearDots();

	clearTrainingState(dummy, CreatureState::STUNNED);
	clearTrainingState(dummy, CreatureState::BLINDED);
	clearTrainingState(dummy, CreatureState::DIZZY);
	clearTrainingState(dummy, CreatureState::INTIMIDATED);
	clearTrainingState(dummy, CreatureState::IMMOBILIZED);
	clearTrainingState(dummy, CreatureState::FROZEN);

	for (int attribute = 0; attribute < 9; ++attribute)
		dummy->setWounds(attribute, 0, true);

	dummy->setShockWounds(0, true);

	for (int attribute = 0; attribute < 9; ++attribute)
		dummy->setHAM(attribute, dummy->getMaxHAM(attribute), true);

	dummy->setPosture(CreaturePosture::UPRIGHT, true, true);

	player->sendSystemMessage(
		"The Training Dummy has been reset to full HAM and cleared of combat effects."
	);

	return 0;
}
