#ifndef CITYREMOVEFACTIONTROOPTASK_H_
#define CITYREMOVEFACTIONTROOPTASK_H_

#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/ai/AiAgent.h"
#include "server/zone/objects/creature/ai/CreatureTemplate.h"

class CityRemoveFactionTroopTask : public Task {
	ManagedReference<SceneObject*> troop;
	ManagedReference<CityRegion*> city;

	static int getRefundForTroop(SceneObject* obj) {
		if (obj == nullptr || !obj->isCreatureObject())
			return 0;

		CreatureObject* creo = obj->asCreatureObject();
		if (creo == nullptr)
			return 0;

		// City troops are AI agents; CreatureObject does not expose getCreatureTemplate()
		AiAgent* agent = creo->asAiAgent();
		if (agent == nullptr)
			return 0;

		const CreatureTemplate* ct = agent->getCreatureTemplate();
		if (ct == nullptr)
			return 0;

		const String& templ = ct->getTemplateName();

		// Must match your placement-cost tiers:
		// Basic: 1000, Mid: 2500, Elite: 5000
		if (templ == "city_imperial_stormtrooper" || templ == "city_rebel_trooper")
			return 2000;

		if (templ == "city_imperial_assault_trooper" || templ == "city_rebel_grenadier")
			return 5000;

		if (templ == "city_imperial_dark_trooper" || templ == "city_rebel_specforce_sergeant")
			return 10000;

		// Unknown / future troop type
		return 0;
	}

public:
	CityRemoveFactionTroopTask(SceneObject* sceno, CityRegion* cityRegion) {
		troop = sceno;
		city = cityRegion;
	}

	void run() {
		if (city == nullptr || troop == nullptr)
			return;

		Locker locker(city);
		Locker clocker(troop, city);

		// Refund placement cost back to city treasury (manual removals only).
		const int refund = getRefundForTroop(troop);
		if (refund > 0) {
			city->addToCityTreasury(refund);
		}

		// Remove from city tracking + delete
		city->removeFactionTroop(troop);

		troop->destroyObjectFromWorld(true);
		troop->destroyObjectFromDatabase(true);
	}
};

#endif /* CITYREMOVEFACTIONTROOPTASK_H_ */