/*
 * WorldResetCommand.h
 *
 * Bellum Gero "/worldreset" -- highly protected administrative reset of DEPLOYED
 * player structures and PLAYER-CREATED cities. See WorldResetManager.cpp for the
 * full scope / safety analysis.
 *
 * Security layers (ALL required for execute):
 *   1. Admin Level 15                              (enforced here, every subcommand)
 *   2. Private server-side secret                  (/worldreset authenticate <secret>)
 *   3. Successful, mutation-free dry run           (/worldreset dryrun)
 *   4. Armed window (~5 min)                       (/worldreset arm)
 *   5. Exact confirmation phrase                   (/worldreset execute RESET-HOUSING-AND-CITIES)
 *   + galaxy LOCKED and zero non-staff players online
 *
 * Subcommands:
 *   /worldreset authenticate <secret>
 *   /worldreset dryrun
 *   /worldreset status
 *   /worldreset arm
 *   /worldreset execute RESET-HOUSING-AND-CITIES
 *   /worldreset cancel
 */

#ifndef WORLDRESETCOMMAND_H_
#define WORLDRESETCOMMAND_H_

#include "server/zone/objects/creature/commands/QueueCommand.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/managers/worldreset/WorldResetManager.h"

class WorldResetCommand : public QueueCommand {
public:
	WorldResetCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
		// Also gate behind the "admin" ability so it is not queueable at all by
		// normal characters; the explicit Level 15 check below is the real gate.
		setCharacterAbility("admin");
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (creature == nullptr)
			return GENERALERROR;

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		PlayerObject* ghost = creature->getPlayerObject();

		// -------- SECURITY LAYER 1: Admin Level 15 (mandatory, every subcommand) --------
		if (ghost == nullptr || (int)ghost->getAdminLevel() < WorldResetManager::REQUIRED_ADMIN_LEVEL || !ghost->hasAbility("admin")) {
			creature->sendSystemMessage("You are not authorized to use this command.");

			Logger::console.info(true) << "[WORLDRESET][AUTH] DENIED /worldreset -- character "
				<< creature->getFirstName() << " (" << creature->getObjectID()
				<< ") adminLevel=" << (ghost != nullptr ? (int)ghost->getAdminLevel() : -1)
				<< " (requires " << WorldResetManager::REQUIRED_ADMIN_LEVEL << ")";

			return INSUFFICIENTPERMISSION;
		}

		String args = arguments.toString().trim();

		if (args.isEmpty()) {
			sendUsage(creature);
			return SUCCESS;
		}

		String sub;
		String rest;

		int sp = args.indexOf(" ");

		if (sp < 0) {
			sub = args.toLowerCase();
		} else {
			sub = args.subString(0, sp).toLowerCase();
			rest = args.subString(sp + 1).trim();
		}

		WorldResetManager* manager = WorldResetManager::instance();

		if (sub == "authenticate" || sub == "auth") {
			if (rest.isEmpty()) {
				creature->sendSystemMessage("Usage: /worldreset authenticate <secret>");
				return SUCCESS;
			}

			// The supplied secret is passed straight through; it is never logged
			// or echoed by the manager.
			manager->authenticate(creature, rest);
			return SUCCESS;
		}

		if (sub == "dryrun") {
			manager->runDryRun(creature);
			return SUCCESS;
		}

		if (sub == "status") {
			manager->showStatus(creature);
			return SUCCESS;
		}

		if (sub == "arm") {
			manager->arm(creature);
			return SUCCESS;
		}

		if (sub == "execute") {
			manager->execute(creature, rest);
			return SUCCESS;
		}

		if (sub == "cancel") {
			manager->cancel(creature);
			return SUCCESS;
		}

		if (sub == "clearstate") {
			manager->clearState(creature, rest);
			return SUCCESS;
		}

		if (sub == "diagnose") {
			manager->diagnose(creature);
			return SUCCESS;
		}

		if (sub == "recovery" || sub == "recoverycheck") {
			manager->recovery(creature);
			return SUCCESS;
		}

		if (sub == "resume") {
			manager->resume(creature, rest);
			return SUCCESS;
		}

		sendUsage(creature);
		return SUCCESS;
	}

private:
	void sendUsage(CreatureObject* creature) const {
		creature->sendSystemMessage(
			"/worldreset -- controlled reset of DEPLOYED player structures + PLAYER cities.\n"
			"  /worldreset authenticate <secret>\n"
			"  /worldreset dryrun\n"
			"  /worldreset status\n"
			"  /worldreset arm\n"
			"  /worldreset execute RESET-HOUSING-AND-CITIES\n"
			"  /worldreset cancel\n"
			"  /worldreset clearstate [force-discard-committed-reset]\n"
			"  /worldreset diagnose        (non-destructive classification of playerstructures.db)\n"
			"  /worldreset recoverycheck   (non-destructive report on an interrupted reset)\n"
			"  /worldreset resume RESET-HOUSING-AND-CITIES  (continue an interrupted reset: PRECHECK/CLIENT_DRAIN/CITY/STRUCTURE)");
	}
};

#endif /* WORLDRESETCOMMAND_H_ */
