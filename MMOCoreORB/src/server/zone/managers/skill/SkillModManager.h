/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.
*/

#ifndef SKILLMODMANAGER_H_
#define SKILLMODMANAGER_H_

#include "engine/engine.h"

namespace server {
namespace zone {
namespace objects {
namespace creature {
	class CreatureObject;
}
}
}
}

using namespace server::zone::objects::creature;

namespace server {
namespace zone {
namespace objects {
namespace tangible {
	class TangibleObject;
}
}
}
}

using namespace server::zone::objects::tangible;

namespace server {
namespace zone {
namespace managers {
namespace skill {

class SkillModManager : public Singleton<SkillModManager>, public Logger, public Object {

public:
	///Permanent Mods
	const static int PERMANENTMOD = 0x100;
	const static int TEMPLATE = 0x101; /// From LUA templates
	const static int SKILLBOX = 0x103; /// From Skills learned

	///Bonus Mods
	const static int BONUSMOD = 0x1000;
	const static int WEARABLE = 0x1001; /// From Wearable items
	const static int STRUCTURE = 0x1002; /// From Structures creature is in
	const static int CITY = 0x1003; // From Cities
	const static int DROID = 0x1004; // From medical droid modules

	// Temp Mod
	const static int TEMPORARYMOD = 0x10000;
	const static int BUFF = 0x10001; /// From temporary buffs
	const static int ABILITYBONUS = 0x10002; /// From CombatQueueCommands

private:
	VectorMap<uint32, int> skillModMax;
	VectorMap<uint32, int> skillModMin;
	VectorMap<String, uint32> skillModNameType;  // per-name modType filter
	VectorMap<String, int>   skillModNameMax;    // per-name cap max
	VectorMap<String, int>   skillModNameMin;    // per-name cap min
	SortedVector<String> disabledWearableSkillMods;
public:
	SkillModManager();
	~SkillModManager();

private:

	void init();

	void setDefaults();

	bool compareMods(VectorMap<String, int>& mods, CreatureObject* creature, uint32 type);


public:
	void verifyWearableSkillMods(CreatureObject* creature);

	void verifyStructureSkillMods(TangibleObject* tano);

	void verifySkillBoxSkillMods(CreatureObject* creature);

	void verifyBuffSkillMods(CreatureObject* creature);

	inline int getMinSkill(const uint32 modType) {
		return skillModMin.get(modType);
	}

	inline int getMaxSkill(const uint32 modType) {
		return skillModMax.get(modType);
	}

	inline bool isWearableModDisabled(String mod) {
		return disabledWearableSkillMods.contains(mod);
	}

	// Returns true and fills outMin/outMax when a per-name cap is configured
	// for the given (modName, modType) pair, overriding the type-level cap.
	inline bool getSkillModLimitByName(const String& modName, uint32 modType, int& outMin, int& outMax) const {
		if (!skillModNameMax.contains(modName))
			return false;

		// If a specific modType filter was configured, only apply for that type
		if (skillModNameType.contains(modName)) {
			uint32 configuredType = skillModNameType.get(modName);
			if (configuredType != 0 && configuredType != modType)
				return false;
		}

		outMin = skillModNameMin.get(modName);
		outMax = skillModNameMax.get(modName);
		return true;
	}
};

}
}
}
}

using namespace server::zone::managers::skill;

#endif // SKILLMODMANAGER_H_
