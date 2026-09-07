/*
				 Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#include "DroidArmorModuleDataComponent.h"
#include "server/zone/objects/tangible/component/droid/DroidComponent.h"
#include "server/zone/objects/creature/ai/DroidObject.h"
#include "server/zone/managers/crafting/labratories/DroidMechanics.h"

namespace {
	int clampArmorModuleRating(float rating) {
		if (rating < 0)
			return 0;

		if (rating > 8)
			return 8;


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
	unsigned int armor = DroidMechanics::determineArmorRating(level);
	int droidType = droid->getMechanicsProfile();
	if (droidType == 0)
		droidType = droid->getSpecies();

	float resist = DroidMechanics::determineArmorResistance(level, droidType);

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

	// Normal armor modules retain their existing additive-to-6 behavior.
	// A genuine Foundry 7/8 roll is preserved as the highest installed tier,
	// so stacking ordinary rating-6 modules can never manufacture tier 7/8.
	int incomingRating = clampArmorModuleRating(otherModule->armorModule);
	if (armorModule > 6 || incomingRating > 6)
		armorModule = Math::max(armorModule, incomingRating);
	else
		armorModule = Math::min(6, armorModule + incomingRating);

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
