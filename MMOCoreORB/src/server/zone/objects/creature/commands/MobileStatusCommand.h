/*
 * Bellum Gero mobile presence diagnostic.
 * Usage: /mobilestatus
 */

#ifndef MOBILESTATUSCOMMAND_H_
#define MOBILESTATUSCOMMAND_H_

#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/ai/AiAgent.h"
#include "server/zone/objects/creature/ai/CreatureTemplate.h"
#include "server/zone/objects/creature/commands/QueueCommand.h"
#include "server/zone/managers/director/DirectorManager.h"
#include "server/zone/managers/director/PersistentEvent.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "system/lang/Time.h"

class MobileStatusUi {
public:
	struct MobileDefinition {
		const char* displayName;
		const char* templateName;
		const char* nameStringId;
	};

	static const MobileDefinition* getMobiles(int& count) {
		static const MobileDefinition mobiles[] = {
			{ "Wild Bladeback Boar", "wild_bladeback_boar", "quest_hero_of_tatooine_ferocious_beast" },
			{ "A Moisture Farmer", "hero_of_tat_farmer", "quest_hero_of_tatooine_farmer" },
			{ "Gorax", "gorax", "" },
			{ "Acklay - Devourer of Massassi", "acklay_worldboss", "" },
			{ "Searing Broodwarden - The Spider Queen", "enhanced_gaping_spider_boss", "" },
			{ "Torgas the Enslaver", "torgas_the_enslaver", "" },
			{ "Infernomaw-Bird of Prey", "peko_peko_infernomaw", "" },
			{ "Primordial Warlord Grak", "primordial_warlord_grak", "" },
			{ "The Hand", "the_hand", "" }
		};

		count = sizeof(mobiles) / sizeof(MobileDefinition);
		return mobiles;
	}

	static int waypointCoordinate(float value) {
		return (int)(value >= 0.f ? value + 0.5f : value - 0.5f);
	}

	static bool matchesDefinition(SceneObject* sceneObject, AiAgent* agent, const MobileDefinition& definition) {
		const CreatureTemplate* creatureTemplate = agent->getCreatureTemplate();
		bool templateMatches = creatureTemplate != nullptr && creatureTemplate->getTemplateName() == definition.templateName;
		bool nameMatches = definition.nameStringId[0] != '\0' && sceneObject->getObjectNameStringIdName() == definition.nameStringId;

		return templateMatches || nameMatches;
	}

	static void addLocation(AiAgent* agent, const MobileDefinition& definition, SortedVector<uint64>& seenObjectIDs, Vector<String>& locations) {
		if (agent == nullptr || agent->isDead())
			return;

		Zone* agentZone = agent->getZone();
		if (agentZone == nullptr)
			return;

		uint64 objectID = agent->getObjectID();
		if (seenObjectIDs.contains(objectID))
			return;

		seenObjectIDs.put(objectID);

		float x = agent->getWorldPositionX();
		float y = agent->getWorldPositionY();

		StringBuffer location;
		location << "PLANET: " << agentZone->getZoneName() << "\n";
		location << "LOCATION: " << x << ", " << y << "\n";
		location << "HEIGHT: " << agent->getWorldPositionZ() << "\n";
		location << "OBJECT ID: " << objectID << "\n";

		// SWG waypoint commands use horizontal world X/Y. SceneObject Z is height.
		location << "WAYPOINT: /waypoint " << agentZone->getZoneName() << " "
			<< waypointCoordinate(x) << " "
			<< waypointCoordinate(y) << " "
			<< definition.displayName << "\n";

		locations.add(location.toString());
	}

	static uint64 getHeroOfTatooineObjectID(const String& templateName) {
		if (templateName == "wild_bladeback_boar")
			return DirectorManager::instance()->readSharedMemory("hero_of_tat:courage_mob_id");

		if (templateName == "hero_of_tat_farmer")
			return DirectorManager::instance()->readSharedMemory("hero_of_tat:altruism_mob_id");

		return 0;
	}

	static bool isHeroOfTatooineMobile(const MobileDefinition& definition) {
		String templateName = definition.templateName;
		return templateName == "wild_bladeback_boar" || templateName == "hero_of_tat_farmer";
	}

	static String getHeroOfTatooineEventName(const MobileDefinition& definition) {
		String templateName = definition.templateName;
		if (templateName == "wild_bladeback_boar")
			return "HeroOfTatCourage";

		if (templateName == "hero_of_tat_farmer")
			return "HeroOfTatAltruism";

		return "";
	}

	static String getHeroOfTatooineSpawnStatus(const MobileDefinition& definition) {
		String eventName = getHeroOfTatooineEventName(definition);
		if (eventName.isEmpty())
			return "";

		Reference<PersistentEvent*> event = DirectorManager::getPersistentEvent(eventName);
		if (event == nullptr)
			return "SPAWN STATUS: EVENT NOT REGISTERED";

		uint64 now = Time().getMiliTime();
		uint64 scheduledTime = event->getCurTime() + event->getMiliDiff();
		if (scheduledTime <= now)
			return "SPAWN STATUS: EVENT DUE - AWAITING EXECUTION";

		uint64 secondsRemaining = (scheduledTime - now) / 1000;
		StringBuffer status;
		status << "SPAWN STATUS: WAITING FOR SPAWN\n";
		status << "NEXT SPAWN: " << (secondsRemaining / 60) << "m " << (secondsRemaining % 60) << "s";
		return status.toString();
	}

	static String getHeroOfTatooineDiagnostic(ZoneServer* zoneServer, const MobileDefinition& definition, const String& planet) {
		if (zoneServer == nullptr || planet != "tatooine" || !isHeroOfTatooineMobile(definition))
			return "";

		uint64 objectID = getHeroOfTatooineObjectID(definition.templateName);
		StringBuffer diagnostic;
		diagnostic << "\n\nHERO TRACKING:\n";
		diagnostic << "SCREENPLAY OBJECT ID: " << objectID << "\n";

		if (objectID == 0) {
			diagnostic << "OBJECT RESOLUTION: NO CURRENT SCREENPLAY OBJECT ID";
			return diagnostic.toString();
		}

		ManagedReference<SceneObject*> sceneObject = zoneServer->getObject(objectID);
		if (sceneObject == nullptr) {
			diagnostic << "OBJECT RESOLUTION: NOT LOADED";
			return diagnostic.toString();
		}

		if (!sceneObject->isAiAgent()) {
			diagnostic << "OBJECT RESOLUTION: NOT AN AI AGENT";
			return diagnostic.toString();
		}

		AiAgent* agent = sceneObject->asAiAgent();
		Zone* zone = agent != nullptr ? agent->getZone() : nullptr;
		diagnostic << "OBJECT ZONE: " << (zone != nullptr ? zone->getZoneName() : "NONE") << "\n";
		diagnostic << "OBJECT DEAD: " << (agent != nullptr && agent->isDead() ? "YES" : "NO") << "\n";

		const CreatureTemplate* creatureTemplate = agent != nullptr ? agent->getCreatureTemplate() : nullptr;
		diagnostic << "CREATURE TEMPLATE: " << (creatureTemplate != nullptr ? creatureTemplate->getTemplateName() : "NONE") << "\n";
		diagnostic << "STF NAME: " << sceneObject->getObjectNameStringIdName();
		return diagnostic.toString();
	}

	static void collectMatches(ZoneServer* zoneServer, const MobileDefinition& definition, const String& planet, Vector<String>& locations) {
		if (zoneServer == nullptr)
			return;

		SortedVector<uint64> seenObjectIDs;

		// Hero of Tatooine stores these dynamic quest objects in screenplay data.
		// Use that authoritative live object ID first because this encounter can
		// exist outside the spatial collection queried by a zone-wide scan.
		if (planet == "" || planet == "tatooine") {
			uint64 objectID = getHeroOfTatooineObjectID(definition.templateName);
			ManagedReference<SceneObject*> trackedObject = objectID != 0 ? zoneServer->getObject(objectID) : nullptr;

			if (trackedObject != nullptr && trackedObject->isAiAgent()) {
				AiAgent* agent = trackedObject->asAiAgent();
				Zone* agentZone = agent != nullptr ? agent->getZone() : nullptr;

				// The screenplay key identifies this exact encounter object. Do not
				// reject it based on a secondary template check after resolving it.
				if (agentZone != nullptr && agentZone->getZoneName() == "tatooine")
					addLocation(agent, definition, seenObjectIDs, locations);
			}
		}

		for (int i = 0; i < zoneServer->getZoneCount(); ++i) {
			ManagedReference<Zone*> zone = zoneServer->getZone(i);

			if (zone == nullptr || (planet != "" && zone->getZoneName() != planet))
				continue;

			SortedVector<ManagedReference<TreeEntry*> > objects;
			// Match /findobject's full terrestrial-zone scan. The prior radius was
			// smaller than Core3's own complete-zone search and could omit mobiles
			// that were otherwise loaded and active.
			float range = zone->getMaxX() * 2.f;
			if (range < 12000.f)
				range = 12000.f;

			zone->getInRangeObjects(0.f, 0.f, 0.f, range, &objects, true, true);

			for (int j = 0; j < objects.size(); ++j) {
				SceneObject* sceneObject = cast<SceneObject*>(objects.getUnsafe(j).get());

				if (sceneObject == nullptr || !sceneObject->isAiAgent())
					continue;

				AiAgent* agent = sceneObject->asAiAgent();
				if (agent == nullptr || agent->isDead())
					continue;

				// The Hero of Tatooine mobiles have unique STF name IDs but share
				// appearance files with unrelated boars and moisture farmers.
				if (!matchesDefinition(sceneObject, agent, definition))
					continue;

				addLocation(agent, definition, seenObjectIDs, locations);
			}
		}
	}

	static void showResults(CreatureObject* player, const MobileDefinition& definition, const String& planet) {
		if (player == nullptr || player->getPlayerObject() == nullptr)
			return;

		Vector<String> locations;
		collectMatches(player->getZoneServer(), definition, planet, locations);

		StringBuffer report;
		report << definition.displayName << "\n\n";

		if (locations.isEmpty()) {
			String spawnStatus = getHeroOfTatooineSpawnStatus(definition);
			report << "STATUS: " << (spawnStatus.isEmpty() ? "NOT FOUND" : "WAITING FOR SPAWN") << "\n";
			report << "PLANET: " << planet;
			if (!spawnStatus.isEmpty())
				report << "\n" << spawnStatus;
			report << getHeroOfTatooineDiagnostic(player->getZoneServer(), definition, planet);
		} else {
			report << "STATUS: ACTIVE\n";
			report << "COUNT: " << locations.size() << "\n\n";
			for (int i = 0; i < locations.size(); ++i) {
				if (locations.size() > 1)
					report << "[" << (i + 1) << "]\n";
				report << locations.get(i) << "\n";
			}
		}

		ManagedReference<SuiMessageBox*> box = new SuiMessageBox(player, SuiWindowType::NONE);
		box->setPromptTitle("Mobile Status Results");
		box->setPromptText(report.toString());
		box->setUsingObject(player);
		box->setCancelButton(false, "");
		box->setOkButton(true, "@ok");

		player->getPlayerObject()->addSuiBox(box);
		player->sendMessage(box->generateMessage());
	}
};

class MobileStatusMobileSuiCallback : public SuiCallback {
	String planet;

public:
	MobileStatusMobileSuiCallback(ZoneServer* server, const String& selectedPlanet) : SuiCallback(server), planet(selectedPlanet) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox() || eventIndex == 1 || args == nullptr || args->size() < 1)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);
		if (listBox == nullptr)
			return;

		int selectedIndex = -1;
		try {
			selectedIndex = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			return;
		}
		int mobileCount = 0;
		const MobileStatusUi::MobileDefinition* mobiles = MobileStatusUi::getMobiles(mobileCount);

		if (selectedIndex < 0 || selectedIndex >= mobileCount)
			return;

		MobileStatusUi::showResults(player, mobiles[selectedIndex], planet);
	}
};

class MobileStatusPlanetSuiCallback : public SuiCallback {
public:
	MobileStatusPlanetSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox() || eventIndex == 1 || args == nullptr || args->size() < 1)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);
		if (listBox == nullptr)
			return;

		int selectedIndex = -1;
		try {
			selectedIndex = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			return;
		}
		if (selectedIndex < 0 || selectedIndex >= listBox->getMenuSize())
			return;

		String planet = listBox->getMenuItemName(selectedIndex);
		ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
		box->setPromptTitle("Select Mobile - " + planet);
		box->setPromptText("Select a mobile to inspect.");
		box->setUsingObject(player);
		box->setCancelButton(true, "@cancel");
		box->setOkButton(true, "@ok");
		box->setCallback(new MobileStatusMobileSuiCallback(player->getZoneServer(), planet));

		int mobileCount = 0;
		const MobileStatusUi::MobileDefinition* mobiles = MobileStatusUi::getMobiles(mobileCount);
		for (int i = 0; i < mobileCount; ++i) {
			Vector<String> locations;
			MobileStatusUi::collectMatches(player->getZoneServer(), mobiles[i], planet, locations);

			StringBuffer label;
			label << mobiles[i].displayName << " (" << locations.size() << " active)";
			box->addMenuItem(label.toString(), i);
		}

		player->getPlayerObject()->addSuiBox(box);
		player->sendMessage(box->generateMessage());
	}
};

class MobileStatusCommand : public QueueCommand {
public:
	MobileStatusCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
		setCharacterAbility("admin");
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (server == nullptr || server->getZoneServer() == nullptr || creature == nullptr || creature->getPlayerObject() == nullptr)
			return GENERALERROR;

		ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
		box->setPromptTitle("Mobile Status - Select Planet");
		box->setPromptText("Select a planet to inspect.");
		box->setUsingObject(creature);
		box->setCancelButton(true, "@cancel");
		box->setOkButton(true, "@ok");
		box->setCallback(new MobileStatusPlanetSuiCallback(server->getZoneServer()));

		for (int i = 0; i < server->getZoneServer()->getZoneCount(); ++i) {
			ManagedReference<Zone*> zone = server->getZoneServer()->getZone(i);
			if (zone != nullptr)
				box->addMenuItem(zone->getZoneName(), i);
		}

		creature->getPlayerObject()->addSuiBox(box);
		creature->sendMessage(box->generateMessage());

		return SUCCESS;
	}
};

#endif /* MOBILESTATUSCOMMAND_H_ */
