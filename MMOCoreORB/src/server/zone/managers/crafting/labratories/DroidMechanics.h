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

		if (quality > 1.0f)
			return 1.0f;

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

		if (percentage > 1.0f)
			percentage = 1.0f;

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

	static float determineArmorResistance(int armorModuleLevel) {
		if (armorModuleLevel > 6)
			armorModuleLevel = 6;

		if (armorModuleLevel == 1 || armorModuleLevel == 4)
			return 15.0f;

		if (armorModuleLevel == 2 || armorModuleLevel == 5)
			return 25.0f;

		if (armorModuleLevel == 3 || armorModuleLevel == 6)
			return 40.0f;

		return 0.0f;
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
		float resistance = determineArmorResistance(armorModuleLevel);
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
