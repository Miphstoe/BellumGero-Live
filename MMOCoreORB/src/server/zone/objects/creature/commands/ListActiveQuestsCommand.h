/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef LISTACTIVEQUESTSCOMMAND_H_
#define LISTACTIVEQUESTSCOMMAND_H_

#include <system/thread/Locker.h>

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"

class ListActiveQuestsCommand : public QueueCommand {
public:
	enum {
		RANGERS_PATH_MENU_ID = 900001,
		RANGERS_PATH_RESET_STAGE_MENU_ID = 900002,
		RANGERS_PATH_RESET_ALL_MENU_ID = 900003
	};

	ListActiveQuestsCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		PlayerObject* ghost = creature->getPlayerObject();

		if (ghost == nullptr)
			return GENERALERROR;

		PlayerManager* playerManager = server->getZoneServer()->getPlayerManager();
		ManagedReference<CreatureObject*> targetObj = nullptr;

		if (creature->getTargetID() != 0) {
			targetObj = server->getZoneServer()->getObject(creature->getTargetID()).castTo<CreatureObject*>();
		} else if (target != 0) {
			targetObj = server->getZoneServer()->getObject(target).castTo<CreatureObject*>();
		} else {
			StringTokenizer args(arguments.toString());

			if(!args.hasMoreTokens())
				return GENERALERROR;

			String targetName = "";
			args.getStringToken(targetName);

			targetObj = playerManager->getPlayer(targetName);
		}

		if (targetObj == nullptr)
			return INVALIDTARGET;

		if (!targetObj->isPlayerCreature())
			return INVALIDTARGET;

		PlayerObject* targetGhost = targetObj->getPlayerObject();

		if (targetGhost == nullptr)
			return INVALIDTARGET;

		ManagedReference<SuiListBox*> box = new SuiListBox(creature, 0);
		box->setUsingObject(targetObj);
		box->setCallback(new LambdaSuiCallback([=](CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
			if (player == nullptr || suiBox == nullptr || !suiBox->isListBox() || eventIndex == 1 || args == nullptr || args->size() < 1)
				return;

			int index = Integer::valueOf(args->get(0).toString());

			if (index < 0)
				return;

			SuiListBox* listBox = cast<SuiListBox*>(suiBox);

			if (listBox == nullptr)
				return;

			uint64 menuObjectId = listBox->getMenuObjectID(index);
			ManagedReference<SceneObject*> usingObject = listBox->getUsingObject();
			ManagedReference<CreatureObject*> selectedTarget = cast<CreatureObject*>(usingObject.get());

			if (selectedTarget == nullptr || !selectedTarget->isPlayerCreature())
				return;

			PlayerObject* selectedGhost = selectedTarget->getPlayerObject();

			if (selectedGhost == nullptr)
				return;

			String questLabel = listBox->getMenuItemName(index);

			if (menuObjectId == RANGERS_PATH_MENU_ID) {
				String currentStage = selectedGhost->getScreenPlayData("rangers_path", "current_stage");

				if (currentStage.isEmpty())
					currentStage = "0";

				ManagedReference<SuiListBox*> rangerBox = new SuiListBox(player, 0);
				rangerBox->setUsingObject(selectedTarget);
				String selectedRewarded = selectedGhost->getScreenPlayData("rangers_path", "rewarded");
				rangerBox->setPromptTitle("Ranger's Path Reset");
				rangerBox->setPromptText("Choose how to reset The Ranger's Path for " + selectedTarget->getFirstName() + ".");
				rangerBox->setForceCloseDisabled();
				if (selectedRewarded != "1")
					rangerBox->addMenuItem("Reset Current Stage (" + currentStage + ")", RANGERS_PATH_RESET_STAGE_MENU_ID);
				rangerBox->addMenuItem("Reset Entire Quest", RANGERS_PATH_RESET_ALL_MENU_ID);

				rangerBox->setCallback(new LambdaSuiCallback([=](CreatureObject* rangerPlayer, SuiBox* rangerSui, uint32 rangerEventIndex, Vector<UnicodeString>* rangerArgs) {
					if (rangerPlayer == nullptr || rangerSui == nullptr || !rangerSui->isListBox() || rangerEventIndex == 1 || rangerArgs == nullptr || rangerArgs->size() < 1)
						return;

					int rangerIndex = Integer::valueOf(rangerArgs->get(0).toString());

					if (rangerIndex < 0)
						return;

					SuiListBox* rangerListBox = cast<SuiListBox*>(rangerSui);

					if (rangerListBox == nullptr)
						return;

					uint64 rangerActionId = rangerListBox->getMenuObjectID(rangerIndex);
					ManagedReference<SceneObject*> rangerUsingObject = rangerListBox->getUsingObject();
					ManagedReference<CreatureObject*> rangerTarget = cast<CreatureObject*>(rangerUsingObject.get());

					if (rangerTarget == nullptr || !rangerTarget->isPlayerCreature())
						return;

					String actionLabel = rangerListBox->getMenuItemName(rangerIndex);

					ManagedReference<SuiMessageBox*> confirm = new SuiMessageBox(rangerPlayer, 0);
					confirm->setUsingObject(rangerTarget);
					confirm->setPromptTitle("Confirm Ranger's Path Reset");
					confirm->setPromptText("Apply this reset to " + rangerTarget->getFirstName() + "?\n\n" + actionLabel);
					confirm->setCancelButton(true, "@cancel");
					confirm->setOkButton(true, "@ok");

					confirm->setCallback(new LambdaSuiCallback([=](CreatureObject* confirmPlayer, SuiBox* confirmSui, uint32 confirmEventIndex, Vector<UnicodeString>* confirmArgs) {
						if (confirmPlayer == nullptr || confirmEventIndex == 1)
							return;

						ManagedReference<SceneObject*> usingObject = confirmSui->getUsingObject().get();

						if (usingObject == nullptr || !usingObject->isCreatureObject())
							return;

						CreatureObject* resetTarget = cast<CreatureObject*>(usingObject.get());

						if (resetTarget == nullptr || !resetTarget->isPlayerCreature())
							return;

						PlayerObject* resetGhost = resetTarget->getPlayerObject();

						if (resetGhost == nullptr)
							return;

						Locker locker(resetTarget, confirmPlayer);

						if (rangerActionId == RANGERS_PATH_RESET_ALL_MENU_ID) {
							resetGhost->clearScreenPlayData("rangers_path");
							confirmPlayer->sendSystemMessage("Reset The Ranger's Path for " + resetTarget->getFirstName() + ".");
							return;
						}

						if (rangerActionId == RANGERS_PATH_RESET_STAGE_MENU_ID) {
							String currentStage = resetGhost->getScreenPlayData("rangers_path", "current_stage");

							if (currentStage.isEmpty() || currentStage == "0") {
								confirmPlayer->sendSystemMessage(resetTarget->getFirstName() + " is not on an active Ranger's Path stage.");
								return;
							}

							Vector<String> priorStageCompleteKeys;
							Vector<String> priorStageCompleteValues;

							int currentStageValue = Integer::valueOf(currentStage);
							int resetToStageValue = currentStageValue - 1;

							if (currentStageValue <= 1) {
								resetGhost->clearScreenPlayData("rangers_path");
								confirmPlayer->sendSystemMessage("Reset Stage 1 for " + resetTarget->getFirstName() + ". They can now accept the quest again.");
								return;
							}

							for (int stageNum = 1; stageNum < resetToStageValue; ++stageNum) {
								String key = "stage_" + String::valueOf(stageNum) + "_complete";
								priorStageCompleteKeys.add(key);
								priorStageCompleteValues.add(resetGhost->getScreenPlayData("rangers_path", key));
							}

							resetGhost->clearScreenPlayData("rangers_path");
							resetGhost->setScreenPlayData("rangers_path", "started", "1");
							resetGhost->setScreenPlayData("rangers_path", "current_stage", String::valueOf(resetToStageValue));
							resetGhost->setScreenPlayData("rangers_path", "completed", "0");
							resetGhost->setScreenPlayData("rangers_path", "rewarded", "0");
							resetGhost->setScreenPlayData("rangers_path", "active_encounter", "0");
							resetGhost->setScreenPlayData("rangers_path", "encounter_stage", "0");
							resetGhost->setScreenPlayData("rangers_path", "encounter_serial", "0");
							resetGhost->setScreenPlayData("rangers_path", "encounter_count", "0");
							resetGhost->setScreenPlayData("rangers_path", "encounter_remaining", "0");
							resetGhost->setScreenPlayData("rangers_path", "encounter_area_id", "0");
							resetGhost->setScreenPlayData("rangers_path", "encounter_aux_area_id", "0");
							resetGhost->setScreenPlayData("rangers_path", "encounter_object_id", "0");
							resetGhost->setScreenPlayData("rangers_path", "stage_waypoint_id", "0");
							resetGhost->setScreenPlayData("rangers_path", "return_waypoint_id", "0");
							resetGhost->setScreenPlayData("rangers_path", "stage2_crate_used", "0");
							resetGhost->setScreenPlayData("rangers_path", "stage2_kill_count", "0");
							resetGhost->setScreenPlayData("rangers_path", "stage3_trail_step", "1");
							resetGhost->setScreenPlayData("rangers_path", "stage3_site_reached", "0");
							resetGhost->setScreenPlayData("rangers_path", "stage3_datapad_retrieved", "0");
							resetGhost->setScreenPlayData("rangers_path", "stage5_defense_started", "0");
							resetGhost->setScreenPlayData("rangers_path", "stage5_wave", "0");
							resetGhost->setScreenPlayData("rangers_path", "stage5_reset_pending", "0");
							resetGhost->setScreenPlayData("rangers_path", "stage5_required_settlers_alive", "0");
							resetGhost->setScreenPlayData("rangers_path", "stage5_total_settlers", "0");

							for (int stageNum = 1; stageNum <= 6; ++stageNum) {
								resetGhost->setScreenPlayData("rangers_path", "stage_" + String::valueOf(stageNum) + "_ready", "0");
							}

							for (int slot = 1; slot <= 8; ++slot) {
								resetGhost->setScreenPlayData("rangers_path", "encounter_mob_id_" + String::valueOf(slot), "0");
							}

							for (int slot = 1; slot <= 4; ++slot) {
								resetGhost->setScreenPlayData("rangers_path", "settler_mob_id_" + String::valueOf(slot), "0");
							}

							for (int i = 0; i < priorStageCompleteKeys.size(); ++i) {
								if (priorStageCompleteValues.get(i) == "1")
									resetGhost->setScreenPlayData("rangers_path", priorStageCompleteKeys.get(i), "1");
							}

							resetGhost->setScreenPlayData("rangers_path", "stage_" + String::valueOf(resetToStageValue) + "_ready", "1");

							confirmPlayer->sendSystemMessage("Rolled back " + resetTarget->getFirstName() + " to the Stage " + String::valueOf(resetToStageValue) + " turn-in point for The Ranger's Path.");
							return;
						}
					}, server->getZoneServer(), "ListActiveQuestsRangerResetConfirmCallback"));

					PlayerObject* rangerPlayerGhost = rangerPlayer->getPlayerObject();

					if (rangerPlayerGhost == nullptr)
						return;

					rangerPlayerGhost->addSuiBox(confirm);
					rangerPlayer->sendMessage(confirm->generateMessage());
				}, server->getZoneServer(), "ListActiveQuestsRangerSelectCallback"));

				PlayerObject* rangerPlayerGhost = player->getPlayerObject();

				if (rangerPlayerGhost == nullptr)
					return;

				rangerPlayerGhost->addSuiBox(rangerBox);
				player->sendMessage(rangerBox->generateMessage());
				return;
			}

			ManagedReference<SuiMessageBox*> confirm = new SuiMessageBox(player, 0);
			confirm->setUsingObject(selectedTarget);
			confirm->setPromptTitle("Reset Active Quest");
			confirm->setPromptText("Reset this quest for " + selectedTarget->getFirstName() + "?\n\n" + questLabel);
			confirm->setCancelButton(true, "@cancel");
			confirm->setOkButton(true, "@ok");

			confirm->setCallback(new LambdaSuiCallback([=](CreatureObject* confirmPlayer, SuiBox* confirmSui, uint32 confirmEventIndex, Vector<UnicodeString>* confirmArgs) {
				if (confirmPlayer == nullptr || confirmEventIndex == 1)
					return;

				ManagedReference<SceneObject*> usingObject = confirmSui->getUsingObject().get();

				if (usingObject == nullptr || !usingObject->isCreatureObject())
					return;

				CreatureObject* resetTarget = cast<CreatureObject*>(usingObject.get());

				if (resetTarget == nullptr || !resetTarget->isPlayerCreature())
					return;

				PlayerObject* resetGhost = resetTarget->getPlayerObject();

				if (resetGhost == nullptr)
					return;

				Locker locker(resetTarget, confirmPlayer);

				if (menuObjectId == RANGERS_PATH_MENU_ID) {
					resetGhost->clearScreenPlayData("rangers_path");
					confirmPlayer->sendSystemMessage("Reset The Ranger's Path for " + resetTarget->getFirstName() + ".");
					return;
				}

				resetGhost->clearActiveQuestsBit((int)menuObjectId, true);
				confirmPlayer->sendSystemMessage("Reset active quest bit " + String::valueOf((int)menuObjectId) + " for " + resetTarget->getFirstName() + ".");
			}, server->getZoneServer(), "ListActiveQuestsResetConfirmCallback"));

			PlayerObject* playerGhost = player->getPlayerObject();

			if (playerGhost == nullptr)
				return;

			playerGhost->addSuiBox(confirm);
			player->sendMessage(confirm->generateMessage());
		}, server->getZoneServer(), "ListActiveQuestsSelectCallback"));

		box->setPromptTitle("Active Quests");
		box->setPromptText("List of active quests for " + targetObj->getFirstName() + ". Select a quest to reset it.");
		box->setForceCloseDisabled();

		for (int i = 0; i < playerManager->getTotalPlayerQuests(); i++) {
			if (targetGhost->hasActiveQuestBitSet(i)) {
				QuestInfo* info = playerManager->getQuestInfo(i);
				box->addMenuItem(info->getJournalSummary() + " (" + info->getQuestName() + ")", i);
			}
		}

		String rangersStarted = targetGhost->getScreenPlayData("rangers_path", "started");
		String rangersRewarded = targetGhost->getScreenPlayData("rangers_path", "rewarded");

		if (rangersStarted == "1") {
			String currentStage = targetGhost->getScreenPlayData("rangers_path", "current_stage");

			if (currentStage.isEmpty())
				currentStage = "0";

			String rangerLabel = rangersRewarded == "1"
				? "The Ranger's Path (COMPLETED)"
				: "The Ranger's Path (screenplay quest, stage " + currentStage + ")";

			box->addMenuItem(rangerLabel, RANGERS_PATH_MENU_ID);
		}

		ghost->addSuiBox(box);
		creature->sendMessage(box->generateMessage());

		return SUCCESS;
	}

};

#endif //LISTACTIVEQUESTSCOMMAND_H_
