/*
 * CitySpecialization.h
 *
 *  Created on: Jul 20, 2012
 *      Author: swgemu
 */

#ifndef CITYSPECIALIZATION_H_
#define CITYSPECIALIZATION_H_

class CitySpecialization : public Object {
	String name;
	String displayName;
	int cost;
	int minRank;
	VectorMap<String, int> skillMods;

public:
	CitySpecialization() {
		cost = 0;
		minRank = 0; // Default: no rank requirement
		skillMods.setNoDuplicateInsertPlan();
		skillMods.setNullValue(0);
	}

	CitySpecialization(const String& name, int cost) {
		this->name = name;
		this->cost = cost;
		this->minRank = 0;
	}

	CitySpecialization(const CitySpecialization& spec) : Object() {
		name = spec.name;
		displayName = spec.displayName;
		cost = spec.cost;
		minRank = spec.minRank;
		skillMods = spec.skillMods;
	}

	CitySpecialization& operator=(const CitySpecialization& spec) {
		if (this == &spec)
			return *this;

		name = spec.name;
		displayName = spec.displayName;
		cost = spec.cost;
		minRank = spec.minRank;
		skillMods = spec.skillMods;

		return *this;
	}

	void readObject(LuaObject* luaObject) {
		name = luaObject->getStringField("name");
		displayName = luaObject->getStringField("displayName"); // Optional custom display name
		cost = luaObject->getIntField("cost");
		minRank = luaObject->getIntField("minRank"); // Read minRank from Lua (defaults to 0 if not present)

		LuaObject smods = luaObject->getObjectField("skillMods");

		for (int i = 1; i <= smods.getTableSize(); ++i) {
			LuaObject mod = smods.getObjectAt(i);

			if (mod.isValidTable()) {
				String k = mod.getStringAt(1);
				int v = mod.getIntAt(2);

				skillMods.put(k, v);
			}

			mod.pop();
		}

		smods.pop();
	}

	inline const String& getName() const {
		return name;
	}

	inline const String& getDisplayName() const {
		return displayName;
	}

	inline int getCost() const {
		return cost;
	}

	inline int getMinRank() const {
		return minRank;
	}

	inline const VectorMap<String, int>* getSkillMods() const {
		return &skillMods;
	}
};

#endif /* CITYSPECIALIZATION_H_ */
