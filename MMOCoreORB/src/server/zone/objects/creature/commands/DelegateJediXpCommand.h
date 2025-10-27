/*
			Copyright <SWGEmu>
	See file COPYING for copying conditions.*/

#ifndef DELEGATEJEDIXPCOMMAND_H_
#define DELEGATEJEDIXPCOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/objects/transaction/TransactionLog.h"

class DelegateJediXpCommand : public QueueCommand {
public:

	DelegateJediXpCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		try {

			StringTokenizer args(arguments.toString());

			// Validate source is a Jedi
			if (!creature->hasSkill("force_title_jedi_novice")) {
				creature->sendSystemMessage("You must be a Jedi to delegate XP.");
				return GENERALERROR;
			}

			// Check if a target was provided
			ManagedReference<SceneObject*> targetObject =
				server->getZoneServer()->getObject(target);

			ManagedReference<CreatureObject*> targetPlayer = nullptr;

			// If target is a player, use them
			if (targetObject != nullptr && targetObject->isPlayerCreature()) {
				targetPlayer = cast<CreatureObject*>(targetObject.get());
			}

			// Otherwise, try to parse target from arguments
			if (targetPlayer == nullptr) {
				String targetName;
				if (!args.hasMoreTokens()) {
					creature->sendSystemMessage("Usage: /delegatejedixp <target_player_name> <xp_amount>");
					return GENERALERROR;
				}

				args.getStringToken(targetName);

				PlayerManager* playerManager = server->getZoneServer()->getPlayerManager();
				targetPlayer = playerManager->getPlayer(targetName);
			}

			// Get XP amount
			if (!args.hasMoreTokens()) {
				creature->sendSystemMessage("Usage: /delegatejedixp <xp_amount>");
				return GENERALERROR;
			}

			int xpAmount = args.getIntToken();

			// Validate XP amount
			if (xpAmount <= 0) {
				creature->sendSystemMessage("XP amount must be a positive number.");
				return GENERALERROR;
			}

			// Check daily limit for source player
			uint64 playerID = creature->getObjectID();
			String todayDate = String::format("%lu", (unsigned long)time(nullptr) / 86400); // Days since epoch
			String lastLimitKey = String::format("%llu:delegateXP_lastDate", (unsigned long long)playerID);
			String delegatedTodayKey = String::format("%llu:delegateXP_today", (unsigned long long)playerID);

			// Get current daily limit (using simple in-memory tracking - you could use database instead)
			static std::map<uint64, std::pair<String, int> > dailyLimits; // playerID -> (date, amount)

			int delegatedToday = 0;
			const int DAILY_LIMIT = 200000;

			// Check if we need to reset daily limit
			if (dailyLimits.find(playerID) != dailyLimits.end()) {
				if (dailyLimits[playerID].first != todayDate) {
					// New day, reset limit
					delegatedToday = 0;
					dailyLimits[playerID].first = todayDate;
					dailyLimits[playerID].second = 0;
				} else {
					delegatedToday = dailyLimits[playerID].second;
				}
			} else {
				// First time tracking this player
				dailyLimits[playerID].first = todayDate;
				dailyLimits[playerID].second = 0;
			}

			// Check if transfer would exceed daily limit
			if ((delegatedToday + xpAmount) > DAILY_LIMIT) {
				int remaining = DAILY_LIMIT - delegatedToday;
				creature->sendSystemMessage(String::format("Daily XP delegation limit reached. You can delegate %d more XP today.", remaining));
				return GENERALERROR;
			}

			// Check if target player was found
			if (targetPlayer == nullptr) {
				creature->sendSystemMessage("Target player not found online.");
				return GENERALERROR;
			}

			// Check if target is also a Jedi
			if (!targetPlayer->hasSkill("force_title_jedi_novice")) {
				creature->sendSystemMessage("Target player must be a Jedi to receive delegated XP.");
				return GENERALERROR;
			}

			// Check if source player has enough XP to delegate
			int sourceXP = 0;
			PlayerObject* sourceGhost = creature->getPlayerObject();
			if (sourceGhost != nullptr) {
				sourceXP = sourceGhost->getExperience("jedi_general");
			}

			if (sourceXP < xpAmount) {
				creature->sendSystemMessage(String::format("You do not have enough jedi_general to delegate. Current: %d", sourceXP));
				return GENERALERROR;
			}

			// Perform the transfer
			Locker clocker(targetPlayer, creature);

			try {
				// Remove XP from source and give to target
				PlayerObject* targetGhost = targetPlayer->getPlayerObject();
				if (targetGhost != nullptr) {
					// Add XP to target player (negative amount adds XP)
					TransactionLog trxTarget(creature, targetPlayer, TrxCode::UNKNOWN);
					targetGhost->addExperience(trxTarget, "jedi_general", -xpAmount, true);

					// Remove XP from source player (positive amount removes XP)
					TransactionLog trxSource(creature, targetPlayer, TrxCode::UNKNOWN);
					sourceGhost->addExperience(trxSource, "jedi_general", xpAmount, true);
				}

				// Update daily limit
				delegatedToday += xpAmount;
				dailyLimits[playerID].second = delegatedToday;

				// Send success messages
				creature->sendSystemMessage(String::format("Successfully delegated %d jedi_general to %s. Daily limit: %d/%d",
					xpAmount, targetPlayer->getFirstName().toCharArray(), delegatedToday, DAILY_LIMIT));

				targetPlayer->sendSystemMessage(String::format("Received %d jedi_general delegated from %s.",
					xpAmount, creature->getFirstName().toCharArray()));

			} catch (Exception& e) {
				creature->sendSystemMessage("Error occurred during XP delegation. Transfer may have failed.");
				return GENERALERROR;
			}

		} catch (Exception& e) {
			creature->sendSystemMessage("Usage: /delegatejedixp <target_player_name> <xp_amount>");
			return GENERALERROR;
		}

		return SUCCESS;
	}

};

#endif //DELEGATEJEDIXPCOMMAND_H_
