/*
 * MissionTerminalImplementation.cpp
 *
 *  Created on: 03/05/11
 *      Author: polonel
 */

#include "server/zone/objects/tangible/terminal/mission/MissionTerminal.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/managers/city/CityManager.h"
#include "server/zone/managers/city/CityRemoveAmenityTask.h"
#include "server/zone/objects/player/sessions/SlicingSession.h"
#include "server/zone/managers/director/DirectorManager.h"
#include "server/zone/managers/mission/MissionManager.h"
#include "server/zone/objects/mission/MissionObject.h"
#include "server/zone/objects/player/PlayerObject.h"

#include "server/zone/managers/creature/CreatureTemplateManager.h"
#include "server/zone/managers/creature/SpawnGroup.h"
#include "server/zone/Zone.h"
#include "server/zone/objects/player/FactionStatus.h"
#include "templates/faction/Factions.h"

void MissionTerminalImplementation::fillObjectMenuResponse(ObjectMenuResponse* menuResponse, CreatureObject* player) {
	TerminalImplementation::fillObjectMenuResponse(menuResponse, player);

	ManagedReference<CityRegion*> city = player->getCityRegion().get();

	if (city != nullptr && getParent().get() == nullptr &&
			(city->isMayor(player->getObjectID())
			|| city->hasMilitiaPermission(player->getObjectID(), CityRegion::MILITIA_PERMISSION_PLACE_CIVIC))) {

		menuResponse->addRadialMenuItem(72, 3, "@city/city:mt_remove"); // Remove

		menuResponse->addRadialMenuItem(73, 3, "@city/city:align"); // Align
		menuResponse->addRadialMenuItemToRadialID(73, 74, 3, "@city/city:north"); // North
		menuResponse->addRadialMenuItemToRadialID(73, 75, 3, "@city/city:east"); // East
		menuResponse->addRadialMenuItemToRadialID(73, 76, 3, "@city/city:south"); // South
		menuResponse->addRadialMenuItemToRadialID(73, 77, 3, "@city/city:west"); // West
	}
		if (terminalType == "general" || terminalType == "imperial" || terminalType == "rebel") {
        menuResponse->addRadialMenuItem(113, 3, "Choose Mission Direction");
		menuResponse->addRadialMenuItem(114, 3, "Choose Mission Target");
    }

	if (terminalType == "bounty" && player->hasSkill("combat_bountyhunter_novice")) {
		menuResponse->addRadialMenuItem(115, 3, "Choose Bounty Contract Tier");
	}

	if (terminalType == "general" || terminalType == "imperial" || terminalType == "rebel") {
		menuResponse->addRadialMenuItem(116, 3, "Accept Top 6 Missions");
	}
}

int MissionTerminalImplementation::handleObjectMenuSelect(CreatureObject* player, byte selectedID) {
	ManagedReference<CityRegion*> city = player->getCityRegion().get();

	if (selectedID == 69 && player->hasSkill("combat_smuggler_slicing_01")) {
		if (isBountyTerminal())
			return 0;

		if (city != nullptr && !city->isClientRegion() && city->isBanned(player->getObjectID())) {
			player->sendSystemMessage("@city/city:banned_services"); // You are banned from using this city's services.
			return 0;
		}

		if (player->containsActiveSession(SessionFacadeType::SLICING)) {
			player->sendSystemMessage("@slicing/slicing:already_slicing");
			return 0;
		}

		if (!player->checkCooldownRecovery("slicing.terminal")) {
			StringIdChatParameter message;
			message.setStringId("@slicing/slicing:not_yet"); // You will be able to hack the network again in %DI seconds.
			message.setDI(player->getCooldownTime("slicing.terminal")->getTime() - Time().getTime());
			player->sendSystemMessage(message);
			return 0;
		}

		//Create Session
		ManagedReference<SlicingSession*> session = new SlicingSession(player);
		session->initalizeSlicingMenu(player, _this.getReferenceUnsafeStaticCast());

		return 0;

	} else if (selectedID == 72) {

		if (city != nullptr && (city->isMayor(player->getObjectID())
				|| city->hasMilitiaPermission(player->getObjectID(), CityRegion::MILITIA_PERMISSION_PLACE_CIVIC))) {
			CityRemoveAmenityTask* task = new CityRemoveAmenityTask(_this.getReferenceUnsafeStaticCast(), city);
			task->execute();

			player->sendSystemMessage("@city/city:mt_removed"); // The object has been removed from the city.
		}

		return 0;

	} else if (selectedID == 74 || selectedID == 75 || selectedID == 76 || selectedID == 77) {

		CityManager* cityManager = getZoneServer()->getCityManager();
		cityManager->alignAmenity(city, player, _this.getReferenceUnsafeStaticCast(), selectedID - 74);

		return 0;
	} else if (selectedID == 113) {
        
        Lua* lua = DirectorManager::instance()->getLuaInstance();
        
        Reference<LuaFunction*> mission_direction_choice = lua->createFunction("mission_direction_choice", "openWindow", 0);
        *mission_direction_choice << player;
        
        mission_direction_choice->callFunction();
        return 0;
	} else if (selectedID == 114) {
    Zone* zone = player->getZone();
    if (zone == nullptr) return 0;

    // Determine which destroy-mission group this terminal uses (mirror mission logic)
    String missionGroup;
    if (terminalType == "general") {
        missionGroup = zone->getZoneName() + "_destroy_missions";
    } else {
        bool neutralMission = true;
        uint32 termFaction = (terminalType == "imperial") ? Factions::FACTIONIMPERIAL : Factions::FACTIONREBEL;

        if (player->getFaction() != 0 && player->getFaction() == termFaction) {
            if (player->getFactionStatus() == FactionStatus::OVERT || player->getFactionStatus() == FactionStatus::COVERT)
                neutralMission = false;
        }

        if (neutralMission)
            missionGroup = "factional_neutral_destroy_missions";
        else if (termFaction == Factions::FACTIONIMPERIAL)
            missionGroup = "factional_imperial_destroy_missions";
        else
            missionGroup = "factional_rebel_destroy_missions";
    }

    SpawnGroup* group = CreatureTemplateManager::instance()->getDestroyMissionGroup(missionGroup.hashCode());

    // Build a newline-delimited list of "template|maxCL" to hand to Lua
    String listString;
    if (group != nullptr) {
    const Vector<Reference<LairSpawn*>>& spawns = group->getSpawnList();

    // PASS 1: compute the highest maxDifficulty per lair template
    HashTable<uint32, int> bestMax(2048);
    for (int i = 0; i < spawns.size(); ++i) {
        LairSpawn* sp = spawns.get(i);
        if (sp == nullptr) continue;

        const String& tmpl = sp->getLairTemplateName();
        uint32 crc = tmpl.hashCode();

        // ---- Pick the getter your fork exposes (UNCOMMENT ONE) ----
        int maxCL = 0;
         maxCL = sp->getMaxDifficulty();  // most Core3 forks
        // maxCL = sp->getMaxLevel();       // some forks
        // maxCL = sp->getDifficultyMax();  // others
        // ------------------------------------------------------------

        int prev = 0;
        if (bestMax.containsKey(crc))
            prev = bestMax.get(crc);
        if (maxCL > prev)
            bestMax.put(crc, maxCL);
    }

    // PASS 2: emit one line per unique template with its highest maxDifficulty
    HashTable<uint32, bool> seen(2048);
    for (int i = 0; i < spawns.size(); ++i) {
        LairSpawn* sp = spawns.get(i);
        if (sp == nullptr) continue;

        const String& tmpl = sp->getLairTemplateName();
        uint32 crc = tmpl.hashCode();
        if (seen.containsKey(crc)) continue;
        seen.put(crc, true);

        int maxCL = 0;
        if (bestMax.containsKey(crc))
            maxCL = bestMax.get(crc);

        if (!listString.isEmpty())
            listString += "\n";

        // Format: template|maxCL (Lua also tolerates template-only if maxCL==0)
        listString += tmpl + "|" + String::valueOf(maxCL);
    }
}

    // Persist the exact list we’re showing so MissionManager can reconstruct reliably
    PlayerObject* ghost = player->getPlayerObject();
    if (ghost != nullptr) {
        ghost->setScreenPlayData("mission_target_choice", "lastList", listString);
        ghost->setScreenPlayData("mission_target_choice", "lastPlanet", zone->getZoneName());
    }

    // Open the Lua UI with the list + planet
    Lua* lua = DirectorManager::instance()->getLuaInstance();
    Reference<LuaFunction*> fn = lua->createFunction("mission_target_choice", "openWithList", 0);
    *fn << player;
    *fn << listString;
    *fn << zone->getZoneName();
    fn->callFunction();

    return 0;
	} else if (selectedID == 115) {
		if (!isBountyTerminal() || !player->hasSkill("combat_bountyhunter_novice"))
			return 0;

		Lua* lua = DirectorManager::instance()->getLuaInstance();
		Reference<LuaFunction*> fn = lua->createFunction("bounty_contract_tier", "openWindow", 0);
		*fn << player;
		fn->callFunction();

		return 0;
	} else if (selectedID == 116) {
		PlayerObject* ghost = player->getPlayerObject();
		if (ghost == nullptr)
			return 0;

		String lastID = ghost->getScreenPlayData("missionTerminalSession", "lastTerminalID");
		if (lastID != String::valueOf(_this.getReferenceUnsafeStaticCast()->getObjectID())) {
			player->sendSystemMessage("You must open this terminal's mission list before accepting missions.");
			return 0;
		}

		SceneObject* missionBag = player->getSlottedObject("mission_bag");
		SceneObject* datapad = player->getSlottedObject("datapad");

		if (missionBag == nullptr || datapad == nullptr)
			return 0;

		// Match missions to this terminal's faction so Imperial/Rebel terminals
		// don't accidentally accept General missions left over from a prior browse
		uint32 expectedFaction = Factions::FACTIONNEUTRAL;
		if (terminalType == "imperial")
			expectedFaction = Factions::FACTIONIMPERIAL;
		else if (terminalType == "rebel")
			expectedFaction = Factions::FACTIONREBEL;

		// Snapshot populated missions before iterating — transferObject modifies the bag
		Vector<ManagedReference<MissionObject*>> candidates;
		for (int i = 0; i < missionBag->getContainerObjectsSize(); ++i) {
			SceneObject* obj = missionBag->getContainerObject(i);
			if (obj != nullptr && obj->isMissionObject()) {
				MissionObject* mission = cast<MissionObject*>(obj);
				if (mission != nullptr && mission->getTypeCRC() != 0 && mission->getFaction() == expectedFaction)
					candidates.add(mission);
			}
		}

		if (candidates.isEmpty()) {
			player->sendSystemMessage("No missions available from this terminal. Open the terminal to browse its mission list first.");
			return 0;
		}

		int beforeCount = 0;
		for (int i = 0; i < datapad->getContainerObjectsSize(); ++i) {
			if (datapad->getContainerObject(i) != nullptr && datapad->getContainerObject(i)->isMissionObject())
				++beforeCount;
		}

		if (beforeCount >= 6) {
			StringIdChatParameter stringId("mission/mission_generic", "too_many_missions");
			player->sendSystemMessage(stringId);
			return 0;
		}

		// Sort by reward descending so we accept the highest-paying missions first
		std::vector<ManagedReference<MissionObject*>> sorted(candidates.size());
		for (int i = 0; i < candidates.size(); ++i)
			sorted[i] = candidates.get(i);
		std::sort(sorted.begin(), sorted.end(), [](const ManagedReference<MissionObject*>& a, const ManagedReference<MissionObject*>& b) {
			int rewardA = (a != nullptr) ? a->getRewardCredits() : 0;
			int rewardB = (b != nullptr) ? b->getRewardCredits() : 0;
			return rewardA > rewardB;
		});

		MissionManager* missionManager = getZoneServer()->getMissionManager();
		MissionTerminal* terminal = _this.getReferenceUnsafeStaticCast();

		for (auto& mission : sorted) {
			if (mission == nullptr) continue;
			Locker missionLock(mission, player);
			missionManager->handleMissionAccept(terminal, mission, player);
		}

		int afterCount = 0;
		for (int i = 0; i < datapad->getContainerObjectsSize(); ++i) {
			if (datapad->getContainerObject(i) != nullptr && datapad->getContainerObject(i)->isMissionObject())
				++afterCount;
		}

		int accepted = afterCount - beforeCount;
		if (accepted > 0)
			player->sendSystemMessage("Accepted " + String::valueOf(accepted) + " mission(s).");
		else
			player->sendSystemMessage("Could not accept any missions. You may already have 6 active missions.");

		return 0;
	}

	return TangibleObjectImplementation::handleObjectMenuSelect(player, selectedID);
}

String MissionTerminalImplementation::getTerminalName() {
	String name = "@terminal_name:terminal_mission";

	if (terminalType == "artisan" || terminalType == "entertainer" || terminalType == "bounty" || terminalType == "imperial" || terminalType == "rebel" || terminalType == "scout")
		name = name + "_" + terminalType;

	return name;
}
