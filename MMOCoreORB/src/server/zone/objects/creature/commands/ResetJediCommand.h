/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef RESETJEDICOMMAND_H_
#define RESETJEDICOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/managers/mission/MissionManager.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/managers/frs/FrsManager.h"
#include "server/zone/objects/creature/buffs/BuffCRC.h"
#include "server/zone/objects/player/variables/FrsData.h"
#include "server/login/account/Account.h"

class ResetJediCommand : public QueueCommand {
	bool isJediResetSkill(const String& skillName) const {
		return skillName == "force_sensitive" ||
				skillName == "force_discipline" ||
				skillName.beginsWith("force_sensitive_") ||
				skillName.beginsWith("force_discipline_") ||
				skillName.beginsWith("force_title_jedi_") ||
				skillName.beginsWith("force_rank_") ||
				skillName.beginsWith("jedi_");
	}

	void clearVillageProgression(CreatureObject* targetCreature, PlayerObject* targetGhost) const {
		targetCreature->setScreenPlayState("VillageJediProgression", 0);
		targetGhost->clearScreenPlayData("VillageJediProgression");
		targetGhost->clearScreenPlayData("KnightTrials");
		targetGhost->clearScreenPlayData("PadawanTrials");

		const char* villageBranches[] = {
			"force_sensitive_combat_prowess_ranged_accuracy",
			"force_sensitive_combat_prowess_ranged_speed",
			"force_sensitive_combat_prowess_melee_accuracy",
			"force_sensitive_combat_prowess_melee_speed",
			"force_sensitive_enhanced_reflexes_ranged_defense",
			"force_sensitive_enhanced_reflexes_melee_defense",
			"force_sensitive_enhanced_reflexes_vehicle_control",
			"force_sensitive_enhanced_reflexes_survival",
			"force_sensitive_crafting_mastery_experimentation",
			"force_sensitive_crafting_mastery_assembly",
			"force_sensitive_crafting_mastery_repair",
			"force_sensitive_crafting_mastery_technique",
			"force_sensitive_heightened_senses_healing",
			"force_sensitive_heightened_senses_surveying",
			"force_sensitive_heightened_senses_persuasion",
			"force_sensitive_heightened_senses_luck"
		};

		for (uint32 i = 0; i < sizeof(villageBranches) / sizeof(villageBranches[0]); ++i) {
			targetCreature->setScreenPlayState("VillageUnlockScreenPlay:" + String(villageBranches[i]), 0);
		}
	}

	void clearJediBuffs(CreatureObject* targetCreature) const {
		const uint32 jediBuffs[] = {
			BuffCRC::JEDI_FORCE_RUN_1,
			BuffCRC::JEDI_FORCE_RUN_2,
			BuffCRC::JEDI_FORCE_RUN_3,
			BuffCRC::JEDI_FORCE_SPEED_1,
			BuffCRC::JEDI_FORCE_SPEED_2,
			BuffCRC::JEDI_FORCE_ARMOR_1,
			BuffCRC::JEDI_FORCE_ARMOR_2,
			BuffCRC::JEDI_FORCE_SHIELD_1,
			BuffCRC::JEDI_FORCE_SHIELD_2,
			BuffCRC::JEDI_FORCE_PROTECTION_1,
			BuffCRC::JEDI_FORCE_FEEDBACK_1,
			BuffCRC::JEDI_FORCE_FEEDBACK_2,
			BuffCRC::JEDI_FORCE_ABSORB_1,
			BuffCRC::JEDI_FORCE_ABSORB_2,
			BuffCRC::JEDI_RESIST_DISEASE,
			BuffCRC::JEDI_RESIST_POISON,
			BuffCRC::JEDI_RESIST_BLEEDING,
			BuffCRC::JEDI_RESIST_STATES,
			BuffCRC::JEDI_AVOID_INCAPACITATION,
			BuffCRC::JEDI_AVOID_INCAPACITATION_1,
			BuffCRC::JEDI_AVOID_INCAPACITATION_2,
			BuffCRC::JEDI_AVOID_INCAPACITATION_3,
			BuffCRC::JEDI_AVOID_INCAPACITATION_4,
			BuffCRC::JEDI_AVOID_INCAPACITATION_5,
			BuffCRC::FS_CRYSTAL_RESURRECT,
			STRING_HASHCODE("private_force_regen_debuff")
		};

		for (uint32 i = 0; i < sizeof(jediBuffs) / sizeof(jediBuffs[0]); ++i) {
			targetCreature->removeBuff(jediBuffs[i]);
		}
	}

public:

	ResetJediCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		ManagedReference<CreatureObject*> targetCreature = nullptr;

		try {
			StringTokenizer args(arguments.toString());

			if (args.hasMoreTokens()) {
				String targetName;
				args.getStringToken(targetName);
				targetCreature = server->getZoneServer()->getPlayerManager()->getPlayer(targetName);
			}
		} catch (Exception& e) {
			creature->sendSystemMessage("Usage: /resetJedi <PlayerName>");
			return INVALIDPARAMETERS;
		}

		if (targetCreature == nullptr) {
			ManagedReference<SceneObject*> object = server->getZoneServer()->getObject(target);

			if (object != nullptr && object->isPlayerCreature())
				targetCreature = cast<CreatureObject*>(object.get());
		}

		if (targetCreature == nullptr || !targetCreature->isPlayerCreature()) {
			creature->sendSystemMessage("Unable to find an online player target. Usage: /resetJedi <PlayerName>");
			return INVALIDTARGET;
		}

		Locker clocker(targetCreature, creature);

		ManagedReference<PlayerObject*> targetGhost = targetCreature->getPlayerObject();

		if (targetGhost == nullptr)
			return GENERALERROR;

		int previousJediState = targetGhost->getJediState();
		int previousForcePower = targetGhost->getForcePower();
		int previousForcePowerMax = targetGhost->getForcePowerMax();
		float previousVisibility = targetGhost->getVisibility();

		const SkillList* skillList = targetCreature->getSkillList();
		Vector<String> skillsToRemove;

		for (int i = 0; i < skillList->size(); ++i) {
			Skill* skill = skillList->get(i);

			if (skill != nullptr && isJediResetSkill(skill->getSkillName()))
				skillsToRemove.add(skill->getSkillName());
		}

		int jediSkillCandidates = skillsToRemove.size();
		int jediSkillsRemoved = 0;
		bool removedSkill = true;

		while (skillsToRemove.size() > 0 && removedSkill) {
			removedSkill = false;

			for (int i = skillsToRemove.size() - 1; i >= 0; --i) {
				if (SkillManager::instance()->surrenderSkill(skillsToRemove.get(i), targetCreature, true, true, true, true)) {
					skillsToRemove.remove(i);
					++jediSkillsRemoved;
					removedSkill = true;
				}
			}
		}

		FrsManager* frsManager = targetCreature->getZoneServer()->getFrsManager();
		FrsData* frsData = targetGhost->getFrsData();

		if (frsManager != nullptr && frsData != nullptr && (frsData->getRank() >= 0 || frsData->getCouncilType() != 0)) {
			frsManager->removeFromFrs(targetCreature);
		}

		if (frsData != nullptr) {
			frsData->setRank(-1);
			frsData->setCouncilType(0);
		}

		clearVillageProgression(targetCreature, targetGhost);
		targetGhost->setJediState(0);
		targetGhost->setVisibility(0);
		clearJediBuffs(targetCreature);

		// PlayerObject baseline 8 serializes forcePower and forcePowerMax directly.
		// Both must be zero after skill/mod cleanup or the client can rebuild a Force bar on relog.
		targetGhost->recalculateForcePower();
		targetGhost->setForcePower(0, true);
		targetGhost->setForcePowerMax(0, true);
		targetGhost->setForcePower(0, true);

		MissionManager* missionManager = targetCreature->getZoneServer()->getMissionManager();

		if (missionManager != nullptr)
			missionManager->removePlayerFromBountyList(targetCreature->getObjectID());

		String staffAccount = "unknown";
		ManagedReference<PlayerObject*> staffGhost = creature->getPlayerObject();

		if (staffGhost != nullptr && staffGhost->getAccount() != nullptr)
			staffAccount = staffGhost->getAccount()->getUsername();

		StringBuffer logMsg;
		logMsg << "Jedi reset by staff " << creature->getFirstName() << " account " << staffAccount
				<< " target " << targetCreature->getFirstName()
				<< " previousJediState=" << previousJediState
				<< " resultingJediState=" << targetGhost->getJediState()
				<< " jediSkillCandidates=" << jediSkillCandidates
				<< " jediSkillsRemoved=" << jediSkillsRemoved
				<< " jediSkillsRemaining=" << skillsToRemove.size()
				<< " previousForce=" << previousForcePower << "/" << previousForcePowerMax
				<< " resultingForce=" << targetGhost->getForcePower() << "/" << targetGhost->getForcePowerMax()
				<< " previousVisibility=" << previousVisibility
				<< " resultingVisibility=" << targetGhost->getVisibility();
		creature->info(logMsg.toString(), true);

		String staffMessage = "Jedi reset completed for " + targetCreature->getFirstName() + ". Jedi progression, Jedi skills, and Force Power have been reset. A full relog may be required for the Force bar to disappear.";
		creature->sendSystemMessage(staffMessage);
		targetCreature->sendSystemMessage("Your Jedi progression, Jedi skills, and Force Power have been reset by staff. Please fully log out and back in if the Force bar remains visible.");

		if (skillsToRemove.size() > 0) {
			StringBuffer remainingSkills;
			remainingSkills << "Warning: " << skillsToRemove.size() << " Jedi/Force skills could not be surrendered through SkillManager:";

			for (int i = 0; i < skillsToRemove.size(); ++i)
				remainingSkills << " " << skillsToRemove.get(i);

			creature->sendSystemMessage(remainingSkills.toString());
			creature->info(remainingSkills.toString(), true);
		}

		return SUCCESS;
	}

};

#endif //RESETJEDICOMMAND_H_
