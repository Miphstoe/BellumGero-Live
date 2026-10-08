/*
 * CharacterRenameManager.cpp
 *
 * Bellum Gero - paid Character Name Change Service. See header for design notes.
 */

#include "CharacterRenameManager.h"

#include "server/zone/ZoneServer.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/managers/name/NameManager.h"
#include "server/zone/managers/auction/AuctionManager.h"
#include "server/zone/managers/auction/AuctionsMap.h"
#include "server/chat/ChatManager.h"
#include "server/db/ServerDatabase.h"
#include "server/zone/objects/transaction/TransactionLog.h"

#include <cctype>

CharacterRenameManager::CharacterRenameManager() {
	setLoggingName("CharacterRenameManager");
	setFileLogger("log/character_rename.log", true, false);
	setLogSynchronized(true);
	setLogToConsole(false);
	setGlobalLogging(true);
	setLogging(true);
}

String CharacterRenameManager::checkEligibility(CreatureObject* player) {
	if (player == nullptr || !player->isPlayerCreature())
		return "Only player characters can use this service.";

	PlayerObject* ghost = player->getPlayerObject();

	if (ghost == nullptr)
		return "Your character data is unavailable right now.";

	ZoneServer* zoneServer = player->getZoneServer();

	if (zoneServer == nullptr || zoneServer->isServerShuttingDown())
		return "Name changes are unavailable while the server is shutting down.";

	if (!player->isOnline() || ghost->isLoggingOut() || ghost->isLinkDead())
		return "You cannot change your name while logging out.";

	if (ghost->isOnLoadScreen() || player->getZone() == nullptr)
		return "You cannot change your name while traveling.";

	if (player->isDead() || player->isIncapacitated())
		return "You cannot change your name while dead or incapacitated.";

	if (player->isInCombat())
		return "You cannot change your name while in combat.";

	return "";
}

// Trims whitespace and enforces A-Z, a-z, ' and - only, starting and ending with a letter,
// with no two special characters in a row. Capitalization is normalized to "Name",
// with a capital after ' or - ("O'Brien", "Jo-Anne"). Per-species length and
// special-character limits are enforced afterwards by NameManager::validateName.
bool CharacterRenameManager::normalizeComponent(const String& raw, String& out) {
	String value = raw.trim();
	out = "";

	if (value.isEmpty())
		return true;

	bool previousSpecial = true; // forces the first character to be a letter

	for (int i = 0; i < value.length(); ++i) {
		char ch = value.charAt(i);
		bool isLetter = (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z');

		if (isLetter) {
			if (previousSpecial)
				out += (char)toupper(ch);
			else
				out += (char)tolower(ch);

			previousSpecial = false;
		} else if (ch == '\'' || ch == '-') {
			if (previousSpecial)
				return false;

			out += ch;
			previousSpecial = true;
		} else {
			return false; // spaces, digits, punctuation, non-ASCII
		}
	}

	return !previousSpecial; // may not end with ' or -
}

bool CharacterRenameManager::isFirstNameTakenInDatabase(const String& firstName, uint64 playerID, int galaxyID) {
	String lowerName = firstName.toLowerCase();
	Database::escapeString(lowerName);

	StringBuffer query;
	query << "SELECT `character_oid` FROM `characters` WHERE lower(`firstname`) = '" << lowerName
			<< "' AND `galaxy_id` = " << galaxyID;

	// Throws DatabaseException on failure; callers treat that as a failed (uncharged) request
	UniqueReference<ResultSet*> res(ServerDatabase::instance()->executeQuery(query.toString()));

	while (res->next()) {
		if (res->getUnsignedLong(0) != playerID)
			return true;
	}

	return false;
}

CharacterRenameManager::RenameResult CharacterRenameManager::validate(CreatureObject* player, const String& rawFirstName, const String& rawLastName,
		String& firstName, String& lastName, bool checkDatabase) {
	RenameResult result;

	String reason = checkEligibility(player);

	if (!reason.isEmpty()) {
		result.code = RESULT_UNSAFE_STATE;
		result.message = reason;
		return result;
	}

	if (rawFirstName.trim().isEmpty()) {
		result.code = RESULT_INVALID;
		result.message = "A first name is required.";
		return result;
	}

	if (!normalizeComponent(rawFirstName, firstName) || !normalizeComponent(rawLastName, lastName)) {
		result.code = RESULT_INVALID;
		result.message = "That name does not meet the server's naming requirements. Names may only contain letters, with at most one ' or - inside the name, and no spaces.";
		return result;
	}

	String fullName = firstName;

	if (!lastName.isEmpty())
		fullName = firstName + " " + lastName;

	result.fullName = fullName;

	ZoneServer* zoneServer = player->getZoneServer();
	NameManager* nameManager = zoneServer->getNameManager();

	int nameResult = nameManager->validateName(fullName, player->getSpecies());

	if (nameResult != NameManagerResult::ACCEPTED) {
		String detail;

		switch (nameResult) {
		case NameManagerResult::DECLINED_RACE_INAPP: detail = "The length or characters are not allowed for your species."; break;
		case NameManagerResult::DECLINED_PROFANE: detail = "That name is not permitted."; break;
		case NameManagerResult::DECLINED_DEVELOPER: detail = "That name is reserved for staff."; break;
		case NameManagerResult::DECLINED_FICT_RESERVED: detail = "That name is reserved."; break;
		case NameManagerResult::DECLINED_RESERVED: detail = "That name is reserved."; break;
		case NameManagerResult::DECLINED_SYNTAX: detail = "That name contains invalid syntax."; break;
		default: detail = "That name was declined."; break;
		}

		result.code = RESULT_INVALID;
		result.message = "That name does not meet the server's naming requirements. " + detail;
		return result;
	}

	if (fullName == player->getCustomObjectName().toString()) {
		result.code = RESULT_SAME_NAME;
		result.message = "That is already your character's name.";
		return result;
	}

	// First names are the unique key (case-insensitive) for SWG characters
	uint64 existingID = zoneServer->getPlayerManager()->getObjectID(firstName);

	if (existingID != 0 && existingID != player->getObjectID()) {
		result.code = RESULT_UNAVAILABLE;
		result.message = "That character name is already in use. Please choose another name.";
		return result;
	}

	if (checkDatabase) {
		try {
			if (isFirstNameTakenInDatabase(firstName, player->getObjectID(), zoneServer->getGalaxyID())) {
				result.code = RESULT_UNAVAILABLE;
				result.message = "That character name is already in use. Please choose another name.";
				return result;
			}
		} catch (const Exception& e) {
			error("database availability check failed for " + String::valueOf(player->getObjectID()) + ": " + e.getMessage());

			result.code = RESULT_FAILED;
			result.message = "Your name change could not be completed. No credits have been charged. Please try again later.";
			return result;
		}
	}

	if (!player->verifyBankCredits(SERVICE_FEE)) {
		result.code = RESULT_INSUFFICIENT_FUNDS;
		result.message = "You need 1,000,000 credits in your bank account to use this service.";
		return result;
	}

	result.code = RESULT_SUCCESS;
	return result;
}

CharacterRenameManager::RenameResult CharacterRenameManager::checkRename(CreatureObject* player, const String& rawFirstName, const String& rawLastName) {
	if (player == nullptr) {
		RenameResult result;
		result.message = "Your name change could not be completed. No credits have been charged. Please try again later.";
		return result;
	}

	Locker locker(player);

	String firstName, lastName;

	return validate(player, rawFirstName, rawLastName, firstName, lastName, false);
}

CharacterRenameManager::RenameResult CharacterRenameManager::purchaseRename(CreatureObject* player, const String& rawFirstName, const String& rawLastName) {
	RenameResult result;
	result.message = "Your name change could not be completed. No credits have been charged. Please try again later.";

	if (player == nullptr)
		return result;

	ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

	if (ghost == nullptr)
		return result;

	Locker locker(player);
	Locker glocker(ghost.get(), player);

	// One rename at a time server-wide: closes the check-then-claim window between
	// two players requesting the same name, and between duplicate confirmations.
	Locker renameLocker(&renameMutex);

	const String oldFullName = player->getCustomObjectName().toString();
	const String oldFirstName = player->getFirstName();

	String firstName, lastName;

	result = validate(player, rawFirstName, rawLastName, firstName, lastName, true);

	if (result.code != RESULT_SUCCESS) {
		audit(player, "REJECTED", oldFullName, result.fullName.isEmpty() ? rawFirstName + " " + rawLastName : result.fullName, 0, result.message);
		return result;
	}

	const String newFullName = result.fullName;
	const uint64 playerID = player->getObjectID();

	ZoneServer* zoneServer = player->getZoneServer();
	PlayerManager* playerManager = zoneServer->getPlayerManager();
	ChatManager* chatManager = zoneServer->getChatManager();

	audit(player, "STARTED", oldFullName, newFullName, SERVICE_FEE, "");

	// Atomic claim in the name index; fails if someone else holds the first name
	if (!playerManager->renamePlayerIndex(playerID, oldFirstName, firstName)) {
		result.code = RESULT_UNAVAILABLE;
		result.message = "That character name is already in use. Please choose another name.";
		audit(player, "REJECTED", oldFullName, newFullName, 0, "name index claim failed");
		return result;
	}

	try {
		player->setCustomObjectName(newFullName, true);

		// If staff fix their staff tags
		if (ghost->hasGodMode())
			playerManager->updatePermissionName(player, ghost->getAdminLevel());

		chatManager->removePlayer(oldFirstName);
		chatManager->addPlayer(player);
	} catch (const Exception& e) {
		// Roll back the in-memory rename; nothing has been charged yet
		player->setCustomObjectName(oldFullName, true);
		playerManager->renamePlayerIndex(playerID, firstName, oldFirstName);
		chatManager->removePlayer(firstName);
		chatManager->addPlayer(player);

		result.code = RESULT_FAILED;
		result.message = "Your name change could not be completed. No credits have been charged. Please try again later.";
		audit(player, "FAILED_ROLLED_BACK", oldFullName, newFullName, 0, e.getMessage());
		return result;
	}

	// Charge exactly once, under the same lock as the rename. validate() already
	// verified the balance and nothing above releases the lock.
	{
		TransactionLog trx(player, TrxCode::CUSTOMERSERVICE, SERVICE_FEE, false);
		trx.addState("bgService", "characterNameChange");
		trx.addState("oldName", oldFullName);
		trx.addState("newName", newFullName);

		player->subtractBankCredits(SERVICE_FEE);
	}

	audit(player, "CHARGED", oldFullName, newFullName, SERVICE_FEE, "");

	bool firstNameChanged = oldFirstName.toLowerCase() != firstName.toLowerCase();

	// Keep other players' friend lists pointing at this character
	if (firstNameChanged)
		ghost->transferReverseFriends(oldFirstName, firstName);

	updateCharacterTables(playerID, zoneServer->getGalaxyID(), firstName, lastName);

	// Bazaar/vendor listings and active bids store names for mail, search and bid refunds
	if (oldFirstName != firstName) {
		ManagedReference<AuctionManager*> auctionManager = zoneServer->getAuctionManager();

		if (auctionManager != nullptr) {
			Core::getTaskManager()->executeTask([auctionManager, playerID, oldFirstName, firstName, this] () {
				ManagedReference<AuctionsMap*> auctionsMap = auctionManager->getAuctionMap();

				if (auctionsMap == nullptr)
					return;

				int updated = auctionsMap->updatePlayerName(playerID, oldFirstName, firstName);

				StringBuffer msg;
				msg << "status=AUCTIONS_UPDATED oid=" << playerID << " old='" << oldFirstName << "' new='" << firstName << "' items=" << updated;
				info(msg.toString(), true);
			}, "BgRenameAuctionUpdate");
		}
	}

	audit(player, "SUCCESS", oldFullName, newFullName, SERVICE_FEE, "");

	result.code = RESULT_SUCCESS;
	result.message = "Your character name has been successfully changed to " + newFullName + ". A fee of 1,000,000 credits has been deducted from your bank account.";

	return result;
}

void CharacterRenameManager::reconcileNameIndex(CreatureObject* player) {
	if (player == nullptr || !player->isPlayerCreature())
		return;

	ZoneServer* zoneServer = player->getZoneServer();

	if (zoneServer == nullptr)
		return;

	PlayerManager* playerManager = zoneServer->getPlayerManager();
	const uint64 playerID = player->getObjectID();

	String indexedName = playerManager->getPlayerName(playerID);
	String actualFirstName = player->getFirstName();

	if (indexedName.isEmpty() || actualFirstName.isEmpty() || indexedName == actualFirstName.toLowerCase())
		return;

	// The object database (name + credits) is authoritative; the index and MySQL follow it
	Locker renameLocker(&renameMutex);

	if (!playerManager->renamePlayerIndex(playerID, indexedName, actualFirstName)) {
		StringBuffer msg;
		msg << "status=RECONCILE_CONFLICT oid=" << playerID << " indexed='" << indexedName << "' actual='" << actualFirstName << "' - name claimed by another character, manual review required";
		error(msg.toString());
		return;
	}

	updateCharacterTables(playerID, zoneServer->getGalaxyID(), actualFirstName, player->getLastName());

	audit(player, "RECONCILED", indexedName, player->getCustomObjectName().toString(), 0, "name index/MySQL did not match object database at login");
}

void CharacterRenameManager::updateCharacterTables(uint64 playerID, int galaxyID, const String& firstName, const String& lastName) {
	String escapedFirst = firstName;
	String escapedLast = lastName;
	Database::escapeString(escapedFirst);
	Database::escapeString(escapedLast);

	const char* tables[] = { "characters_dirty", "characters" };

	for (const char* table : tables) {
		StringBuffer query;
		query << "UPDATE `" << table << "` SET `firstname` = '" << escapedFirst << "', `surname` = '" << escapedLast
				<< "' WHERE `character_oid` = '" << playerID << "' AND `galaxy_id` = '" << galaxyID << "'";

		ServerDatabase::instance()->executeStatement(query);
	}
}

// Player-typed text: strip line breaks/quotes and cap length so audit lines stay one parseable line
static String sanitizeForLog(const String& value) {
	String clean = value.replaceAll("\n", " ").replaceAll("\r", " ").replaceAll("'", "`");

	if (clean.length() > 200)
		clean = clean.subString(0, 200) + "...";

	return clean;
}

void CharacterRenameManager::audit(CreatureObject* player, const String& status, const String& oldName, const String& newName, int fee, const String& reason) {
	uint32 accountID = 0;

	if (player != nullptr) {
		PlayerObject* ghost = player->getPlayerObject();

		if (ghost != nullptr)
			accountID = ghost->getAccountID();
	}

	StringBuffer msg;

	msg << "status=" << status
		<< " oid=" << (player != nullptr ? player->getObjectID() : 0)
		<< " account=" << accountID
		<< " old='" << sanitizeForLog(oldName) << "'"
		<< " new='" << sanitizeForLog(newName) << "'"
		<< " fee=" << fee;

	if (!reason.isEmpty())
		msg << " reason='" << sanitizeForLog(reason) << "'";

	info(msg.toString(), true);
}
