/*
 * 				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#include "DroidMedicalModuleDataComponent.h"
#include "server/zone/objects/tangible/component/droid/DroidComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/ai/AiAgent.h"
#include "server/zone/objects/creature/ai/DroidObject.h"
#include "server/zone/objects/player/PlayerObject.h"

namespace {
	int getHighestActiveMedicalRating(CreatureObject* player, DroidObject* excludedDroid = nullptr) {
		if (player == nullptr)
			return 0;

		PlayerObject* ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return 0;

		int highestRating = 0;

		for (int i = 0; i < ghost->getActivePetsSize(); ++i) {
			ManagedReference<AiAgent*> activePet = ghost->getActivePet(i);

			if (activePet == nullptr || !activePet->isDroidObject())
				continue;

			DroidObject* activeDroid = cast<DroidObject*>(activePet.get());

			if (activeDroid == nullptr || activeDroid == excludedDroid ||
					activeDroid->isDead() || activeDroid->isIncapacitated() ||
					!activeDroid->hasPower() || !player->isInRange(activeDroid, 15))
				continue;

			Reference<BaseDroidModuleComponent*> module =
				activeDroid->getModule("medical_module");

			DroidMedicalModuleDataComponent* medicalModule =
				cast<DroidMedicalModuleDataComponent*>(module.get());

			if (medicalModule == nullptr)
				continue;

			int activeRating = medicalModule->getMedicalRating();

			if (activeRating > highestRating)
				highestRating = activeRating;
		}

		return highestRating;
	}

	void refreshActiveMedicalRating(CreatureObject* player, DroidObject* excludedDroid = nullptr) {
		if (player == nullptr)
			return;

		// Remove only the contribution previously applied by a Medical Droid.
		// Other sources of private_medical_rating, such as buildings or camps,
		// must remain untouched while the active droid rating is recalculated.
		int currentRating = player->getSkillModOfType(
			"private_medical_rating",
			SkillModManager::DROID
		);

		if (currentRating > 0) {
			player->removeSkillMod(
				SkillModManager::DROID,
				"private_medical_rating",
				currentRating,
				true
			);
		}

		int highestRating = getHighestActiveMedicalRating(player, excludedDroid);

		if (highestRating > 0) {
			player->addSkillMod(
				SkillModManager::DROID,
				"private_medical_rating",
				highestRating,
				true
			);
		}
	}
}

DroidMedicalModuleDataComponent::DroidMedicalModuleDataComponent() {
	setLoggingName("DroidMedicalModule");
	rating = 0;
}

DroidMedicalModuleDataComponent::~DroidMedicalModuleDataComponent() {

}

String DroidMedicalModuleDataComponent::getModuleName() const {
	return String("medical_module");
}

void DroidMedicalModuleDataComponent::initializeTransientMembers() {
	DroidComponent* droidComponent = cast<DroidComponent*>(getParent());

	if (droidComponent == nullptr) {
		info("droidComponent was null");
		return;
	}

	if (droidComponent->hasKey("medical_module")) {
		rating = droidComponent->getAttributeValue("medical_module");
	}
}

void DroidMedicalModuleDataComponent::updateCraftingValues(CraftingValues* values, bool firstUpdate) {
	rating = values->getCurrentValue("medical_module");
}

int DroidMedicalModuleDataComponent::getMedicalRating() {
	if (rating <= 0)
		return 0;

	switch (rating) {
		case 1:
		case 2:
			return 55;
		case 3:
		case 4:
			return 65;
		case 5:
		case 6:
			return 75;
		case 7:
		case 8:
			return 85;
		case 9:
		case 10:
			return 100;
	}

	return 110;
}

void DroidMedicalModuleDataComponent::fillAttributeList(AttributeListMessage* alm, CreatureObject* droid) {
	// Convert the internal module rating to the actual medical rating.
	alm->insertAttribute("medical_module", getMedicalRating());
}

String DroidMedicalModuleDataComponent::toString() const {
	return BaseDroidModuleComponent::toString();
}

void DroidMedicalModuleDataComponent::addToStack(BaseDroidModuleComponent* other) {
	DroidMedicalModuleDataComponent* otherModule =
		cast<DroidMedicalModuleDataComponent*>(other);

	if (otherModule == nullptr)
		return;

	rating = rating + otherModule->rating;

	DroidComponent* droidComponent = cast<DroidComponent*>(getParent());

	if (droidComponent != nullptr)
		droidComponent->changeAttributeValue("medical_module", (float)rating);
}

void DroidMedicalModuleDataComponent::copy(BaseDroidModuleComponent* other) {
	DroidMedicalModuleDataComponent* otherModule =
		cast<DroidMedicalModuleDataComponent*>(other);

	if (otherModule == nullptr)
		return;

	rating = otherModule->rating;

	DroidComponent* droidComponent = cast<DroidComponent*>(getParent());

	if (droidComponent != nullptr) {
		droidComponent->addProperty(
			"medical_module",
			(float)rating,
			0,
			"exp_effectiveness"
		);
	}
}

void DroidMedicalModuleDataComponent::onCall() {
	// No op.
}

void DroidMedicalModuleDataComponent::onStore() {
	// No op.
}

void DroidMedicalModuleDataComponent::loadSkillMods(CreatureObject* player) {
	// Multiple active droids may carry Medical Modules. Apply only the highest
	// currently eligible rating rather than allowing their periodic tasks to
	// overwrite one another or remove unrelated Droid skill mods.
	refreshActiveMedicalRating(player);
}

void DroidMedicalModuleDataComponent::unloadSkillMods(CreatureObject* player) {
	// Exclude this droid while recalculating so storing it, losing power, dying,
	// or moving out of range immediately falls back to the next eligible droid.
	ManagedReference<DroidObject*> droid = getDroidObject();

	refreshActiveMedicalRating(player, droid.get());
}
