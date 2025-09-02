/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef GCWSTATUSCOMMAND_H_
#define GCWSTATUSCOMMAND_H_

#include "server/zone/Zone.h"
#include "server/zone/managers/gcw/GCWManager.h"
#include "templates/faction/Factions.h"

class GcwStatusCommand : public QueueCommand {
public:

	GcwStatusCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		Zone* zone = creature->getZone();
		if (zone == nullptr)
			return GENERALERROR;

		GCWManager* gcwMan = zone->getGCWManager();

		if (gcwMan == nullptr)
			return GENERALERROR;

		// temporary for testing gcw bases
		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

		if (ghost != nullptr && ghost->isPrivileged()) {
			int rebelBases = gcwMan->getRebelBaseCount();
			int imperialBases = gcwMan->getImperialBaseCount();

			int rebelScore = gcwMan->getRebelScore();
			int imperialScore = gcwMan->getImperialScore();

			StringBuffer msg;
			msg << "Rebel Score: " + String::valueOf(rebelScore) << endl;
			msg << "Imperial Score " + String::valueOf(imperialScore) << endl;
			msg << "Rebel Bases: " + String::valueOf(rebelBases) << endl;
			msg << "Imperial Bases: " + String::valueOf(imperialBases);

			creature->sendSystemMessage(msg.toString());
		} else {
    		// allow simple args: "", "all", or a planet name
    		String args = arguments.toString();
    		args = args.toLowerCase().trim();

    		auto printOne = [&](CreatureObject* who, Zone* z) {
        		if (z == nullptr) return;
        		GCWManager* gm = z->getGCWManager();
        		if (gm == nullptr) return;

        		unsigned int winner = gm->getWinningFaction(); // 0 neutral, Factions::FACTIONIMPERIAL, Factions::FACTIONREBEL
        		int imp = gm->getImperialScore();
        		int reb = gm->getRebelScore();
        		int total = imp + reb;

        		String label = "Neutral";
        		if (winner == Factions::FACTIONIMPERIAL) label = "Imperial";
        		else if (winner == Factions::FACTIONREBEL) label = "Rebel";

        		StringBuffer msg;
        		msg << "GCW Control on " << z->getZoneName() << ": " << label;

        		if (total > 0) {
            		int impPct = (imp * 100) / total;
            		int rebPct = (reb * 100) / total;
            		msg << "  (Imp " << String::valueOf(impPct) << "%, Reb " << String::valueOf(rebPct) << "%)";
        		}

        		who->sendSystemMessage(msg.toString());
    		};

    		if (args == "all") {
        		static const char* PLANETS[] = {
            		"tatooine","naboo","corellia","rori","talus",
            		"dantooine","lok","endor","dathomir","yavin4"
        		};
        		StringBuffer header;
        		header << "GCW Planet Control:";
        		creature->sendSystemMessage(header.toString());

        		for (int i = 0; i < (int)(sizeof(PLANETS)/sizeof(PLANETS[0])); ++i) {
            		Zone* z = server->getZoneServer()->getZone(PLANETS[i]);
            		printOne(creature, z);
        		}
    		} else if (args.length() > 0) {
        		Zone* z = server->getZoneServer()->getZone(args);
        		if (z == nullptr) {
            		creature->sendSystemMessage("Unknown planet. Try: /gcwstatus, /gcwstatus all, or /gcwstatus <planet>.");
        		} else {
            		printOne(creature, z);
        		}
    		} else {
        		// default: current planet
        		printOne(creature, zone);
    		}
		}

		return SUCCESS;
	}

};

#endif //GCWSTATUSCOMMAND_H_
