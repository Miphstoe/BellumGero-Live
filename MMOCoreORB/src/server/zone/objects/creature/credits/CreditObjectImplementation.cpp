#include "engine/engine.h"
#include "engine/log/Logger.h"

#include "server/zone/objects/creature/credits/CreditObject.h"
#include "server/zone/packets/DeltaMessage.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/credit/CreditManager.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/login/account/Account.h"
#include "server/login/account/GalaxyAccountInfo.h"

void CreditObjectImplementation::setCashCredits(int credits, bool notifyClient) {
	if (cashCredits == credits)
		return;

	E3_ASSERT(credits >= 0);

	cashCredits = credits;

	if (notifyClient) {
		Reference<CreatureObject*> creo = owner.get();
		if (creo == nullptr)
			return;

		DeltaMessage *msg = new DeltaMessage(creo->getObjectID(), 'CREO', 1);
		msg->startUpdate(0x01);
		msg->insertInt(cashCredits);
		msg->close();
		creo->sendMessage(msg);
	}
}

WeakReference<CreatureObject*> CreditObjectImplementation::getOwner() {
	return owner;
}

void CreditObjectImplementation::setOwner(CreatureObject* obj) {
	ownerObjectID = obj->getObjectID();
	owner = obj;
}

uint64 CreditObjectImplementation::getOwnerObjectID() const {
	return ownerObjectID;
}

// Helper method to get the account's galaxy info for shared bank
GalaxyAccountInfo* CreditObjectImplementation::getAccountGalaxyInfo() {
	Reference<CreatureObject*> creo = owner.get();
	if (creo == nullptr || !creo->isPlayerCreature())
		return nullptr;

	ManagedReference<PlayerObject*> playerObject = creo->getPlayerObject();
	if (playerObject == nullptr)
		return nullptr;

	ManagedReference<Account*> account = playerObject->getAccount();
	if (account == nullptr)
		return nullptr;

	// Get the galaxy name from the zone server
	auto zone = creo->getZone();
	if (zone == nullptr)
		return nullptr;

	auto zoneServer = zone->getZoneServer();
	if (zoneServer == nullptr)
		return nullptr;

	String galaxyName = zoneServer->getGalaxyName();

	return account->getGalaxyAccountInfo(galaxyName);
}

int CreditObjectImplementation::getBankCredits() const {
	// For NPCs and creatures without accounts, use the old system
	Reference<CreatureObject*> creo = owner.get();
	if (creo == nullptr || !creo->isPlayerCreature())
		return bankCredits;

	// For players, get bank credits from the account (shared across all characters)
	GalaxyAccountInfo* galaxyInfo = const_cast<CreditObjectImplementation*>(this)->getAccountGalaxyInfo();
	if (galaxyInfo == nullptr) {
		// Fallback to character-specific bank if account info unavailable
		return bankCredits;
	}

	return galaxyInfo->getBankCredits();
}

void CreditObjectImplementation::setBankCredits(int credits, bool notifyClient) {
	E3_ASSERT(credits >= 0);

	// For players, set the account's shared bank
	GalaxyAccountInfo* galaxyInfo = getAccountGalaxyInfo();
	if (galaxyInfo != nullptr) {
		int currentBankCredits = galaxyInfo->getBankCredits();
		if (currentBankCredits == credits)
			return;

		galaxyInfo->setBankCredits(credits);
	} else {
		// For NPCs or if account unavailable, use character-specific bank
		if (bankCredits == credits)
			return;

		bankCredits = credits;
	}

	if (notifyClient) {
		Reference<CreatureObject*> creo = owner.get();
		if (creo == nullptr)
			return;

		DeltaMessage *msg = new DeltaMessage(creo->getObjectID(), 'CREO', 1);
		msg->startUpdate(0x00);
		msg->insertInt(credits);
		msg->close();
		creo->sendMessage(msg);
	}
}

void CreditObjectImplementation::transferCredits(int cash, int bank, bool notifyClient) {
	if (cash < 0 || bank < 0 || cash > CreditObject::CREDITCAP || bank > CreditObject::CREDITCAP) {
		error() << "ERROR: invalid call to transferCredits(cash=" << cash << ", bank=" << bank << "), current: " << *this;
		return;
	}

	int currentBankCredits = getBankCredits();

	if ((uint32) cashCredits + (uint32) currentBankCredits != (uint32) cash + (uint32) bank) {
		error() << "WARNING: unbalanced call to transferCredits(cash=" << cash << ", bank=" << bank << "), current: " << *this;
		return;
	}

	setCashCredits(cash, notifyClient);
	setBankCredits(bank, notifyClient);
}

void CreditObjectImplementation::subtractBankCredits(int credits, bool notifyClient) {
	if (credits < 0) {
		error() << "WARNING: Negative subtractBankCredits(credits=" << credits << "), current: " << *this;
		return;
	}

	int currentBankCredits = getBankCredits();

	if (credits > currentBankCredits) {
		error() << "WARNING: Overdraft subtractBankCredits(credits=" << credits << "), current: " << *this;
		credits -= currentBankCredits;
		clearBankCredits(notifyClient);

		if (credits > cashCredits) {
			clearCashCredits(notifyClient);
			error() << "WARNING: Player is now bankrupt, current: " << *this;
		} else {
			subtractCashCredits(credits, notifyClient);
		}

		return;
	}

	setBankCredits(currentBankCredits - credits, notifyClient);
}

void CreditObjectImplementation::subtractCashCredits(int credits, bool notifyClient) {
	if (credits < 0) {
		error() << "WARNING: Negative subtractCashCredits(credits=" << credits << "), current: " << *this;
		return;
	}

	if (credits > cashCredits) {
		error() << "WARNING: Overdraft subtractCashCredits(credits=" << credits << "), current: " << *this;
		credits -= cashCredits;
		clearCashCredits(notifyClient);

		if (credits > bankCredits) {
			clearBankCredits(notifyClient);
			error() << "WARNING: Player is now bankrupt, current: " << *this;
		} else {
			subtractBankCredits(credits, notifyClient);
		}

		return;
	}

	setCashCredits(cashCredits - credits, notifyClient);
}

bool CreditObjectImplementation::subtractCredits(int credits, bool notifyClient, bool bankFirst) {
	if (credits < 0) {
		error() << "WARNING: Negative subtractCredits(credits=" << credits << "), current: " << *this;
		return false;
	}

	int currentBankCredits = getBankCredits();

	if (credits > cashCredits + currentBankCredits) {
		return false;
	}

	if (bankFirst) {
		if (currentBankCredits > credits) {
			subtractBankCredits(credits, notifyClient);
		} else {
			credits -= currentBankCredits;
			clearBankCredits(notifyClient);
			subtractCashCredits(credits, notifyClient);
		}
	} else {
		if (cashCredits > credits) {
			subtractCashCredits(credits, notifyClient);
		} else {
			credits -= cashCredits;
			clearCashCredits(notifyClient);
			subtractBankCredits(credits, notifyClient);
		}
	}

	return true;
}

void CreditObjectImplementation::addBankCredits(int credits, bool notifyClient) {
	if (credits < 0) {
		error() << "WARNING: Negative addBankCredits(credits=" << credits << "), current: " << *this;
		return;
	}

	int currentBankCredits = getBankCredits();
	uint64 newBalance = (uint64)currentBankCredits + (uint64)credits;

	if (newBalance > CreditObject::CREDITCAP) {
		error() << "WARNING: Overflow addBankCredits(credits=" << credits << "), current: " << *this;
		setBankCredits(CreditObject::CREDITCAP, notifyClient);
		newBalance -= CreditObject::CREDITCAP;

		if (newBalance + (uint64)cashCredits > CreditObject::CREDITCAP) {
			setCashCredits(CreditObject::CREDITCAP, notifyClient);
			error() << "WARNING: Player is at CREDITCAP both for Cash and Bank, current: " << *this;
		} else {
			addCashCredits(newBalance, notifyClient);
		}

		return;
	}

	setBankCredits(currentBankCredits + credits, notifyClient);
}

void CreditObjectImplementation::addCashCredits(int credits, bool notifyClient) {
	if (credits < 0) {
		error() << "WARNING: Negative addCashCredits(credits=" << credits << "), current: " << *this;
		return;
	}

	uint64 newBalance = (uint64)cashCredits + (uint64)credits;

	if (newBalance > CreditObject::CREDITCAP) {
		error() << "WARNING: Overflow addCashCredits(credits=" << credits << "), current: " << *this;
		setCashCredits(CreditObject::CREDITCAP, notifyClient);
		newBalance -= CreditObject::CREDITCAP;

		int currentBankCredits = getBankCredits();

		if (newBalance + (uint64)currentBankCredits > CreditObject::CREDITCAP) {
			setBankCredits(CreditObject::CREDITCAP, notifyClient);
			error() << "WARNING: Player is at CREDITCAP both for Cash and Bank, current: " << *this;
		} else {
			addBankCredits(newBalance, notifyClient);
		}

		return;
	}

	setCashCredits(cashCredits + credits, notifyClient);
}

void CreditObjectImplementation::notifyLoadFromDatabase() {
	ManagedObjectImplementation::notifyLoadFromDatabase();

	if (cashCredits < 0) {
		error() << "Fixing negative cashCredits on load, current: " << *this;
		cashCredits = 0;
	}

	int currentBankCredits = getBankCredits();
	if (currentBankCredits < 0) {
		error() << "Fixing negative bankCredits on load, current: " << *this;
		setBankCredits(0, false);
	}

	// For players, migrate old character-specific bank to account bank if needed
	if (bankCredits > 0) {
		GalaxyAccountInfo* galaxyInfo = getAccountGalaxyInfo();
		if (galaxyInfo != nullptr && galaxyInfo->getBankCredits() == 0) {
			info() << "Migrating character-specific bank credits (" << bankCredits << ") to account-wide bank for objectID: " << ownerObjectID;
			galaxyInfo->setBankCredits(bankCredits);
			bankCredits = 0; // Clear the old character-specific bank
		}
	}
}

LoggerHelper CreditObjectImplementation::error() const {
	StackTrace::printStackTrace();

	auto creo = owner.get();

	return creo == nullptr ? CreditManager::instance()->error() : creo->error();
}

LoggerHelper CreditObjectImplementation::info(int forced) const {
	auto creo = owner.get();

	return creo == nullptr ? CreditManager::instance()->info(forced) : creo->info(forced);
}

LoggerHelper CreditObjectImplementation::debug() const {
	auto creo = owner.get();

	return creo == nullptr ? CreditManager::instance()->debug() : creo->debug();
}

String CreditObjectImplementation::toStringData() const {
	JSONSerializationType jsonData;
	jsonData["ownerObjectID"] = getOwnerObjectID();
	jsonData["bankCredits"] = getBankCredits();
	jsonData["cashCredits"] = cashCredits;
	jsonData["objectID"] = _this.getReferenceUnsafeStaticCast()->_getObjectID();
	return jsonData.dump();
}
