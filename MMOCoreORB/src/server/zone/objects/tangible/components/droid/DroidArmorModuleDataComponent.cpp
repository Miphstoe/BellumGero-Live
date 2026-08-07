/*
				 Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#include "DroidArmorModuleDataComponent.h"
#include "server/zone/objects/tangible/component/droid/DroidComponent.h"
#include "server/zone/objects/creature/ai/DroidObject.h"

namespace {
	int clampArmorModuleRating(float rating) {
		if (rating < 0)
			return 0;

		if (rating > 6)
			return 6;

		return (int)rating;
	}
}

DroidArmorModuleDataComponent::DroidArmorModuleDataComponent() {
	armorModule = 0;
	setLoggingName("DroidArmorModule");
}

DroidArmorModuleDataComponent::~DroidArmorModuleDataComponent() {

}

String DroidArmorModuleDataComponent::getModuleName() const {
	return String("armor_module");
}

void DroidArmorModuleDataComponent::initializeTransientMembers() {

	// Pull module stat from parent sceno
	DroidComponent* droidComponent = cast<DroidComponent*>(getParent());
	if (droidComponent == nullptr) {
		info("droidComponent was null");
		return;
	}

	if (droidComponent->hasKey("armor_module")) {
		armorModule = clampArmorModuleRating(droidComponent->getAttributeValue("armor_module"));

		// Keep old or previously stacked components consistent with the
		// effective gameplay cap used by the called droid.
		droidComponent->changeAttributeValue("armor_module", armorModule);
	}
}

void DroidArmorModuleDataComponent::initialize(DroidObject* droid) {
	// Change droid resist and armor stat

	int level = clampArmorModuleRating(armorModule);
	unsigned int armor = 0;
	float resist = 0;

	// Set armor type
	if (level == 0) {
		armor = 0; // NO ARMOR
	}
	else if (level <= 3) {
		armor = 1; // LIGHT ARMOR
	}
	else if (level <= 6) {
		armor = 2; // MEDIUM ARMOR
	}

	// Set damage resistance
	if (level == 1 || level == 4) {
		resist = 15;
	}
	else if (level == 2 || level == 5) {
		resist = 25;
	}
	else if (level == 3 || level == 6) {
		resist = 40;
	} else {
		resist = 0;
	}

	droid->setArmor(armor);
	droid->setResists(resist);
}

void DroidArmorModuleDataComponent::fillAttributeList(AttributeListMessage* alm, CreatureObject* droid) {
	// Armor/resists are filled from AiAgent. Display the effective capped
	// module level on deeds and components so the shown value matches gameplay.
	alm->insertAttribute("armor_module", clampArmorModuleRating(armorModule));
}

int DroidArmorModuleDataComponent::getBatteryDrain() {
	return 0;
}

String DroidArmorModuleDataComponent::toString() const {
	return BaseDroidModuleComponent::toString();
}

void DroidArmorModuleDataComponent::updateCraftingValues(CraftingValues* values, bool firstUpdate) {
	armorModule = clampArmorModuleRating(values->getCurrentValue("armor_module"));
}

void DroidArmorModuleDataComponent::addToStack(BaseDroidModuleComponent* other) {

	DroidArmorModuleDataComponent* otherModule = cast<DroidArmorModuleDataComponent*>(other);
	if (otherModule == nullptr)
		return;

	// Armor Module effectiveness has no gameplay benefit above rating 6.
	armorModule = clampArmorModuleRating(armorModule + otherModule->armorModule);

	// Save capped stat in parent sceno
	DroidComponent* droidComponent = cast<DroidComponent*>(getParent());
	if (droidComponent == nullptr)
		return;

	// Attribute should have already been created in copy method
	if (!droidComponent->changeAttributeValue("armor_module", armorModule)) {
		info("addToStack updateAttributeValue failed");
		return;
	}
}

void DroidArmorModuleDataComponent::copy(BaseDroidModuleComponent* other) {

	DroidArmorModuleDataComponent* otherModule = cast<DroidArmorModuleDataComponent*>(other);
	if (otherModule == nullptr)
		return;

	armorModule = clampArmorModuleRating(otherModule->armorModule);

	// Save capped stat in parent sceno
	DroidComponent* droidComponent = cast<DroidComponent*>(getParent());
	if (droidComponent == nullptr)
		return;

	droidComponent->addProperty("armor_module", armorModule, 0, "exp_effectiveness");
}
