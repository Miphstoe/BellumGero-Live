/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef FINDMYTRAINERCOMMAND_H_
#define FINDMYTRAINERCOMMAND_H_

class FindMyTrainerCommand : public QueueCommand {
	static constexpr uint64 JEDI_TRAINER_REROLL_COOLDOWN_SECONDS = 72 * 60 * 60;

public:
	FindMyTrainerCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (!creature->isPlayerCreature())
			return GENERALERROR;

		auto ghost = creature->getPlayerObject();

		if (ghost == nullptr)
			return GENERALERROR;

		String commandArgument = arguments.toString().trim().toLowerCase();
		bool rerollRequested = commandArgument == "new";

		if (!commandArgument.isEmpty() && !rerollRequested) {
			creature->sendSystemMessage("Usage: /findmytrainer [new]");
			return GENERALERROR;
		}

		if (ghost->getJediState() < 2 || !creature->hasSkill("force_title_jedi_rank_02")) {
			if (rerollRequested)
				creature->sendSystemMessage("You are not currently eligible to request a randomized Jedi trainer.");

			return GENERALERROR;
		}

		auto zoneServer = server->getZoneServer();

		if (zoneServer == nullptr)
			return GENERALERROR;

		if (rerollRequested)
			return rerollTrainer(creature, zoneServer, ghost);

		String planet = ghost->getTrainerZoneName();

		if (planet.isEmpty()) {
			// Pick a trainer for the Jedi
			if (!setJediTrainer(zoneServer, ghost)) {
				creature->sendSystemMessage("A Jedi trainer cannot currently be located. Please try again later.");
				return GENERALERROR;
			}

			// Retrieve trainer zone from the player object
			planet = ghost->getTrainerZoneName();
		} else {
			auto trainerZone = zoneServer->getZone(planet);

			if (trainerZone == nullptr) {
				if (!setJediTrainer(zoneServer, ghost)) {
					creature->sendSystemMessage("A Jedi trainer cannot currently be located. Please try again later.");
					return GENERALERROR;
				}
				planet = ghost->getTrainerZoneName();
			}
		}

		if (!updateTrainerWaypoint(zoneServer, ghost, planet, ghost->getJediTrainerCoordinates())) {
			creature->sendSystemMessage("Your Jedi trainer was located, but a waypoint could not be created. Please try again later.");
			return GENERALERROR;
		}

		creature->sendSystemMessage("@jedi_spam:waypoint_created_to_trainer");

		return SUCCESS;
	}

	bool setJediTrainer(ZoneServer* zoneServer, PlayerObject* ghost) const {
		if (ghost == nullptr || zoneServer == nullptr)
			return false;

		Vector<ManagedReference<SceneObject*>> trainers;
		getValidJediTrainers(zoneServer, trainers);

		if (trainers.size() <= 0)
			return false;

		SceneObject* trainer = trainers.get(System::random(trainers.size() - 1));
		CreatureObject* trainerCreo = trainer == nullptr ? nullptr : trainer->asCreatureObject();
		Zone* trainerZone = trainerCreo == nullptr ? nullptr : trainerCreo->getZone();

		if (trainerZone == nullptr)
			return false;

		String trainerZoneName = trainerZone->getZoneName();
		ghost->setTrainerCoordinates(trainerCreo->getWorldPosition());
		ghost->setTrainerZoneName(trainerZoneName);

		return true;
	}

	void getValidJediTrainers(ZoneServer* zoneServer, Vector<ManagedReference<SceneObject*>>& trainers) const {
		if (zoneServer == nullptr)
			return;

		Vector<uint32> trainerTypes = {STRING_HASHCODE("trainer_brawler"), STRING_HASHCODE("trainer_artisan"), STRING_HASHCODE("trainer_scout"), STRING_HASHCODE("trainer_marksman"), STRING_HASHCODE("trainer_entertainer"), STRING_HASHCODE("trainer_medic")};

		// Get all trainers in galaxy and build list based on above trainer sub map categories
		for (int i = 0; i < zoneServer->getZoneCount(); ++i) {
			auto zone = zoneServer->getZone(i);

			if (zone == nullptr)
				continue;

			SortedVector<ManagedReference<SceneObject*>> objectList = zone->getPlanetaryObjectList("trainer");

			for (int j = 0; j < objectList.size(); ++j) {
				ManagedReference<SceneObject*> trainer = objectList.get(j);

				if (trainer == nullptr)
					continue;

				uint32 subCatCrc = trainer->getPlanetMapSubCategoryCRC();

				for (int k = 0; k < trainerTypes.size(); ++k) {
					uint32 typeHash = trainerTypes.get(k);

					if (subCatCrc == 0 || typeHash != subCatCrc)
						continue;

					CreatureObject* trainerCreo = trainer->asCreatureObject();

					if (trainerCreo == nullptr)
						break;

					Zone* trainerZone = trainerCreo->getZone();

					if (trainerZone == nullptr || trainerZone->getZoneName() == "tutorial")
						break;

					if (!(trainerCreo->getOptionsBitmask() & OptionBitmask::CONVERSE))
						break;

					ManagedReference<CityRegion*> city = trainerCreo->getCityRegion().get();

					// Player-city trainers are not part of the randomized Jedi trainer pool.
					if (city != nullptr && !city->isClientRegion())
						break;

					trainers.add(trainer);

					break;
				}
			}
		}
	}

	bool isAssignedTrainer(PlayerObject* ghost, CreatureObject* trainer) const {
		if (ghost == nullptr || trainer == nullptr || trainer->getZone() == nullptr)
			return false;

		Vector3 assignedCoordinates = ghost->getJediTrainerCoordinates();
		Vector3 trainerCoordinates = trainer->getWorldPosition();

		// Trainer identity is persisted as zone plus waypoint coordinates; elevation is
		// not part of the existing trainer/waypoint comparison.
		return ghost->getTrainerZoneName() == trainer->getZone()->getZoneName() && assignedCoordinates.getX() == trainerCoordinates.getX() && assignedCoordinates.getY() == trainerCoordinates.getY();
	}

	int rerollTrainer(CreatureObject* creature, ZoneServer* zoneServer, PlayerObject* ghost) const {
		Vector<ManagedReference<SceneObject*>> trainers;
		getValidJediTrainers(zoneServer, trainers);

		if (trainers.size() <= 0) {
			creature->sendSystemMessage("A Jedi trainer cannot currently be located. Please try again later.");
			return GENERALERROR;
		}

		bool hasValidAssignment = false;
		Vector<ManagedReference<SceneObject*>> alternatives;

		for (int i = 0; i < trainers.size(); ++i) {
			SceneObject* trainer = trainers.get(i);
			CreatureObject* trainerCreo = trainer == nullptr ? nullptr : trainer->asCreatureObject();

			if (isAssignedTrainer(ghost, trainerCreo)) {
				hasValidAssignment = true;
				continue;
			}

			alternatives.add(trainer);
		}

		// Missing or invalid stored trainer data is repaired as an initial assignment,
		// not charged as a reroll.
		if (!hasValidAssignment) {
			String oldZone = ghost->getTrainerZoneName();
			Vector3 oldCoordinates = ghost->getJediTrainerCoordinates();

			if (!setJediTrainer(zoneServer, ghost)) {
				creature->sendSystemMessage("A Jedi trainer cannot currently be assigned. Please try again later.");
				return GENERALERROR;
			}

			if (!updateTrainerWaypoint(zoneServer, ghost, ghost->getTrainerZoneName(), ghost->getJediTrainerCoordinates())) {
				ghost->setTrainerCoordinates(oldCoordinates);
				ghost->setTrainerZoneName(oldZone);
				creature->sendSystemMessage("A Jedi trainer cannot currently be assigned. Please try again later.");
				return GENERALERROR;
			}

			creature->sendSystemMessage("A Jedi trainer has been assigned to you. Your trainer waypoint has been updated.");
			return SUCCESS;
		}

		uint64 currentTime = System::getTime();
		uint64 nextAllowedTime = ghost->getJediTrainerRerollNextTime();

		if (currentTime < nextAllowedTime) {
			creature->sendSystemMessage(getCooldownMessage(nextAllowedTime - currentTime));
			return GENERALERROR;
		}

		if (alternatives.size() <= 0) {
			creature->sendSystemMessage("Another valid Jedi trainer cannot currently be assigned. Your existing trainer has not changed.");
			return GENERALERROR;
		}

		SceneObject* newTrainer = alternatives.get(System::random(alternatives.size() - 1));
		CreatureObject* newTrainerCreo = newTrainer == nullptr ? nullptr : newTrainer->asCreatureObject();
		Zone* newTrainerZone = newTrainerCreo == nullptr ? nullptr : newTrainerCreo->getZone();

		if (newTrainerZone == nullptr) {
			creature->sendSystemMessage("A new Jedi trainer cannot currently be assigned. Your existing trainer has not changed.");
			return GENERALERROR;
		}

		String oldZone = ghost->getTrainerZoneName();
		Vector3 oldCoordinates = ghost->getJediTrainerCoordinates();
		String newZone = newTrainerZone->getZoneName();
		Vector3 newCoordinates = newTrainerCreo->getWorldPosition();

		ghost->setTrainerCoordinates(newCoordinates);
		ghost->setTrainerZoneName(newZone);

		if (!updateTrainerWaypoint(zoneServer, ghost, newZone, newCoordinates)) {
			ghost->setTrainerCoordinates(oldCoordinates);
			ghost->setTrainerZoneName(oldZone);
			creature->sendSystemMessage("A new Jedi trainer could not be assigned. Your existing trainer has not changed.");
			return GENERALERROR;
		}

		// Write the persistent cooldown only after assignment and waypoint replacement succeed.
		ghost->setJediTrainerRerollNextTime(currentTime + JEDI_TRAINER_REROLL_COOLDOWN_SECONDS);

		creature->info() << "FindMyTrainer reroll: player=" << creature->getObjectID() << " oldTrainer=" << oldZone << "(" << oldCoordinates.getX() << "," << oldCoordinates.getY() << ") newTrainer=" << newZone << "(" << newCoordinates.getX() << "," << newCoordinates.getY() << ") cooldownSeconds=" << JEDI_TRAINER_REROLL_COOLDOWN_SECONDS;
		creature->sendSystemMessage("A new Jedi trainer has been selected for you. Your trainer waypoint has been updated. You may request another trainer in 72 hours.");

		return SUCCESS;
	}

	bool updateTrainerWaypoint(ZoneServer* zoneServer, PlayerObject* ghost, const String& planet, const Vector3& coords) const {
		if (zoneServer == nullptr || ghost == nullptr || planet.isEmpty())
			return false;

		ManagedReference<WaypointObject*> waypointObj = (zoneServer->createObject(0xc456e788, 1)).castTo<WaypointObject*>();

		if (waypointObj == nullptr)
			return false;

		Locker locker(waypointObj);
		waypointObj->setPlanetCRC(planet.hashCode());
		waypointObj->setPosition(coords.getX(), 0, coords.getY());
		waypointObj->setCustomObjectName("@jedi_spam:trainer_waypoint_name", false);
		waypointObj->setSpecialTypeID(WaypointObject::SPECIALTYPE_FINDMYTRAINER);

		// addWaypoint replaces the prior trainer waypoint by its legacy name or special type.
		ghost->addWaypoint(waypointObj, true, true);

		return true;
	}

	String getCooldownMessage(uint64 secondsRemaining) const {
		// Round up so a sub-minute remainder is never displayed as zero minutes.
		uint64 totalMinutes = (secondsRemaining + 59) / 60;
		uint64 days = totalMinutes / (24 * 60);
		uint64 hours = (totalMinutes / 60) % 24;
		uint64 minutes = totalMinutes % 60;
		String message = "You cannot request another Jedi trainer yet. You may choose a new trainer again in ";

		if (days > 0)
			message += String::valueOf(days) + (days == 1 ? " day, " : " days, ");

		message += String::valueOf(hours) + (hours == 1 ? " hour, and " : " hours, and ");
		message += String::valueOf(minutes) + (minutes == 1 ? " minute." : " minutes.");

		return message;
	}
};

#endif // FINDMYTRAINERCOMMAND_H_
