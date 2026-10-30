/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef REQUESTSTATMIGRATIONDATACOMMAND_H_
#define REQUESTSTATMIGRATIONDATACOMMAND_H_

#include "server/zone/objects/player/sessions/MigrateStatsSession.h"
#include "server/zone/packets/player/StatMigrationTargetsMessage.h"
#include "server/zone/managers/player/creation/PlayerCreationManager.h"

class RequestStatMigrationDataCommand : public QueueCommand {
public:

	RequestStatMigrationDataCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		ManagedReference<Facade*> facade = creature->getActiveSession(SessionFacadeType::MIGRATESTATS);
		ManagedReference<MigrateStatsSession*> session = dynamic_cast<MigrateStatsSession*>(facade.get());

		// BG STATMIGRATION DEBUG (temporary, Species Change Token investigation -- remove once
		// resolved). This is the exact moment the client's "Points Remaining" baseline gets
		// established for a freshly-opened migration session: it seeds the session's targets from
		// creature->getBaseHAM() as-is (whatever it currently is) and reports 0 points remaining --
		// implicitly telling the client "your current baseHAM already sums to your species total".
		// If it does NOT actually sum to the total, the client's internal bookkeeping for this
		// session is wrong from this point forward. Logged via creature->error() so it is never
		// suppressed regardless of this object's own logging configuration.
		if (session == nullptr) {
			int bgSum = 0;
			const DeltaVector<int>* bgBaseHam = creature->getBaseHAM();

			for (int i = 0; i < 9; ++i)
				bgSum += bgBaseHam->get(i);

			int bgTotalLimit = PlayerCreationManager::instance()->getTotalAttributeLimit(creature->getSpeciesName());

			creature->error() << "[BG STATMIGRATION DEBUG] opening NEW migration session"
					<< " | player=" << creature->getFirstName() << " [" << creature->getObjectID() << "]"
					<< " | speciesName=" << creature->getSpeciesName()
					<< " | playerTemplate=" << (creature->getObjectTemplate() != nullptr ? creature->getObjectTemplate()->getFullTemplateString() : "<null>")
					<< " | rawSpeciesInt=" << creature->getSpecies()
					<< " | baseHAM=[" << bgBaseHam->get(0) << "," << bgBaseHam->get(1) << "," << bgBaseHam->get(2) << ","
					<< bgBaseHam->get(3) << "," << bgBaseHam->get(4) << "," << bgBaseHam->get(5) << ","
					<< bgBaseHam->get(6) << "," << bgBaseHam->get(7) << "," << bgBaseHam->get(8) << "]"
					<< " | sumOfBaseHAM=" << bgSum
					<< " | totalAttributeLimit=" << bgTotalLimit
					<< " | SUM_MATCHES_TOTAL=" << (bgSum == bgTotalLimit)
					<< " | minLimits=[" << PlayerCreationManager::instance()->getMinimumAttributeLimit(creature->getSpeciesName(), 0)
					<< "," << PlayerCreationManager::instance()->getMinimumAttributeLimit(creature->getSpeciesName(), 1)
					<< "," << PlayerCreationManager::instance()->getMinimumAttributeLimit(creature->getSpeciesName(), 2)
					<< "," << PlayerCreationManager::instance()->getMinimumAttributeLimit(creature->getSpeciesName(), 3)
					<< "," << PlayerCreationManager::instance()->getMinimumAttributeLimit(creature->getSpeciesName(), 4)
					<< "," << PlayerCreationManager::instance()->getMinimumAttributeLimit(creature->getSpeciesName(), 5)
					<< "," << PlayerCreationManager::instance()->getMinimumAttributeLimit(creature->getSpeciesName(), 6)
					<< "," << PlayerCreationManager::instance()->getMinimumAttributeLimit(creature->getSpeciesName(), 7)
					<< "," << PlayerCreationManager::instance()->getMinimumAttributeLimit(creature->getSpeciesName(), 8)
					<< "] | maxLimits=[" << PlayerCreationManager::instance()->getMaximumAttributeLimit(creature->getSpeciesName(), 0)
					<< "," << PlayerCreationManager::instance()->getMaximumAttributeLimit(creature->getSpeciesName(), 1)
					<< "," << PlayerCreationManager::instance()->getMaximumAttributeLimit(creature->getSpeciesName(), 2)
					<< "," << PlayerCreationManager::instance()->getMaximumAttributeLimit(creature->getSpeciesName(), 3)
					<< "," << PlayerCreationManager::instance()->getMaximumAttributeLimit(creature->getSpeciesName(), 4)
					<< "," << PlayerCreationManager::instance()->getMaximumAttributeLimit(creature->getSpeciesName(), 5)
					<< "," << PlayerCreationManager::instance()->getMaximumAttributeLimit(creature->getSpeciesName(), 6)
					<< "," << PlayerCreationManager::instance()->getMaximumAttributeLimit(creature->getSpeciesName(), 7)
					<< "," << PlayerCreationManager::instance()->getMaximumAttributeLimit(creature->getSpeciesName(), 8)
					<< "]";
		}

		if (session == nullptr) {
			session = new MigrateStatsSession(creature);

			const DeltaVector<int>* baseHam = creature->getBaseHAM();

			for (int i = 0; i < 9; ++i) {
				session->setAttributeToModify(i, baseHam->get(i));
			}

			creature->addActiveSession(SessionFacadeType::MIGRATESTATS, session);

			StatMigrationTargetsMessage* smtm = new StatMigrationTargetsMessage(creature);
			creature->sendMessage(smtm);
		} else {
			StatMigrationTargetsMessage* smtm = new StatMigrationTargetsMessage(creature, session);
			creature->sendMessage(smtm);
		}

		return SUCCESS;
	}

};

#endif //REQUESTSTATMIGRATIONDATACOMMAND_H_
