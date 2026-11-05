/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef SETPERMISSIONCOMMAND_H_
#define SETPERMISSIONCOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/login/account/AccountManager.h"
#include "server/login/account/Account.h"
#include "server/login/objects/CharacterList.h"
#include "server/login/objects/CharacterListEntry.h"

class SetpermissionCommand : public QueueCommand {
public:
	SetpermissionCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (!creature->checkCooldownRecovery("set_permission")) {
			creature->sendSystemMessage("@healing_response:healing_must_wait"); //You must wait before you can do that.
			return GENERALERROR;
		}

		creature->updateCooldownTimer("set_permission", defaultTime * 1000);

		ManagedReference<PlayerManager*> playerManager = server->getPlayerManager();

		if (playerManager == nullptr)
			return GENERALERROR;

		uint64 targetid = creature->getTargetID();
		ManagedReference<SceneObject*> obj = playerManager->getInRangeStructureWithAdminRights(creature, targetid);

		if (obj == nullptr || !obj->isStructureObject()) {
			creature->sendSystemMessage("@player_structure:no_building"); // You must be in a building, be near an installation, or have one targeted to do that.
			return INVALIDTARGET;
		}

		StructureObject* structure = cast<StructureObject*>(obj.get());

		if (structure->isCivicStructure()) {
			creature->sendSystemMessage("You cannot modify permissions on civic structures.");
			return INVALIDTARGET;
		}

		if (structure->isGCWBase()) {
			return INVALIDTARGET;
		}

		String listName, targetName;

		try {
			UnicodeTokenizer tokenizer(arguments);
			tokenizer.getStringToken(listName);
			tokenizer.getStringToken(targetName);
		} catch (Exception& e) {
			creature->sendSystemMessage("@player_structure:format_setpermission_type_player"); // Format: /setPermission <type> <player>
			return INVALIDPARAMETERS;
		}

		// Bellum Gero: "/setpermission admin account <accountname>" bulk-edits the ADMIN list.
		// Only triggers on the exact "admin account" prefix followed by more arguments, so a plain
		// "/setpermission admin <player>" (even for a character named "Account") is unchanged.
		if (listName.toLowerCase() == "admin" && targetName.toLowerCase() == "account") {
			try {
				UnicodeTokenizer tokenizer(arguments);
				tokenizer.getStringToken(listName);
				tokenizer.getStringToken(targetName);

				if (tokenizer.hasMoreTokens()) {
					String accountName;
					tokenizer.getStringToken(accountName);

					if (tokenizer.hasMoreTokens()) {
						sendAccountUsage(creature);
						return INVALIDPARAMETERS;
					}

					return handleAccountAdmin(creature, structure, accountName);
				}
			} catch (Exception& e) {
				sendAccountUsage(creature);
				return INVALIDPARAMETERS;
			}
		}

		UnicodeString args = targetName + " " + listName + " toggle";
		creature->executeObjectControllerAction(0x896713F2, obj->getObjectID(), args); // PermissionListModify

		return SUCCESS;
	}

private:
	static void sendAccountUsage(CreatureObject* creature) {
		creature->sendSystemMessage("Usage:");
		creature->sendSystemMessage("/setpermission admin account <accountname>");
	}

	/**
	 * Adds every character on the named account (same galaxy, online or offline) to the
	 * structure's ADMIN list using the normal grantPermission API. One-time bulk operation on
	 * character IDs; nothing account-level is stored.
	 */
	int handleAccountAdmin(CreatureObject* creature, StructureObject* structure, const String& accountName) const {
		if (accountName.isEmpty() || accountName.length() > 40) {
			sendAccountUsage(creature);
			return INVALIDPARAMETERS;
		}

		ZoneServer* zoneServer = server->getZoneServer();

		if (zoneServer == nullptr)
			return GENERALERROR;

		// Looks up by username using the account system's own (escaped) query and collation
		Reference<Account*> account = AccountManager::getAccount(accountName, true);

		if (account == nullptr) {
			creature->sendSystemMessage("Account not found: " + accountName);
			return INVALIDPARAMETERS;
		}

		Reference<CharacterList*> characterList;

		{
			Locker accLocker(account);
			characterList = account->getCharacterList();
		}

		if (characterList == nullptr) {
			creature->sendSystemMessage("Account not found: " + accountName);
			return GENERALERROR;
		}

		Locker _lock(structure, creature);

		const String listName = "ADMIN";
		uint32 galaxyID = zoneServer->getGalaxyID();

		int found = 0, changed = 0, skipped = 0, failed = 0;
		SortedVector<uint64> seen;

		for (int i = 0; i < characterList->size(); ++i) {
			CharacterListEntry* entry = &characterList->get(i);

			if (entry == nullptr || entry->getGalaxyID() != galaxyID)
				continue;

			uint64 oid = entry->getObjectID();

			if (oid == 0 || seen.contains(oid))
				continue;

			seen.put(oid);
			found++;

			ManagedReference<CreatureObject*> target = zoneServer->getObject(oid).castTo<CreatureObject*>();

			// Only the OID is needed for the list; the object (if loadable) is just used to refresh cell permissions
			if (target != nullptr && !target->isPlayerCreature())
				target = nullptr;

			bool onList = structure->isOnPermissionList(listName, oid);

			if (onList) {
				skipped++;
				continue;
			}

			if (structure->isOnBanList(oid) || structure->isPermissionListFull(listName)) {
				structure->info() << "ADMIN ACCOUNT add skipped (banned or list full) oid " << oid << " (" << entry->getFullName() << ")";
				failed++;
				continue;
			}

			if (structure->grantPermission(listName, oid) == StructurePermissionList::GRANTED)
				changed++;
			else
				failed++;

			if (target != nullptr && structure->isBuildingObject()) {
				BuildingObject* building = cast<BuildingObject*>(structure);

				if (building != nullptr)
					building->updateCellPermissionsTo(target);
			}
		}

		structure->info() << "STRUCTURE ADMIN ACCOUNT " << "ADD"
			<< " StructureID: " << structure->getObjectID()
			<< " ByID: " << creature->getObjectID()
			<< " AccountID: " << account->getAccountID()
			<< " found=" << found << " changed=" << changed << " skipped=" << skipped << " failed=" << failed;

		if (found == 0) {
			creature->sendSystemMessage("No characters on this galaxy were found for account: " + accountName);
			return INVALIDPARAMETERS;
		}

		creature->sendSystemMessage("Account permissions updated successfully.");
		creature->sendSystemMessage("Account: " + accountName);
		creature->sendSystemMessage("Characters found: " + String::valueOf(found));
		creature->sendSystemMessage(String("Characters added: ") + String::valueOf(changed));
		creature->sendSystemMessage(String("Already administrators: ") + String::valueOf(skipped));
		creature->sendSystemMessage("Failed: " + String::valueOf(failed));

		return SUCCESS;
	}
};

#endif // SETPERMISSIONCOMMAND_H_
