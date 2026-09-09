/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef DATABASECOMMAND_H_
#define DATABASECOMMAND_H_

#include "engine/engine.h"

#include "QueueCommand.h"
#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "conf/ConfigManager.h"

class DatabaseCommand : public QueueCommand {
public:

	DatabaseCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		UnicodeTokenizer tokenizer(arguments);
		tokenizer.setDelimeter(" ");

		String arg0, arg1;
		uint64 objectID;

		if (!tokenizer.hasMoreTokens())
			return INVALIDPARAMETERS;

		tokenizer.getStringToken(arg0);

		try {
			if (arg0 == "zerostructures") {
				String summary = StructureManager::instance()->validatePlayerStructureZoneIndex(true, true);
				creature->sendSystemMessage("Player structure zone validation complete. Details were written to the server log.");
				creature->sendSystemMessage(summary);

				return SUCCESS;
			}

			// BELLUM_GERO_STRUCTURE_INTEGRITY_BUILD1
			if (arg0 == "structureinfo") {
				ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

				if (ghost == nullptr || ghost->getAdminLevel() < 15 || !ghost->hasAbility("admin")) {
					creature->sendSystemMessage("structureinfo requires Admin Level 15 and the admin ability.");
					return GENERALERROR;
				}

				if (!tokenizer.hasMoreTokens()) {
					creature->sendSystemMessage("Usage: /database structureinfo <structureOID>");
					return INVALIDPARAMETERS;
				}

				objectID = tokenizer.getLongToken();
				creature->sendSystemMessage(StructureManager::instance()->getPlayerStructureIntegrityInfo(objectID));
				return SUCCESS;
			}

			// BELLUM_GERO_STRUCTURE_INTEGRITY_BUILD2
			// BELLUM_GERO_STRUCTURE_INTEGRITY_BUILD31_WORLDREMOVE
			if (arg0 == "structureworldremove") {
				if (!tokenizer.hasMoreTokens()) {
					creature->sendSystemMessage(
						"SYNTAX: /database structureworldremove <OID>");
					return INVALIDPARAMETERS;
				}

				uint64 objectID = tokenizer.getLongToken();

				if (objectID == 0) {
					creature->sendSystemMessage(
						"Invalid OID for structureworldremove.");
					return INVALIDPARAMETERS;
				}

				String result;
				bool removed = StructureManager::instance()->
					removePlayerStructureFromWorldForIntegrityTest(objectID, result);

				creature->sendSystemMessage(result);
				return removed ? SUCCESS : GENERALERROR;
			}

			if (arg0 == "structurerepair") {
				ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

				if (ghost == nullptr || ghost->getAdminLevel() < 15 || !ghost->hasAbility("admin")) {
					creature->sendSystemMessage("structurerepair requires Admin Level 15 and the admin ability.");
					return GENERALERROR;
				}

				if (!tokenizer.hasMoreTokens()) {
					creature->sendSystemMessage("Usage: /database structurerepair <structureOID>");
					return INVALIDPARAMETERS;
				}

				objectID = tokenizer.getLongToken();

				String result;
				// BELLUM_GERO_STRUCTURE_INTEGRITY_BUILD21
				bool queued = StructureManager::instance()->
					queuePlayerStructureZoneRepairFromWaypoint(objectID, result);

				creature->sendSystemMessage(result);
				return queued ? SUCCESS : GENERALERROR;
			}

			if (arg0 == "structurecorrupt") {
				ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

				if (ghost == nullptr || ghost->getAdminLevel() < 15 || !ghost->hasAbility("admin")) {
					creature->sendSystemMessage("structurecorrupt requires Admin Level 15 and the admin ability.");
					return GENERALERROR;
				}

				if (!ConfigManager::instance()->getBool("Core3.StructureIntegrity.EnableTestCorruption", false)) {
					creature->sendSystemMessage("Test corruption is disabled. This command is Test Center only.");
					return GENERALERROR;
				}

				if (!tokenizer.hasMoreTokens()) {
					creature->sendSystemMessage("Usage: /database structurecorrupt <structureOID> zone");
					return INVALIDPARAMETERS;
				}

				objectID = tokenizer.getLongToken();

				if (!tokenizer.hasMoreTokens()) {
					creature->sendSystemMessage("Usage: /database structurecorrupt <structureOID> zone");
					return INVALIDPARAMETERS;
				}

				String corruptionType;
				tokenizer.getStringToken(corruptionType);
				if (corruptionType != "zone") {
					creature->sendSystemMessage("Build 1 only supports: /database structurecorrupt <structureOID> zone");
					return INVALIDPARAMETERS;
				}

				String result;
				bool queued = StructureManager::instance()->queuePlayerStructureZoneCorruptionForTest(objectID, result);
				creature->sendSystemMessage(result);
				return queued ? SUCCESS : GENERALERROR;
			}

			if (!tokenizer.hasMoreTokens())
				return INVALIDPARAMETERS;

			objectID = tokenizer.getLongToken();

		} catch (const Exception& err) {
			creature->sendSystemMessage("Error parsing objectID: " +  err.getMessage());
			return INVALIDPARAMETERS;
		}

		String strResource;

		if (!(arg0 == "cityregions" || arg0 == "factionstructures" || arg0 == "playerstructures" || arg0 == "sceneobjects" || arg0 == "clientobjects" || arg0 == "resourcespawns" ||
				arg0 == "characters" || arg0 == "deleted_characters") ){
			creature->sendSystemMessage("Command format: database <playerstructures | cityregions | sceneobjects | clientobjects> <objectid>, database zerostructures, database structureinfo <OID>, database structurerepair <OID>, or database structurecorrupt <OID> zone");

			return INVALIDPARAMETERS;
		}

		try {
			if (arg0 == "characters" || arg0 == "deleted_characters" ) {
				doSQLQuery(creature, arg0, objectID);
			} else {
				doObjectDBQuery(creature, arg0, objectID);
			}
		} catch (const  Exception& err) {
			creature->sendSystemMessage("Error in database lookup: " + err.getMessage());
			error() << err.getMessage();
		}

		return SUCCESS;
	}


private:
	void doObjectDBQuery(CreatureObject* creature, String db, uint64 objectID) const {
		StringBuffer msg;

		debug() << "doing object query for " << db << " with object " << objectID;

		try {
			ObjectDatabaseManager* dManager = ObjectDatabaseManager::instance();
			uint16 id = ObjectDatabaseManager::instance()->getDatabaseID(db);

			if (id == 0) {
				creature->sendSystemMessage("invalid db");
				return;
			}

			ObjectDatabase* thisDatabase = cast<ObjectDatabase*>(ObjectDatabaseManager::instance()->getDatabase(id));

			if(thisDatabase == nullptr || !thisDatabase->isObjectDatabase()) {
				creature->sendSystemMessage("Error retrieving " + db + " database.");
				return;
			}

			ObjectInputStream objectData(2000);

			if (!(thisDatabase->getData(objectID,&objectData))) {
				uint32 serverObjectCRC;
				String className;

				if (Serializable::getVariable<String>(STRING_HASHCODE("_className"), &className, &objectData)) {
					msg << endl << "OID: " + String::valueOf(objectID) << endl;
					msg << "Database: " << db << endl;
					msg << "ClassName: " << className << endl;

					creature->sendSystemMessage(msg.toString());
				} else {
					msg << "ERROR desrializing from db" << endl;
				}

			} else {
				creature->sendSystemMessage("Object " + String::valueOf(objectID) + " was not found in " + db + " database.");
			}
		} catch (const DatabaseException& err) {
			msg << endl << err.getMessage();
		} catch (const Exception& err){
			msg << endl << err.getMessage();
		}

		creature->sendSystemMessage(msg.toString());
	}

	void doSQLQuery(CreatureObject* creature, String db, uint64 objectID) const {
		StringBuffer selectStatement;
		StringBuffer msg;

		try {
			selectStatement << "SELECT * FROM " << db << " WHERE character_oid = " << objectID;
			UniqueReference<ResultSet*> queryResults(ServerDatabase::instance()->executeQuery(selectStatement));

			if (queryResults == nullptr || queryResults.get()->getRowsAffected() == 0){
				msg << endl << "No results for " << selectStatement.toString();
			} else if ( queryResults->getRowsAffected() > 1) {
				msg << endl << "Duplicate character id.";
			} else {
				while (queryResults->next()) {
					msg << endl << "Found in the database";

					uint64 newOID = queryResults->getUnsignedLong(0);

					msg << "oid " << String::valueOf(newOID) << endl;
					msg << "account id: " << String::valueOf(queryResults->getUnsignedInt(1)) << endl;
					msg << "galaxy id " << String::valueOf(queryResults->getUnsignedInt(2)) << endl;

					if (db == "characters")
						msg << "Name: " << queryResults->getString(3) << " " << queryResults->getString(4) << endl;

					if (db == "deleted_characters")
						msg << "db_deleted: " <<  String::valueOf(queryResults->getInt(9)) << endl;
				}
			}
		} catch (const DatabaseException& err) {
			msg << endl << err.getMessage();
		} catch (const Exception& err) {
			msg << endl << err.getMessage();
		}

		creature->sendSystemMessage(msg.toString());
	}
};

#endif //DATABASECOMMAND_H_
