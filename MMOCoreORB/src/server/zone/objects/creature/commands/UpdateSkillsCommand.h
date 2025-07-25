/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef UPDATESKILLSCOMMAND_H_
#define UPDATESKILLSCOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/managers/skill/SkillManager.h"

class UpdateSkillsCommand : public QueueCommand {
public:

	UpdateSkillsCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;


		SkillManager* skillManager = SkillManager::instance();
		if (skillManager == nullptr)
			return GENERALERROR;
			
		const SkillList* skillList = creature->getSkillList();
		if (skillList == nullptr)
			return GENERALERROR;

		auto zoneServer = creature->getZoneServer();
		if (zoneServer == nullptr)
			return GENERALERROR;

		if (!creature->checkCooldownRecovery("updateSkills")) {
			creature->sendSystemMessage("You may only use the updateSkills command once per minute.");
			return GENERALERROR;
        }

		creature->updateCooldownTimer("updateSkills", 1000 * 60); // 1 minute cooldown

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
		if (ghost != nullptr) {

			int force = ghost->getForcePower();


			Vector<String> listOfNames;
			skillList->getStringList(listOfNames);
			std::sort(listOfNames.begin(), listOfNames.end(), std::less<std::string>());
			SkillList skillListCopy;
			skillListCopy.loadFromNames(listOfNames);

			for (int i = 0; i < skillListCopy.size(); ++i) {
				Skill* skill = skillListCopy.get(i);
				if (skill == nullptr)
					continue;
				String skillName = skill->getSkillName();

				if (!(skillName.beginsWith("admin") || skillName.beginsWith("social_language") || skillName.beginsWith("species"))) {				
					creature->sendSystemMessage("Updating skill: " + skillName);
					skillManager->surrenderSkillWithRegrant(skillName, creature, true, false, true, true);
					bool skillGranted = skillManager->awardSkillWithRegrant(skillName, creature, true, false, true, true);
				}			
			}

			skillManager->updateXpLimits(ghost);

			ghost->recalculateForcePower();
			ghost->setForcePower(force);

			return SUCCESS;
		}
		else {
			creature->sendSystemMessage("The player object could not be found so skills were not updated.");
			return GENERALERROR;
		}
	}

};

#endif //UPDATESKILLSCOMMAND_H_