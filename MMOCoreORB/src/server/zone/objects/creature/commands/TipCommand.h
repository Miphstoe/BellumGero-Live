/*
 				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#ifndef TIPCOMMAND_H_
#define TIPCOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/callbacks/TipCommandSuiCallback.h"
#include "server/zone/objects/transaction/TransactionLog.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/creature/commands/QueueCommand.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/chat/ChatManager.h"

class TipCommand: public QueueCommand {
private:

	int performTip(CreatureObject* player, CreatureObject* targetPlayer,
			int amount) const {

		// Target player must be in range (I think it's likely to assume this is the maximum targeting range, 190m)
		if (!checkDistance(player, targetPlayer, 190)) {
			StringIdChatParameter ptr("base_player", "prose_tip_range"); // You are too far away to tip %TT with cash. You can send a wire transfer instead.
			ptr.setTT(targetPlayer->getCreatureName());
			player->sendSystemMessage(ptr);
			return GENERALERROR;
		}

		// Player must have sufficient funds
		int cash = player->getCashCredits();
		if (amount > cash) {
			StringIdChatParameter ptnsfc("base_player", "prose_tip_nsf_cash"); // You lack the cash funds to tip %DI credits to %TT.
			ptnsfc.setDI(amount);
			ptnsfc.setTT(targetPlayer->getObjectID());
			player->sendSystemMessage(ptnsfc);
			return GENERALERROR;
		}

		// Player must not be ignored
		auto target = targetPlayer->getPlayerObject();

		if (target != nullptr) {
			if (target->isIgnoring(player->getFirstName()))
				return GENERALERROR;
		}

		// We have a target, who is on-line, in range, with sufficient funds.
		// Lock target player to prevent simultaneous tips to not register correctly.

		Locker clocker(targetPlayer, player);
		{
			TransactionLog trx(player, targetPlayer, TrxCode::PLAYERTIP, amount, true);
			player->subtractCashCredits(amount);
			targetPlayer->addCashCredits(amount, true);
		}

		StringIdChatParameter tiptarget("base_player", "prose_tip_pass_target"); // %TT tips you %DI credits.
		tiptarget.setDI(amount);
		tiptarget.setTT(player->getCreatureName());
		targetPlayer->sendSystemMessage(tiptarget);

		StringIdChatParameter tipself("base_player", "prose_tip_pass_self"); // You successfully tip %DI credits to %TT.
		tipself.setDI(amount);
		tipself.setTT(targetPlayer->getCreatureName());
		player->sendSystemMessage(tipself);

		// Send email notifications for cash tip
		ManagedReference<ChatManager*> chatManager = player->getZoneServer()->getChatManager();
		if (chatManager != nullptr) {
			UnicodeString subject("Cash Tip Received");
			String sender = "Galactic Banking";

			// Email to target player
			StringBuffer bodyTarget;
			bodyTarget << player->getCreatureName().toString() << " has cash tipped you " << amount << " credits.";
			chatManager->sendMail(sender, subject, UnicodeString(bodyTarget.toString()), targetPlayer->getFirstName());

			// Email to sender
			UnicodeString subjectSelf("Cash Tip Sent");
			StringBuffer bodySelf;
			bodySelf << "You have successfully cash tipped " << amount << " credits to " << targetPlayer->getCreatureName().toString() << ".";
			chatManager->sendMail(sender, subjectSelf, UnicodeString(bodySelf.toString()), player->getFirstName());
		}

		return SUCCESS;
	}

	int performBankTip(CreatureObject* player, CreatureObject* targetPlayer,
			int amount) const {

		auto ghost = player->getPlayerObject();
		if (ghost == nullptr) {
			player->sendSystemMessage("@base_player:tip_error"); // There was an error processing your /tip request. Please try again.
			return GENERALERROR;
		}

		// Player must have sufficient bank funds
		int cash = player->getBankCredits();
		if (amount > cash) {
			StringIdChatParameter ptnsfb("base_player", "prose_tip_nsf_bank"); // You lack the bank funds to wire %DI credits to %TT.
			ptnsfb.setDI(amount);
			ptnsfb.setTT(targetPlayer->getCreatureName());
			player->sendSystemMessage(ptnsfb);
			return GENERALERROR;
		}

		// Player must not be ignored
		auto target = targetPlayer->getPlayerObject();
		if (target == nullptr || target->isIgnoring(player->getFirstName())) {
				return GENERALERROR;
		}

		// Perform the bank tip immediately without confirmation
		Locker clocker(targetPlayer, player);
		{
			TransactionLog trx(player, targetPlayer, TrxCode::PLAYERTIP, amount, true);
			player->subtractBankCredits(amount);
			targetPlayer->addBankCredits(amount, true);
		}

		// Send in-game message to target (if online)
		StringIdChatParameter tiptarget("base_player", "prose_wire_pass_target"); // %TT has sent you %DI credits.
		tiptarget.setDI(amount);
		tiptarget.setTO(player->getCreatureName());
		targetPlayer->sendSystemMessage(tiptarget);

		// Confirm to sender
		StringIdChatParameter tipself("base_player", "prose_wire_pass_self"); // You have successfully sent %DI bank credits to %TO.
		tipself.setDI(amount);
		tipself.setTO(targetPlayer->getCreatureName());
		player->sendSystemMessage(tipself);

		// Send email notifications to both players
		ManagedReference<ChatManager*> chatManager = player->getZoneServer()->getChatManager();
		if (chatManager != nullptr) {
			UnicodeString subject("@base_player:wire_mail_subject"); // Bank Transfer Complete
			String sender = "bank";

			// Email to target player
			StringIdChatParameter bodyTarget("@base_player:prose_wire_mail_target");
			// %DI credits from %TO have been successfully delivered from escrow to your bank account.
			bodyTarget.setTO(player->getCreatureName());
			bodyTarget.setDI(amount);
			chatManager->sendMail(sender, subject, bodyTarget, targetPlayer->getFirstName());

			// Email to sender
			StringIdChatParameter bodySelf("@base_player:prose_wire_mail_self");
			// %TO has received %DI credits from you, via bank wire transfer.
			bodySelf.setTO(targetPlayer->getCreatureName());
			bodySelf.setDI(amount);
			chatManager->sendMail(sender, subject, bodySelf, player->getFirstName());
		}

		return SUCCESS;
	}

public:

	TipCommand(const String& name, ZoneProcessServer* server) :
		QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target,
			const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		ManagedReference<CreatureObject*> targetPlayer = nullptr;
		int amount = 0;
		bool isBank = false;

		// Check arguments. /tip [playername] <amount> [bank]
		// Parse the arguments
		StringTokenizer args(arguments.toString());

		String amountOrPlayer;
		bool syntaxError = false;

		try {
			args.getStringToken(amountOrPlayer);

			//Check for people impersonating the bank.
			if (amountOrPlayer == "bank") {
				creature->sendSystemMessage("@base_player:tip_syntax"); //SYNTAX: /tip (to current target) or /tip
				return INVALIDPARAMETERS;
			}

			amount = Integer::valueOf(amountOrPlayer);

			if (amount == 0) { // First param is player or invalid
				targetPlayer = server->getZoneServer()->getPlayerManager()->getPlayer(amountOrPlayer);

				amount = args.getIntToken();
				if(amount == 0)
					throw NumberFormatException();

				if (targetPlayer == nullptr) {
					StringIdChatParameter ptip("base_player", "prose_tip_invalid_param"); // /TIP: invalid amount ("%TO") parameter.
					ptip.setTO(amountOrPlayer);
					creature->sendSystemMessage(ptip);
					return INVALIDPARAMETERS;
				}
			}

			if (args.hasMoreTokens()) {
				String param;
				args.getStringToken(param);
				isBank = (param.toLowerCase() == "bank"); //TODO: locale aware. Possibly @acct_n:bank
			} else
				isBank = false;

		} catch (Exception &e) {
			syntaxError = true;
		}

		if (!syntaxError && targetPlayer == nullptr) { // No target argument, check look-at target
			auto object = server->getZoneServer()->getObject(target);

			if (object != nullptr && object->isPlayerCreature()) {
				targetPlayer = object->asCreatureObject();
			} else if (object != nullptr) {
				StringIdChatParameter ptip("base_player",
						"prose_tip_invalid_param"); // /TIP: invalid amount ("%TO") parameter.
				ptip.setTO(object->getObjectID());
				creature->sendSystemMessage(ptip);
				return INVALIDPARAMETERS;
			} else {
				syntaxError = true;
			}
		}

		if (syntaxError) {
			creature->sendSystemMessage("@base_player:tip_syntax"); // SYNTAX: /tip (to current target) or /tip
			return INVALIDPARAMETERS;
		}

		// Need to tip more than zero credits. Prevent stealing with negative tips.
		if (amount <= 0) {
			StringIdChatParameter ptia("base_player", "prose_tip_invalid_amt"); // /TIP: invalid amount ("%DI").
			ptia.setDI(amount);
			creature->sendSystemMessage(ptia);
			return INVALIDPARAMETERS;
		}

		if (creature == targetPlayer) { // You can't use yourself as a target for /tip!
			creature->sendSystemMessage("@error_message:target_self_disallowed"); // You cannot target yourself with this command.
			return GENERALERROR;
		}

		if (isBank || !targetPlayer->isOnline()) // Default to bank tip if player is offline
			return performBankTip(creature, targetPlayer, amount);
		else
			return performTip(creature, targetPlayer, amount);
	}

};

#endif //TIPCOMMAND_H_