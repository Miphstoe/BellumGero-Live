/*
 * PowerupObjectImplementation.cpp
 *
 * Created on: march 3, 2012
 * Author: Kyle
 *
 * Modified: November 19, 2022
 * By: Hakry
 */

#include "server/zone/objects/tangible/powerup/PowerupObject.h"
#include "templates/tangible/PowerupTemplate.h"
#include "server/zone/packets/scene/AttributeListMessage.h"
#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "templates/tangible/SharedWeaponObjectTemplate.h"

//#define DEBUG_POWERUPS

static String getDamageTypeOverrideName(int damageType) {
	switch (damageType) {
		case SharedWeaponObjectTemplate::KINETIC:
			return "Kinetic";
		case SharedWeaponObjectTemplate::ENERGY:
			return "Energy";
		case SharedWeaponObjectTemplate::ELECTRICITY:
			return "Electricity";
		case SharedWeaponObjectTemplate::STUN:
			return "Stun";
		case SharedWeaponObjectTemplate::BLAST:
			return "Blast";
		case SharedWeaponObjectTemplate::HEAT:
			return "Heat";
		case SharedWeaponObjectTemplate::COLD:
			return "Cold";
		case SharedWeaponObjectTemplate::ACID:
			return "Acid";
		case SharedWeaponObjectTemplate::LIGHTSABER:
			return "Lightsaber";
		default:
			return "Unknown";
	}
}

int PowerupObjectImplementation::getDamageTypeOverride() const {
	Reference<PowerupTemplate*> pupTemplate = cast<PowerupTemplate*>(templateObject.get());

	if (pupTemplate == nullptr)
		return 0;

	return pupTemplate->getDamageTypeOverride();
}

void PowerupObjectImplementation::ensureInitializedFromTemplate() {
	Reference<PowerupTemplate*> pupTemplate = cast<PowerupTemplate*>(templateObject.get());

	if (pupTemplate == nullptr) {
		return;
	}

	// Track whether this powerup looks uninitialized (admin/loot spawned).
	const bool needsInit = type.isEmpty() || modifiers.size() == 0;

	// Non-crafted (admin/loot) powerups don't run updateCraftingValues(),
	// so ensure key members are initialized from the template.
	if (type.isEmpty()) {
		type = pupTemplate->getType().toLowerCase();
	}

	// IMPORTANT: default uses for spawned pups (admin/loot)
	// Only damage type powerups get 2500 uses, regular powerups get 500
	// Don't reset uses for crafted powerups that have been depleted.
	if (uses <= 0 && needsInit) {
		if (getDamageTypeOverride() != 0) {
			uses = 2500;  // Damage type powerups (Electricity, Heat, etc.)
		} else {
			uses = 500;   // Regular powerups (Melee, Ranged, etc.)
		}
	}

	// Ensure we have at least a primary stat for display/naming consistency.
	if (modifiers.size() == 0 && pupTemplate->hasPrimaryAttribute()) {
		PowerupStat stat = pupTemplate->getRandomPrimaryAttribute();
		modifiers.add(stat);

		if (getCustomObjectName().isEmpty()) {
			StringBuffer name;
			name << "A " << stat.getName() << " " << pupTemplate->getBaseName();
			setCustomObjectName(name.toString(), true);
		}
	}
}

// @read methods are const in autogen headers, so definitions must be const.
bool PowerupObjectImplementation::isRanged() const {
	const_cast<PowerupObjectImplementation*>(this)->ensureInitializedFromTemplate();
	return type == "ranged";
}

bool PowerupObjectImplementation::isMelee() const {
	const_cast<PowerupObjectImplementation*>(this)->ensureInitializedFromTemplate();
	return type == "melee";
}

bool PowerupObjectImplementation::isThrown() const {
	const_cast<PowerupObjectImplementation*>(this)->ensureInitializedFromTemplate();
	return type == "thrown";
}

bool PowerupObjectImplementation::isMine() const {
	const_cast<PowerupObjectImplementation*>(this)->ensureInitializedFromTemplate();
	return type == "mine";
}

bool PowerupObjectImplementation::isAll() const {
	const_cast<PowerupObjectImplementation*>(this)->ensureInitializedFromTemplate();
	return type == "all";
}

int PowerupObjectImplementation::getUses() const {
	const_cast<PowerupObjectImplementation*>(this)->ensureInitializedFromTemplate();
	return uses;
}

void PowerupObjectImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* object) {
	TangibleObjectImplementation::fillAttributeList(alm, object);

	ensureInitializedFromTemplate();

	// Powerup item examine: uses line (keep exactly as you had it)
	alm->insertAttribute("cat_pup.pup_uses", uses);

	// Powerup item examine: damage type override (string name)
	int dmgOverride = getDamageTypeOverride();
	if (dmgOverride != 0) {
		alm->insertAttribute("cat_pup.pup_damage_type_override", getDamageTypeOverrideName(dmgOverride));
	}

	for (int i = 0; i < modifiers.size(); ++i) {
		PowerupStat* stat = &modifiers.get(i);
		StringBuffer val;
		val << Math::getPrecision(stat->getValue(), 1) << "%";
		alm->insertAttribute(stat->getPupAttribute(), val.toString());
	}
}

float PowerupObjectImplementation::getPowerupStat(const String& stat) const {
	for (int i = 0; i < modifiers.size(); ++i) {
		if (modifiers.get(i).getAttributeToModify() == stat) {
			return modifiers.get(i).getValue();
		}
	}

	return 0.f;
}

void PowerupObjectImplementation::addPowerupStat(const String& attributeToMod, const String& name, const String& pupAttrib, float value) {
	// PowerupStat ctor is 3 args in your codebase; set value separately.
	PowerupStat newStat(attributeToMod, name, pupAttrib);
	newStat.setValue(value);
	modifiers.add(newStat);
}

float PowerupObjectImplementation::getWeaponStat(const String& attrib, WeaponObject* weapon, bool withPup) const {
	// Use the same getters as the actual weapon math so the display is correct.
	if (attrib == "attackSpeed" || attrib == "speed") {
		return weapon->getAttackSpeed(withPup);

	} else if (attrib == "minDamage") {
		return weapon->getMinDamage(withPup);

	} else if (attrib == "maxDamage") {
		return weapon->getMaxDamage(withPup);

	} else if (attrib == "damageRadius") {
		return weapon->getDamageRadius(withPup);

	} else if (attrib == "woundsRatio" || attrib == "woundchance") {
		return weapon->getWoundsRatio(withPup);

	} else if (attrib == "healthAttackCost") {
		return (float)weapon->getHealthAttackCost(withPup);

	} else if (attrib == "actionAttackCost" || attrib == "actioncost") {
		return (float)weapon->getActionAttackCost(withPup);

	} else if (attrib == "mindAttackCost" || attrib == "mindcost") {
		return (float)weapon->getMindAttackCost(withPup);

	} else if (attrib == "pointBlankAccuracy") {
		return (float)weapon->getPointBlankAccuracy(withPup);

	} else if (attrib == "pointBlankRange") {
		return (float)weapon->getPointBlankRange(withPup);

	} else if (attrib == "idealRange") {
		return (float)weapon->getIdealRange(withPup);

	} else if (attrib == "maxRange") {
		return (float)weapon->getMaxRange(withPup);

	} else if (attrib == "idealAccuracy") {
		return (float)weapon->getIdealAccuracy(withPup);

	} else if (attrib == "maxRangeAccuracy") {
		return (float)weapon->getMaxRangeAccuracy(withPup);

	} else if (attrib == "hitpoints") {
		return (float)weapon->getMaxCondition();
	}

	return 0.f;
}

void PowerupObjectImplementation::fillWeaponAttributeList(AttributeListMessage* alm, WeaponObject* weapon) {
	ensureInitializedFromTemplate();

	// Weapon examine: restore the "uses remaining" line on the WEAPON
	alm->insertAttribute("cat_pup.pup_uses", uses);

	// Weapon examine: show damage type override on the WEAPON (string name)
	int dmgOverride = getDamageTypeOverride();
	if (dmgOverride != 0) {
		alm->insertAttribute("cat_pup.pup_damage_type_override", getDamageTypeOverrideName(dmgOverride));
	}

	// Existing modifier/stat lines (if any)
	for (int i = 0; i < modifiers.size(); ++i) {
		PowerupStat* stat = &modifiers.get(i);

		float current = getWeaponStat(stat->getAttributeToModify(), weapon, false);
		float mod = stat->getValue();
		float total = getWeaponStat(stat->getAttributeToModify(), weapon, true);

		StringBuffer val;
		val << Math::getPrecision(current, 1) << " + "
			<< Math::getPrecision(mod, 1) << "% = "
			<< Math::getPrecision(total, 1);

		alm->insertAttribute(stat->getPupAttribute(), val.toString());
	}
}

void PowerupObjectImplementation::addSecondaryStat(CraftingValues* values, PowerupTemplate* pupTemplate) {
	float effect = values->getCurrentValue("effect");
	float maxEffect = values->getMaxValue("effect");

	// In your codebase this is returned by value, not a pointer.
	Vector<PowerupStat> secondaryStats = pupTemplate->getSecondaryAttributes();
	if (secondaryStats.size() == 0) {
		return;
	}

	// Build a list of secondary stats that aren't already present.
	Vector<PowerupStat> availableStats;

	for (int i = 0; i < secondaryStats.size(); ++i) {
		PowerupStat candidate = secondaryStats.get(i);
		bool hasStat = false;

		for (int j = 0; j < modifiers.size(); ++j) {
			PowerupStat stat = modifiers.get(j);
			if (stat.getAttributeToModify() == candidate.getAttributeToModify()) {
				hasStat = true;
				break;
			}
		}

		if (!hasStat) {
			availableStats.add(candidate);
		}
	}

	if (availableStats.size() == 0) {
		return;
	}

	PowerupStat newStat = availableStats.get(System::random(availableStats.size() - 1));
	modifiers.add(newStat);

#ifdef DEBUG_POWERUPS
	info(true) << "Pup adding stat " << newStat.getAttributeToModify() << " with a value of " << newStat.getValue();
#endif // DEBUG_POWERUPS
}

void PowerupObjectImplementation::updateCraftingValues(CraftingValues* values, bool firstUpdate) {
#ifdef DEBUG_POWERUPS
	info(true) << "========== START -  PowerupObjectImplementation::updateCraftingValues ==========";
	info(true) << getCustomObjectName() <<  " Type = " << type;
#endif // DEBUG_POWERUPS

	Reference<PowerupTemplate*> pupTemplate = cast<PowerupTemplate*>(templateObject.get());

	if (pupTemplate == nullptr) {
		return;
	}

	float effect = values->getCurrentValue("effect");
	float maxEffect = values->getMaxValue("effect");

	if (firstUpdate) {
		// Handle first update during assembly to add base values and add primary stat
#ifdef DEBUG_POWERUPS
		info(true) << "PowerupObjectImplementation::updateCraftingValues  -- first update";
#endif // DEBUG_POWERUPS

		String key;
		String value;

		if (pupTemplate->hasPrimaryAttribute()) {
			PowerupStat stat = pupTemplate->getRandomPrimaryAttribute();
			modifiers.add(stat);

			StringBuffer name;
			name << "A " << stat.getName() << " " << pupTemplate->getBaseName();

#ifdef DEBUG_POWERUPS
			info(true) << "Adding Primary attribute: " << stat.getAttributeToModify();
#endif // DEBUG_POWERUPS

			setCustomObjectName(name.toString(), true);
		}

		type = pupTemplate->getType().toLowerCase();

		// Only damage type powerups get 2500 uses, regular powerups get 500
		if (getDamageTypeOverride() != 0) {
			uses = 2500;  // Damage type powerups (Electricity, Heat, etc.)
		} else {
			uses = 500;   // Regular powerups (Melee, Ranged, etc.)
		}

#ifdef DEBUG_POWERUPS
		info(true) << "Type = " << type << " Uses = " << uses;
#endif // DEBUG_POWERUPS

	// Handle subsequent crafting updates derived from experimentation
	} else if (pupTemplate->hasSecondaryAttribute()) {
		int roll = System::random(100);

#ifdef DEBUG_POWERUPS
		info(true) << "has secondary attribute -- Current Effect = " << effect << " with a roll of " << roll;
#endif // DEBUG_POWERUPS

		// 1st secondary stat -- Effect is greater than 25% check to apply the stat - roll chance 50%
		if ((effect >= 25.f) && modifiers.size() == 1 && roll < 50) {
			addSecondaryStat(values, pupTemplate);

			// Handle the naming with the 1st secondary stat added
			PowerupStat secondaryNameStat = modifiers.get(1);

			StringBuffer name;
			name << "A " << secondaryNameStat.getName() << " " << pupTemplate->getBaseName();
			setCustomObjectName(name.toString(), true);

		// 2nd secondary stat -- Effect is greater than 50% check to apply the stat - roll chance 25%
		} else if ((effect >= 50.f) && modifiers.size() == 2 && roll < 25) {
			addSecondaryStat(values, pupTemplate);

		// 3rd secondary stat -- Effect is greater than 75% check to apply the stat - roll chance 15%
		} else if ((effect >= 75.f) && modifiers.size() == 3 && roll < 15) {
			addSecondaryStat(values, pupTemplate);
		}
	}

	// Update values based on experimentation
	if (maxEffect > 0) {
		float ratio = effect / maxEffect;

		for (int i = 0; i < modifiers.size(); ++i) {
			PowerupStat stat = modifiers.get(i);

			// Primary scales 0%..MAXPRIMARY (bonus percentage only, not 100 + bonus)
			if (i == 0) {
				stat.setValue(Math::getPrecision(MAXPRIMARY * ratio, 2));
			} else {
				// Secondary scales 0%..MAXSECONDARY (bonus percentage only, not 100 + bonus)
				stat.setValue(Math::getPrecision(MAXSECONDARY * ratio, 2));
			}

			modifiers.set(i, stat);
		}
	}

#ifdef DEBUG_POWERUPS
	info(true) << "========== END -  PowerupObjectImplementation::updateCraftingValues ==========";
#endif // DEBUG_POWERUPS
}
