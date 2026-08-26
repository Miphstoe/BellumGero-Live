#ifndef DROID_MECHANICS_H
#define DROID_MECHANICS_H

#include "server/zone/objects/creature/ai/DroidObject.h"
#include "server/zone/managers/crafting/labratories/Genetics.h"

namespace server {
namespace zone {
namespace managers {
namespace crafting {
namespace labratories {

class DroidMechanics {
public:
	struct CombatDroidProfile {
		bool supported;
		int minimumHam;
		int maximumHam;
		float slowestAttackSpeed;
		float fastestAttackSpeed;
		float minimumHitChance;
		float maximumHitChance;
		float minimumDamageFloor;
		float minimumDamageCeiling;
		float maximumDamageFloor;
		float maximumDamageCeiling;
		int maximumUsefulCombatRating;

		CombatDroidProfile(bool isSupported = false, int minHam = 45, int maxHam = 55,
				float slowSpeed = 2.0f, float fastSpeed = 2.0f,
				float minHit = 0.20f, float maxHit = 0.20f,
				float minDamageFloor = 1.0f, float minDamageCeiling = 1.0f,
				float maxDamageFloor = 1.0f, float maxDamageCeiling = 1.0f,
				int maxCombatRating = 1) :
			supported(isSupported),
			minimumHam(minHam),
			maximumHam(maxHam),
			slowestAttackSpeed(slowSpeed),
			fastestAttackSpeed(fastSpeed),
			minimumHitChance(minHit),
			maximumHitChance(maxHit),
			minimumDamageFloor(minDamageFloor),
			minimumDamageCeiling(minDamageCeiling),
			maximumDamageFloor(maxDamageFloor),
			maximumDamageCeiling(maxDamageCeiling),
			maximumUsefulCombatRating(maxCombatRating) {
		}
	};

	DroidMechanics();
	virtual ~DroidMechanics();

	static float clampQuality(float quality) {
		if (quality < 0.0f)
			return 0.0f;

		// Foundry chassis can deliberately exceed the normal 100% crafted
		// ceiling. 60 power_level maps to at most 110% effective chassis quality.
		if (quality > 1.10f)
			return 1.10f;

		return quality;
	}

	static CombatDroidProfile getCombatProfile(int droidType) {
		switch (droidType) {
		case DroidObject::DZ70:
			// Fast, accurate skirmisher. Basic chassis tops out at 50% quality,
			// while the advanced chassis can reach the full profile.
			return CombatDroidProfile(true, 1250, 5000,
				1.55f, 0.95f, 0.32f, 0.68f,
				100.0f, 230.0f, 120.0f, 300.0f, 220);

		case DroidObject::PROBOT:
			// Heavy ranged platform with stronger sustained damage and durability.
			return CombatDroidProfile(true, 1625, 6500,
				1.95f, 1.25f, 0.28f, 0.62f,
				120.0f, 320.0f, 150.0f, 400.0f, 550);

		case DroidObject::R_SERIES:
			// Combat/utility hybrid. Its flexibility is part of its power budget.
			return CombatDroidProfile(true, 1500, 6000,
				2.15f, 1.35f, 0.28f, 0.58f,
				95.0f, 220.0f, 122.5f, 285.0f, 550);

		case DroidObject::LE_REPAIR:
			// Durable support chassis with deliberately modest offensive output.
			return CombatDroidProfile(true, 2000, 8000,
				2.40f, 1.60f, 0.28f, 0.52f,
				50.0f, 140.0f, 90.0f, 180.0f, 330);

		case DroidObject::BATTLE_DROID:
			// Foundry B1: offensive/skirmisher bias.
			return CombatDroidProfile(true, 1750, 7000,
				1.85f, 1.10f, 0.32f, 0.68f,
				145.0f, 360.0f, 180.0f, 450.0f, 550);

		case DroidObject::SUPER_BATTLE_DROID:
			// Foundry B2: durability bias.
			return CombatDroidProfile(true, 2125, 8500,
				2.10f, 1.35f, 0.28f, 0.60f,
				150.0f, 340.0f, 190.0f, 430.0f, 550);

		case DroidObject::DROIDECA:
			// Foundry Droideka: defensive platform with strong ranged pressure.
			return CombatDroidProfile(true, 1900, 7600,
				1.75f, 1.05f, 0.32f, 0.66f,
				155.0f, 350.0f, 195.0f, 445.0f, 550);

		default:
			return CombatDroidProfile();
		}
	}

	static float determineHam(float quality, int droidType) {
		CombatDroidProfile profile = getCombatProfile(droidType);

		if (!profile.supported) {
			float hamValue = clampQuality(quality) * (droidType == DroidObject::BLL ? 1400.0f : 55.0f);
			float minimumHam = droidType == DroidObject::BLL ? 1200.0f : 45.0f;

			if (hamValue < minimumHam)
				hamValue = minimumHam;

			return hamValue;
		}

		float hamValue = clampQuality(quality) * (float)profile.maximumHam;

		if (hamValue < profile.minimumHam)
			hamValue = profile.minimumHam;

		return hamValue;
	}

	static float determineChassisQuality(int droidType, float ham) {
		CombatDroidProfile profile = getCombatProfile(droidType);

		if (!profile.supported || profile.maximumHam <= 0)
			return 0.0f;

		return clampQuality(ham / (float)profile.maximumHam);
	}

	static float determineSpeed(int droidType, float ham) {
		CombatDroidProfile profile = getCombatProfile(droidType);

		if (!profile.supported)
			return 0.0f;

		float quality = determineChassisQuality(droidType, ham);
		return profile.slowestAttackSpeed - (quality * (profile.slowestAttackSpeed - profile.fastestAttackSpeed));
	}

	static float determineHit(int droidType, float ham) {
		CombatDroidProfile profile = getCombatProfile(droidType);

		if (!profile.supported)
			return 0.0f;

		float quality = determineChassisQuality(droidType, ham);
		return profile.minimumHitChance + (quality * (profile.maximumHitChance - profile.minimumHitChance));
	}

	static float determineCombatRatingPercentage(int droidType, int rating) {
		CombatDroidProfile profile = getCombatProfile(droidType);

		if (!profile.supported || rating <= 0 || profile.maximumUsefulCombatRating <= 0)
			return 0.0f;

		float percentage = rating / (float)profile.maximumUsefulCombatRating;

		// Foundry Combat Modules roll to 125 versus the normal crafted ceiling of 110.
		const float maximumFoundryPercentage = 125.0f / 110.0f;
		if (percentage > maximumFoundryPercentage)
			percentage = maximumFoundryPercentage;

		return percentage;
	}

	static float determineMinDamage(int droidType, int rating) {
		if (rating <= 0)
			return 1.0f;

		CombatDroidProfile profile = getCombatProfile(droidType);

		if (!profile.supported)
			return 1.0f;

		float percentage = determineCombatRatingPercentage(droidType, rating);
		return round(profile.minimumDamageFloor + (percentage * (profile.minimumDamageCeiling - profile.minimumDamageFloor)));
	}

	static float determineMaxDamage(int droidType, int rating) {
		if (rating <= 0)
			return 1.0f;

		CombatDroidProfile profile = getCombatProfile(droidType);

		if (!profile.supported)
			return 1.0f;

		float percentage = determineCombatRatingPercentage(droidType, rating);
		return round(profile.maximumDamageFloor + (percentage * (profile.maximumDamageCeiling - profile.maximumDamageFloor)));
	}

	static int determineArmorRating(int armorModuleLevel) {
		if (armorModuleLevel <= 0)
			return 0;

		if (armorModuleLevel <= 3)
			return 1;

		return 2;
	}

	static float determineArmorResistance(int armorModuleLevel, int droidType = -1) {
		if (armorModuleLevel > 8)
			armorModuleLevel = 8;

		float resistance = 0.0f;
		if (armorModuleLevel == 1 || armorModuleLevel == 4)
			resistance = 15.0f;
		else if (armorModuleLevel == 2 || armorModuleLevel == 5)
			resistance = 25.0f;
		else if (armorModuleLevel == 3 || armorModuleLevel == 6)
			resistance = 40.0f;
		else if (armorModuleLevel == 7)
			resistance = 50.0f;
		else if (armorModuleLevel == 8)
			resistance = 60.0f;

		// Droideka is the premium defensive specialist.
		if (droidType == DroidObject::DROIDECA && resistance > 0.0f)
			resistance += 5.0f;

		return resistance;
	}

	static int determineLevel(float quality, int droidType, int combatRating, int armorModuleLevel) {
		// Preserve the established display levels for noncombat or empty deeds.
		if (combatRating <= 0) {
			if (droidType == DroidObject::PROBOT)
				return 19;

			if (droidType == DroidObject::DZ70 || droidType == DroidObject::LE_REPAIR)
				return 18;

			if (droidType == DroidObject::R_SERIES)
				return 7;

			return 1;
		}

		CombatDroidProfile profile = getCombatProfile(droidType);

		if (!profile.supported)
			return 1;

		int ham = (int)round(determineHam(quality, droidType));
		int minimumDamage = (int)determineMinDamage(droidType, combatRating);
		int maximumDamage = (int)determineMaxDamage(droidType, combatRating);
		float attackSpeed = determineSpeed(droidType, ham);
		float hitChance = determineHit(droidType, ham);
		int armorRating = determineArmorRating(armorModuleLevel);
		float resistance = determineArmorResistance(armorModuleLevel, droidType);
		float dps = ((minimumDamage + maximumDamage) / 2.0f) / attackSpeed;
		int regeneration = Math::max(1, ham / 10);

		int level = Genetics::calculateAgentLevel(ham, dps, hitChance, regeneration,
			armorRating, resistance, resistance, resistance, resistance,
			resistance, resistance, resistance, resistance, resistance);

		return Math::max(1, level);
	}

	/** Used to determine harvest droid and trap droid skill mod*/
	static int determineDroidSkillBonus(float playerSkill, float droidSkill, float baseAmount) {
		float p1 = (1.f + (playerSkill / 100.f));
		float p2 = 3.55 * p1;
		float p3 = droidSkill / p2;
		float p4 = p3 / 100;
		float bonus = (baseAmount * p4);
		return ceil(bonus);
	}
};

}
}
}
}
}

using namespace server::zone::managers::crafting::labratories;

#endif /* DROID_MECHANICS_H */
