/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#ifndef FORCEFOCUSCOMMAND_H_
#define FORCEFOCUSCOMMAND_H_

#include "server/zone/objects/player/events/ForceFocusTask.h"

class ForceFocusCommand : public QueueCommand {
public:

	ForceFocusCommand(const String& name, ZoneProcessServer* server)
	: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (!creature->isPlayerCreature())
			return GENERALERROR;

		if (isWearingArmor(creature)) {
			return NOJEDIARMOR;
		}
		
		if (creature->isInCombat()) {
			creature->sendSystemMessage("@jedi_spam:not_while_in_combat");
			return GENERALERROR;
		}

		if (creature->isMeditating()) {
			creature->sendSystemMessage("@jedi_spam:already_in_meditative_state"); // Same message as Force Meditate
			return GENERALERROR;
		}

		// Same visual effect as Force Meditate
		creature->playEffect("clienteffect/pl_force_meditate_self.cef", "");

		// Reuse the existing meditate state system but with enhanced ForceFocusTask
		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
		
		creature->sendSystemMessage("@teraskasi:med_begin"); // Same message as Force Meditate
		Reference<ForceFocusTask*> focusTask = new ForceFocusTask(creature);
		focusTask->setMoodString(creature->getMoodString());
		creature->addPendingTask("forcefocus", focusTask, 3500); // Different task name

		creature->setMeditateState(); // Reuse existing function

		PlayerManager* playermgr = server->getZoneServer()->getPlayerManager();	
		creature->registerObserver(ObserverEventType::POSTURECHANGED, playermgr);

		return SUCCESS;

	}

};

#endif //FORCEFOCUSCOMMAND_H_