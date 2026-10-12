/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#ifndef TOTALHEALOTHERCOMMAND_H_
#define TOTALHEALOTHERCOMMAND_H_

#include "ForceHealQueueCommand.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/objectcontroller/ObjectController.h"

#include <map>
#include <mutex>

/*
 * Bellum Gero: Automatic Total Heal by Tell.
 *
 * /totalhealother auto   - toggles auto mode for this session
 * /totalhealother status - reports auto mode state
 *
 * While enabled, a tell of exactly "heal" (case/whitespace insensitive) makes the server
 * enqueue /totalhealother on the healer's own command queue, targeting the tell sender.
 * The heal therefore runs through the normal queue timing and ForceHealQueueCommand
 * validation (ability, Force, range, LOS, PvP, states) with no duplicated heal logic,
 * and the healer's look-at target is never changed.
 *
 * State is session-only and keyed by object ID (no object pointers are stored).
 */
class TotalHealOtherCommand : public ForceHealQueueCommand {
	// healer ID -> (requester ID -> time the request was queued, in ms)
	inline static std::map<uint64, std::map<uint64, uint64>> autoHealers;
	inline static std::mutex autoHealMutex;

	static constexpr int MAX_PENDING_AUTO_HEALS = 5;
	static constexpr uint64 PENDING_AUTO_HEAL_EXPIRY_MS = 30000;

	static constexpr const char* AUTO_TELL_ARG = "__autotellheal";

	static String parseArgument(const UnicodeString& arguments) {
		return arguments.toString().trim().toLowerCase();
	}

	static bool canUseTotalHeal(CreatureObject* creature) {
		if (creature == nullptr)
			return false;

		auto ghost = creature->getPlayerObject();
		auto zoneServer = creature->getZoneServer();

		if (ghost == nullptr || zoneServer == nullptr)
			return false;

		const QueueCommand* command = zoneServer->getObjectController()->getQueueCommand(STRING_HASHCODE("totalhealother"));

		if (command == nullptr)
			return false;

		const String& ability = command->getCharacterAbility();

		return ghost->hasAbility(ability.length() > 1 ? ability : command->getQueueCommandName());
	}

	static bool setAutoHealEnabled(uint64 healerID, bool enabled) {
		std::lock_guard<std::mutex> guard(autoHealMutex);

		if (enabled)
			autoHealers[healerID];
		else
			autoHealers.erase(healerID);

		return enabled;
	}

	static void purgeExpired(std::map<uint64, uint64>& pending, uint64 now) {
		for (auto it = pending.begin(); it != pending.end();) {
			if (now - it->second > PENDING_AUTO_HEAL_EXPIRY_MS)
				it = pending.erase(it);
			else
				++it;
		}
	}

	enum { PENDING_ADDED, PENDING_DUPLICATE, PENDING_FULL, PENDING_DISABLED };

	static int addPendingRequest(uint64 healerID, uint64 requesterID) {
		std::lock_guard<std::mutex> guard(autoHealMutex);

		auto entry = autoHealers.find(healerID);

		if (entry == autoHealers.end())
			return PENDING_DISABLED;

		auto& pending = entry->second;
		uint64 now = Time().getMiliTime();

		purgeExpired(pending, now);

		if (pending.find(requesterID) != pending.end())
			return PENDING_DUPLICATE;

		if (pending.size() >= MAX_PENDING_AUTO_HEALS)
			return PENDING_FULL;

		pending[requesterID] = now;

		return PENDING_ADDED;
	}

	// Returns true only if this exact healer/requester pair was queued by a tell.
	static bool consumePendingRequest(uint64 healerID, uint64 requesterID) {
		std::lock_guard<std::mutex> guard(autoHealMutex);

		auto entry = autoHealers.find(healerID);

		if (entry == autoHealers.end())
			return false;

		return entry->second.erase(requesterID) > 0;
	}

	int toggleAutoHeal(CreatureObject* creature) const {
		if (isAutoHealEnabled(creature->getObjectID())) {
			setAutoHealEnabled(creature->getObjectID(), false);
			creature->sendSystemMessage("Automatic Total Heal by Tell is now DISABLED.");
			return SUCCESS;
		}

		if (!canUseTotalHeal(creature)) {
			creature->sendSystemMessage("You must be able to use Total Heal to enable Automatic Total Heal by Tell.");
			return GENERALERROR;
		}

		setAutoHealEnabled(creature->getObjectID(), true);
		creature->sendSystemMessage("Automatic Total Heal by Tell is now ENABLED.");
		creature->sendSystemMessage("Players may send you a tell containing 'heal' to request Total Heal.");

		return SUCCESS;
	}

	int doAutoTellHeal(CreatureObject* creature, const uint64& target) const {
		ManagedReference<SceneObject*> object = server->getZoneServer()->getObject(target);

		if (object == nullptr || !object->isPlayerCreature())
			return GENERALERROR;

		ManagedReference<CreatureObject*> requester = object.castTo<CreatureObject*>();

		if (requester == nullptr || !requester->isOnline())
			return GENERALERROR;

		if (!isAutoHealEnabled(creature->getObjectID())) {
			requester->sendSystemMessage("The Master Healer cannot heal you right now.");
			return GENERALERROR;
		}

		// checkDistance() only compares world coordinates, so a requester on another
		// planet must be rejected explicitly.
		if (creature->getZone() == nullptr || requester->getZone() != creature->getZone()) {
			requester->sendSystemMessage("You are too far away from the Master Healer.");
			return TOOFAR;
		}

		auto ghost = creature->getPlayerObject();
		bool lowForce = ghost != nullptr && ghost->getForcePower() < getFrsModifiedForceCost(creature);

		int result = ForceHealQueueCommand::doQueueCommand(creature, target, "");

		if (result == SUCCESS) {
			requester->sendSystemMessage("You have received Total Heal from " + creature->getFirstName() + ".");
			creature->sendSystemMessage("Automatic Total Heal applied to " + requester->getFirstName() + ".");
		} else if (result == TOOFAR) {
			requester->sendSystemMessage("You are too far away from the Master Healer.");
		} else if (lowForce) {
			requester->sendSystemMessage("The Master Healer does not have enough Force.");
		} else {
			requester->sendSystemMessage("The Master Healer cannot heal you right now.");
		}

		return result;
	}

public:
	TotalHealOtherCommand(const String& name, ZoneProcessServer* server) : ForceHealQueueCommand(name, server) {}

	float getCommandDuration(CreatureObject* object, const UnicodeString& arguments) const override {
		String arg = parseArgument(arguments);

		// Toggling/querying auto mode must not cost the healer an action delay.
		if (arg == "auto" || arg == "status")
			return 0.f;

		return ForceHealQueueCommand::getCommandDuration(object, arguments);
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const override {
		if (creature == nullptr || !creature->isPlayerCreature())
			return GENERALERROR;

		String arg = parseArgument(arguments);

		if (arg == "auto")
			return toggleAutoHeal(creature);

		if (arg == "status") {
			if (isAutoHealEnabled(creature->getObjectID()))
				creature->sendSystemMessage("Automatic Total Heal by Tell is currently ENABLED.");
			else
				creature->sendSystemMessage("Automatic Total Heal by Tell is currently DISABLED.");

			return SUCCESS;
		}

		// The marker is only honored for a request that was actually queued by a tell;
		// anything else (including a player typing the marker) is a normal manual heal.
		if (arg == AUTO_TELL_ARG && consumePendingRequest(creature->getObjectID(), target))
			return doAutoTellHeal(creature, target);

		return ForceHealQueueCommand::doQueueCommand(creature, target, arguments);
	}

	static bool isAutoHealEnabled(uint64 healerID) {
		std::lock_guard<std::mutex> guard(autoHealMutex);

		return autoHealers.find(healerID) != autoHealers.end();
	}

	// Called when the healer goes offline (logout, link-dead, disconnect).
	static void clearAutoHeal(uint64 healerID) {
		setAutoHealEnabled(healerID, false);
	}

	/*
	 * Called by ChatManager after a player-to-player tell has been delivered.
	 * sender is the authenticated client's creature, never a name from the message text.
	 */
	static void handleIncomingTell(CreatureObject* healerArg, CreatureObject* senderArg, const UnicodeString& message) {
		if (healerArg == nullptr || senderArg == nullptr || healerArg == senderArg)
			return;

		if (!healerArg->isPlayerCreature() || !senderArg->isPlayerCreature())
			return;

		if (!isAutoHealEnabled(healerArg->getObjectID()))
			return;

		if (parseArgument(message) != "heal")
			return;

		ManagedReference<CreatureObject*> healer = healerArg;
		ManagedReference<CreatureObject*> requester = senderArg;

		// The chat handler holds no locks; do the work as a task with the healer locked,
		// matching how other server-side code calls sendCommand.
		Core::getTaskManager()->executeTask([healer, requester] () {
			Locker locker(healer);

			uint64 healerID = healer->getObjectID();
			uint64 requesterID = requester->getObjectID();

			if (!healer->isOnline()) {
				clearAutoHeal(healerID);
				return;
			}

			if (!canUseTotalHeal(healer)) {
				clearAutoHeal(healerID);
				healer->sendSystemMessage("Automatic Total Heal by Tell has been DISABLED because you can no longer use Total Heal.");
				requester->sendSystemMessage("The Master Healer cannot heal you right now.");
				return;
			}

			if (!requester->isOnline())
				return;

			if (healer->getZone() == nullptr || requester->getZone() != healer->getZone()) {
				requester->sendSystemMessage("You are too far away from the Master Healer.");
				return;
			}

			int pending = addPendingRequest(healerID, requesterID);

			if (pending == PENDING_DUPLICATE) {
				requester->sendSystemMessage("Your Total Heal request is already pending.");
				return;
			}

			if (pending == PENDING_FULL) {
				requester->sendSystemMessage("The Master Healer cannot heal you right now.");
				return;
			}

			if (pending != PENDING_ADDED)
				return;

			healer->sendCommand(STRING_HASHCODE("totalhealother"), AUTO_TELL_ARG, requesterID, QueueCommand::NORMAL);
		}, "AutoTotalHealTellTask");
	}
};

#endif //TOTALHEALOTHERCOMMAND_H_
