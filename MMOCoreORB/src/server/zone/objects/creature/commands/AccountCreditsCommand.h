/*
 * Bellum Gero — /accountcredits
 * Reports cash + bank credits across every active character on the
 * executing player's own account (including offline characters on the
 * same galaxy). Informational only; never modifies any balance.
 */

#ifndef ACCOUNTCREDITSCOMMAND_H_
#define ACCOUNTCREDITSCOMMAND_H_

#include "server/zone/objects/creature/commands/QueueCommand.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/managers/credit/CreditManager.h"
#include "server/login/account/Account.h"
#include "server/login/objects/CharacterList.h"
#include "server/login/objects/CharacterListEntry.h"

#include <vector>
#include <algorithm>

class AccountCreditsCommand : public QueueCommand {
	struct CharacterCreditRow {
		String name;
		bool available;
		int64 cash;
		int64 bank;
	};

public:
	AccountCreditsCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {
		setCooldown(10000); // 10 seconds
		setCooldownString("You must wait before checking your account credits again.");
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (creature == nullptr || !creature->isPlayerCreature())
			return GENERALERROR;

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (!checkCooldown(creature))
			return GENERALERROR;

		PlayerObject* ghost = creature->getPlayerObject();

		if (ghost == nullptr) {
			error() << "AccountCreditsCommand: creature " << creature->getObjectID() << " has no PlayerObject ghost";
			creature->sendSystemMessage("Your account credit information could not be retrieved at this time.");
			return GENERALERROR;
		}

		Reference<Account*> account = ghost->getAccount();

		if (account == nullptr) {
			error() << "AccountCreditsCommand: failed to resolve account for creature " << creature->getObjectID();
			creature->sendSystemMessage("Your account credit information could not be retrieved at this time.");
			return GENERALERROR;
		}

		Reference<CharacterList*> characterList;

		try {
			Locker accLocker(account);
			characterList = account->getCharacterList();
		} catch (const Exception& e) {
			error() << "AccountCreditsCommand: exception retrieving character list: " << e.getMessage();
			characterList = nullptr;
		}

		if (characterList == nullptr) {
			error() << "AccountCreditsCommand: null character list for account " << account->getAccountID();
			creature->sendSystemMessage("Your account credit information could not be retrieved at this time.");
			return GENERALERROR;
		}

		uint32 currentGalaxyID = server->getZoneServer()->getGalaxyID();

		std::vector<CharacterCreditRow> rows;
		SortedVector<uint64> seenObjectIDs;

		for (int i = 0; i < characterList->size(); ++i) {
			CharacterListEntry* entry = &characterList->get(i);

			if (entry == nullptr)
				continue;

			// Only same-galaxy characters: credit data for other galaxies
			// lives in a different server's object database and is not
			// reachable from here.
			if (entry->getGalaxyID() != currentGalaxyID)
				continue;

			uint64 charOID = entry->getObjectID();

			if (charOID == 0) {
				error() << "AccountCreditsCommand: invalid (zero) character object id on account " << account->getAccountID();
				continue;
			}

			if (seenObjectIDs.contains(charOID))
				continue;

			seenObjectIDs.put(charOID);

			CharacterCreditRow row;
			row.name = entry->getFullName();

			if (row.name.isEmpty())
				row.name = "Unknown Character";

			Reference<CreditObject*> creditObj;

			try {
				creditObj = CreditManager::getCreditObject(charOID);
			} catch (const Exception& e) {
				error() << "AccountCreditsCommand: exception loading credit data for character " << charOID << ": " << e.getMessage();
				creditObj = nullptr;
			}

			if (creditObj == nullptr) {
				error() << "AccountCreditsCommand: could not load credit data for character " << charOID << " on account " << account->getAccountID();
				row.available = false;
				row.cash = 0;
				row.bank = 0;
			} else {
				row.available = true;
				row.cash = (int64) creditObj->getCashCredits();
				row.bank = (int64) creditObj->getBankCredits();
			}

			rows.push_back(row);
		}

		if (rows.empty()) {
			creature->sendSystemMessage("No active characters were found for your account.");
			return SUCCESS;
		}

		std::sort(rows.begin(), rows.end(), [](const CharacterCreditRow& a, const CharacterCreditRow& b) {
			return a.name.compareTo(b.name) < 0;
		});

		int64 totalCash = 0;
		int64 totalBank = 0;
		bool anyAvailable = false;

		StringBuffer body;
		body << "Credits held across your Bellum Gero account" << endl << endl;

		for (const CharacterCreditRow& row : rows) {
			body << row.name << endl;

			if (!row.available) {
				body << "Balance unavailable" << endl << endl;
				continue;
			}

			anyAvailable = true;

			int64 charTotal = row.cash + row.bank;

			totalCash += row.cash;
			totalBank += row.bank;

			body << "Cash: " << formatCredits(row.cash) << endl;
			body << "Bank: " << formatCredits(row.bank) << endl;
			body << "Total: " << formatCredits(charTotal) << endl << endl;
		}

		int64 accountTotal = totalCash + totalBank;

		body << "Account Summary" << endl << endl;
		body << "Cash Total: " << formatCredits(totalCash) << endl;
		body << "Bank Total: " << formatCredits(totalBank) << endl;
		body << "Account Total: " << formatCredits(accountTotal) << " credits" << endl;

		if (!anyAvailable) {
			error() << "AccountCreditsCommand: no character credit data could be read for account " << account->getAccountID();
		}

		ManagedReference<SuiMessageBox*> box = new SuiMessageBox(creature, 0);
		box->setPromptTitle("Account Credit Report");
		box->setPromptText(body.toString());
		box->setOkButton(true, "@ok");
		box->setUsingObject(creature);

		creature->sendMessage(box->generateMessage());

		creature->sendSystemMessage("Account credit report generated.");

		return SUCCESS;
	}

private:
	static String formatCredits(int64 value) {
		bool negative = value < 0;
		uint64 absValue = negative ? (uint64) (-value) : (uint64) value;

		String digits = String::valueOf(absValue);

		StringBuffer result;
		int len = digits.length();

		for (int i = 0; i < len; ++i) {
			if (i > 0 && (len - i) % 3 == 0)
				result << ",";

			result << digits.charAt(i);
		}

		if (negative)
			return "-" + result.toString();

		return result.toString();
	}
};

#endif /* ACCOUNTCREDITSCOMMAND_H_ */
