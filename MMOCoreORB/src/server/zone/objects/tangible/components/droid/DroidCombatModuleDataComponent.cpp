/*
 * 				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#include "DroidCombatModuleDataComponent.h"
#include "server/zone/objects/tangible/component/droid/DroidComponent.h"
#include "server/zone/managers/crafting/labratories/DroidMechanics.h"

DroidCombatModuleDataComponent::DroidCombatModuleDataComponent() {
	setLoggingName("DroidCombatModule");
	rating = 0;
}

DroidCombatModuleDataComponent::~DroidCombatModuleDataComponent() {

}

String DroidCombatModuleDataComponent::getModuleName() const {
	return String("combat_module");
}

void DroidCombatModuleDataComponent::initializeTransientMembers() {
	DroidComponent* droidComponent = cast<DroidComponent*>(getParent());
	if (droidComponent == nullptr) {
		info("droidComponent was null");
		return;
	}

	if (droidComponent->hasKey("cmbt_module")) {
		rating = droidComponent->getAttributeValue("cmbt_module");
	}
}

void DroidCombatModuleDataComponent::updateCraftingValues(CraftingValues* values, bool firstUpdate) {
	rating = values->getCurrentValue("cmbt_module");
}

void DroidCombatModuleDataComponent::fillAttributeList(AttributeListMessage* alm, CreatureObject* creature) {
	// Standalone Combat Modules and socket banks should show the installed
	// module rating for crafting verification. A called droid already shows
	// the derived attack speed, accuracy and damage, so hide the raw total.
	ManagedReference<DroidObject*> droid = getDroidObject();

	if (droid == nullptr) {
		alm->insertAttribute("cmbt_module", (int)rating);
		return;
	}

	// lets make a pcd
	int maxHam = droid->getMaximumHAM();
	int damageMin = droid->getDamageMin();
	int damageMax = droid->getDamageMax();
	float chanceHit = droid->getChanceHit();
	float attackSpeed = droid->getAttackSpeed();

	StringBuffer attdisplayValue;
	attdisplayValue << Math::getPrecision(attackSpeed, 2);
	StringBuffer hitdisplayValue;
	hitdisplayValue << Math::getPrecision(chanceHit, 2);

	alm->insertAttribute("creature_attack", attdisplayValue);
	alm->insertAttribute("creature_tohit", hitdisplayValue);
	alm->insertAttribute("creature_damage", String::valueOf(damageMin) + " - " + String::valueOf(damageMax));
}

String DroidCombatModuleDataComponent::toString() const {
	return BaseDroidModuleComponent::toString();
}

void DroidCombatModuleDataComponent::addToStack(BaseDroidModuleComponent* other) {
	DroidCombatModuleDataComponent* otherModule = cast<DroidCombatModuleDataComponent*>(other);
	if (otherModule == nullptr)
		return;

	rating = rating + otherModule->rating;
	if (rating > 750) {
		rating = 750;
	}

	DroidComponent* droidComponent = cast<DroidComponent*>(getParent());
	if (droidComponent != nullptr)
		droidComponent->changeAttributeValue("cmbt_module", (float)rating);
}

void DroidCombatModuleDataComponent::copy(BaseDroidModuleComponent* other) {
	DroidCombatModuleDataComponent* otherModule = cast<DroidCombatModuleDataComponent*>(other);
	if (otherModule == nullptr)
		return;

	rating = otherModule->rating;

	DroidComponent* droidComponent = cast<DroidComponent*>(getParent());
	if (droidComponent != nullptr)
		droidComponent->addProperty("cmbt_module", (float)rating, 0, "exp_effectiveness");
}

void DroidCombatModuleDataComponent::initialize(DroidObject* droid) {
	// calculate and set the weapon values
	int maxHam = droid->getBaseHAM(0);
	int droidType = droid->getMechanicsProfile();
	if (droidType == 0)
		droidType = droid->getSpecies();

	int minDmg = DroidMechanics::determineMinDamage(droidType, rating);
	int maxDmg = DroidMechanics::determineMaxDamage(droidType, rating);
	float toHit = DroidMechanics::determineHit(droidType, maxHam);
	float speed = DroidMechanics::determineSpeed(droidType, maxHam);

	// Unsupported/custom chassis do not have a dedicated combat profile. Never
	// apply zero attack speed or zero accuracy to a droid that accepts a Combat
	// Module; use a deliberately weak but safe fallback instead.
	if (speed <= 0.0f)
		speed = 2.0f;

	if (toHit <= 0.0f)
		toHit = 0.20f;

	droid->setHitChance(toHit);
	droid->setMaxDamage(maxDmg);
	droid->setMinDamage(minDmg);
	droid->setAttackSpeed(speed);
}
