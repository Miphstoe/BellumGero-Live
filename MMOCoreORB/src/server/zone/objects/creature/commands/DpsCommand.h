/*
 * DpsCommand.h
 *
 * Player-facing controls for the transient timed DPS session system.
 */

#ifndef DPSCOMMAND_H_
#define DPSCOMMAND_H_

#include "server/zone/managers/combat/DpsSessionManager.h"
#include "server/zone/objects/creature/ai/AiAgent.h"
#include "server/zone/objects/creature/ai/CreatureTemplate.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"

class DpsSessionSuiCallback;

class DpsCommandUi {
public:
	enum MenuAction {
		START_ONE_MINUTE = 1,
		START_FIVE_MINUTES = 2,
		STOP_SESSION = 3,
		VIEW_STATUS = 4,
		RESTART_SESSION = 5,
		TOGGLE_UPDATES = 6,
		SHOW_HELP = 7
	};

	static String getDurationLabel(uint64 durationMillis) {
		if (durationMillis >= DpsSessionManager::FIVE_MINUTES_MILLIS)
			return "5-minute";

		return "1-minute";
	}

	static bool getTrainingDummyInfo(SceneObject* object, uint64& objectID,
		String& profileLabel, String& profileDescription) {
		objectID = 0;
		profileLabel = "";
		profileDescription = "";

		if (object == nullptr || !object->isAiAgent())
			return false;

		AiAgent* agent = object->asAiAgent();

		if (agent == nullptr)
			return false;

		const CreatureTemplate* creatureTemplate = agent->getCreatureTemplate();

		if (creatureTemplate == nullptr)
			return false;

		const String& templateName = creatureTemplate->getTemplateName();

		if (templateName == "training_dummy_raw") {
			profileLabel = "Dummy - Raw";
			profileDescription = "Armor 0 | No resistances | Raw output baseline";
		} else if (templateName == "training_dummy_standard") {
			profileLabel = "Dummy - Standard";
			profileDescription = "Armor 1 | Mercenary Sentry defenses";
		} else if (templateName == "training_dummy_acklay") {
			profileLabel = "Dummy - Acklay";
			profileDescription = "Armor 2 | Geo Lab Acklay defenses";
		} else if (templateName == "training_dummy_krayt") {
			profileLabel = "Dummy - Canyon Krayt";
			profileDescription = "Armor 3 | Canyon Krayt defenses";
		} else if (templateName == "training_dummy_jedi_hunter") {
			profileLabel = "Dummy - Jedi Hunter";
			profileDescription = "Armor 3 | Resists 90 | Lightsaber 40 | jk_hunt_bh PvP profile";
		} else {
			return false;
		}

		objectID = object->getObjectID();
		return objectID != 0;
	}

	static void showMessage(CreatureObject* player, const String& title, const String& text) {
		if (player == nullptr || player->getPlayerObject() == nullptr)
			return;

		ManagedReference<SuiMessageBox*> box = new SuiMessageBox(player, SuiWindowType::NONE);
		box->setPromptTitle(title);
		box->setPromptText(text);
		box->setOkButton(true, "@ok");

		player->getPlayerObject()->addSuiBox(box);
		player->sendMessage(box->generateMessage());
	}

	static void sendArmedMessage(CreatureObject* player, uint64 durationMillis,
		uint64 targetObjectID = 0, const String& targetLabel = "",
		const String& targetProfile = "") {
		if (player == nullptr)
			return;

		StringBuffer message;
		message << "DPS " << getDurationLabel(durationMillis) << " test armed";

		if (targetObjectID != 0)
			message << " and locked to " << targetLabel;

		message << ". Timing begins with your first credited damage event and ends automatically.";
		player->sendSystemMessage(message.toString());
	}

	static void showHelp(CreatureObject* player) {
		StringBuffer help;
		help << "Use the DPS meter to run bounded outgoing-damage tests anywhere on the server.\n\n";
		help << "/dps - Open the DPS menu\n";
		help << "/dps start 1 - Arm a 1-minute test\n";
		help << "/dps start 5 - Arm a 5-minute test\n";
		help << "/dps 1 or /dps 5 - Duration shortcuts\n";
		help << "/dps stop - Stop early and view results\n";
		help << "/dps status - View current or last results\n";
		help << "/dps reset - Restart the same test duration\n";
		help << "/dps updates on|off - Toggle true 10-second progress updates\n\n";
		help << "The test is only armed until the first successful credited damage event. "
			 << "That first event starts the clock and produces a confirmation message. "
			 << "The test then ends automatically after 1 or 5 minutes. Your own damage, "
			 << "creature-pet damage, combat-droid damage, and supported damage-over-time ticks are tracked separately.\n\n";
		help << "When a Training Dummy is selected before starting the test, the session is locked "
			 << "to that exact dummy. Damage dealt to any other target is ignored. Starting without "
			 << "a Training Dummy selected continues to run a normal freeform DPS test.\n\n";
		help << "Results include sustained DPS, best completed 10-second DPS, average damage event, "
			 << "events per second, owner percentages, and direct-versus-DOT percentages.";

		showMessage(player, "DPS Meter Help", help.toString());
	}

	static bool startTimedSession(CreatureObject* player, uint64 durationMillis,
		uint64 targetObjectID = 0, const String& targetLabel = "",
		const String& targetProfile = "") {
		DpsSessionManager* manager = DpsSessionManager::instance();

		if (manager == nullptr || player == nullptr)
			return false;

		if (!manager->startSession(player, false, targetObjectID, durationMillis,
			targetLabel, targetProfile)) {
			player->sendSystemMessage("You already have an active DPS test. Stop or reset it before starting another.");
			return false;
		}

		sendArmedMessage(player, durationMillis, targetObjectID, targetLabel,
			targetProfile);
		return true;
	}

	static void showMenu(CreatureObject* player, SceneObject* selectedObject = nullptr);
};

class DpsSessionSuiCallback : public SuiCallback {
public:
	DpsSessionSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox() || eventIndex == 1)
			return;

		// HANDLESINGLEBUTTON returns the selected list row in args[0].
		if (args == nullptr || args->size() < 1)
			return;

		int selectedIndex = -1;

		try {
			selectedIndex = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			player->error("Invalid selection sent to DpsSessionSuiCallback.");
			return;
		}

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);

		if (listBox == nullptr || selectedIndex < 0 || selectedIndex >= listBox->getMenuSize())
			return;

		uint64 action = listBox->getMenuObjectID(selectedIndex);
		DpsSessionManager* manager = DpsSessionManager::instance();

		if (manager == nullptr)
			return;

		uint64 selectedDummyID = 0;
		String selectedDummyLabel;
		String selectedDummyProfile;
		ManagedReference<SceneObject*> usingObject = suiBox->getUsingObject().get();
		DpsCommandUi::getTrainingDummyInfo(usingObject, selectedDummyID,
			selectedDummyLabel, selectedDummyProfile);

		switch (action) {
		case DpsCommandUi::START_ONE_MINUTE:
			DpsCommandUi::startTimedSession(player, DpsSessionManager::ONE_MINUTE_MILLIS,
				selectedDummyID, selectedDummyLabel, selectedDummyProfile);
			break;
		case DpsCommandUi::START_FIVE_MINUTES:
			DpsCommandUi::startTimedSession(player, DpsSessionManager::FIVE_MINUTES_MILLIS,
				selectedDummyID, selectedDummyLabel, selectedDummyProfile);
			break;
		case DpsCommandUi::STOP_SESSION: {
			String report;

			if (manager->stopSession(player, report))
				DpsCommandUi::showMessage(player, "DPS Session Results", report);
			else
				player->sendSystemMessage("You do not have an active DPS test.");
			break;
		}
		case DpsCommandUi::VIEW_STATUS:
			DpsCommandUi::showMessage(player, "DPS Session Status", manager->getStatusReport(player));
			break;
		case DpsCommandUi::RESTART_SESSION: {
			if (manager->restartSession(player)) {
				uint64 durationMillis = manager->getConfiguredDurationMillis(player);
				uint64 targetObjectID = 0;
				String targetLabel;
				String targetProfile;
				manager->getSessionTargetInfo(player, targetObjectID, targetLabel,
					targetProfile);
				DpsCommandUi::sendArmedMessage(player, durationMillis, targetObjectID,
					targetLabel, targetProfile);
			}
			break;
		}
		case DpsCommandUi::TOGGLE_UPDATES: {
			bool enabled = !manager->getLiveUpdates(player);
			manager->setLiveUpdates(player, enabled);
			player->sendSystemMessage(enabled ?
				"DPS progress updates enabled. Active timed tests will report every 10 seconds." :
				"DPS progress updates disabled.");
			break;
		}
		case DpsCommandUi::SHOW_HELP:
			DpsCommandUi::showHelp(player);
			break;
		default:
			break;
		}
	}
};

inline void DpsCommandUi::showMenu(CreatureObject* player, SceneObject* selectedObject) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	DpsSessionManager* manager = DpsSessionManager::instance();

	if (manager == nullptr)
		return;

	bool active = manager->hasActiveSession(player);
	bool updates = manager->getLiveUpdates(player);
	uint64 configuredDuration = manager->getConfiguredDurationMillis(player);
	uint64 selectedDummyID = 0;
	String selectedDummyLabel;
	String selectedDummyProfile;
	bool hasSelectedDummy = !active &&
		getTrainingDummyInfo(selectedObject, selectedDummyID, selectedDummyLabel,
			selectedDummyProfile);

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
	box->setPromptTitle("DPS Meter");
	box->setUsingObject(hasSelectedDummy ? selectedObject : player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");
	box->setCallback(new DpsSessionSuiCallback(player->getZoneServer()));

	StringBuffer prompt;
	prompt << "Run a bounded DPS test using final outgoing damage after normal target mitigation.\n";
	prompt << "Session: " << (active ? "ACTIVE / ARMED" : "INACTIVE") << "\n";

	if (active)
		prompt << "Configured test: " << getDurationLabel(configuredDuration) << "\n";
	else if (hasSelectedDummy)
		prompt << "Selected target: " << selectedDummyLabel << "\n";
	else
		prompt << "Mode: Freeform outgoing damage\n";

	prompt << "10-second updates: " << (updates ? "ON" : "OFF") << "\n\n";
	prompt << "Select an action:";
	box->setPromptText(prompt.toString());

	if (active) {
		box->addMenuItem("Stop Early and View Results", STOP_SESSION);
		box->addMenuItem("View Current Status", VIEW_STATUS);
		box->addMenuItem("Restart Same Timed Test", RESTART_SESSION);
	} else {
		box->addMenuItem(hasSelectedDummy ?
			"Start 1-Minute Test Against Selected Dummy" : "Start 1-Minute DPS Test", START_ONE_MINUTE);
		box->addMenuItem(hasSelectedDummy ?
			"Start 5-Minute Test Against Selected Dummy" : "Start 5-Minute DPS Test", START_FIVE_MINUTES);
		box->addMenuItem("View Last Session", VIEW_STATUS);
	}

	box->addMenuItem(updates ? "Disable 10-Second Updates" : "Enable 10-Second Updates", TOGGLE_UPDATES);
	box->addMenuItem("Help and Command List", SHOW_HELP);

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

class DpsCommand : public QueueCommand {
public:
	DpsCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* player, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(player))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(player))
			return INVALIDLOCOMOTION;

		if (player == nullptr || !player->isPlayerCreature() || player->getPlayerObject() == nullptr)
			return GENERALERROR;

		DpsSessionManager* manager = DpsSessionManager::instance();

		if (manager == nullptr)
			return GENERALERROR;

		ManagedReference<SceneObject*> selectedObject = nullptr;
		uint64 selectedTargetID = target;

		// Slash commands do not always receive the client's selected target as
		// their target argument. Fall back to the player's current target ID.
		if (selectedTargetID == 0)
			selectedTargetID = player->getTargetID();

		if (selectedTargetID != 0 && server->getZoneServer() != nullptr)
			selectedObject = server->getZoneServer()->getObject(selectedTargetID);

		uint64 selectedDummyID = 0;
		String selectedDummyLabel;
		String selectedDummyProfile;
		DpsCommandUi::getTrainingDummyInfo(selectedObject, selectedDummyID,
			selectedDummyLabel, selectedDummyProfile);

		String argumentString = arguments.toString().trim().toLowerCase();

		if (argumentString.isEmpty()) {
			DpsCommandUi::showMenu(player, selectedObject);
			return SUCCESS;
		}

		StringTokenizer tokenizer(argumentString);
		String action;
		tokenizer.getStringToken(action);

		if (action == "1" || action == "1m" || action == "one") {
			DpsCommandUi::startTimedSession(player, DpsSessionManager::ONE_MINUTE_MILLIS,
				selectedDummyID, selectedDummyLabel, selectedDummyProfile);
		} else if (action == "5" || action == "5m" || action == "five") {
			DpsCommandUi::startTimedSession(player, DpsSessionManager::FIVE_MINUTES_MILLIS,
				selectedDummyID, selectedDummyLabel, selectedDummyProfile);
		} else if (action == "start") {
			String durationToken;

			if (tokenizer.hasMoreTokens())
				tokenizer.getStringToken(durationToken);

			if (durationToken.isEmpty() || durationToken == "1" || durationToken == "1m" || durationToken == "one") {
				DpsCommandUi::startTimedSession(player, DpsSessionManager::ONE_MINUTE_MILLIS,
				selectedDummyID, selectedDummyLabel, selectedDummyProfile);
			} else if (durationToken == "5" || durationToken == "5m" || durationToken == "five") {
				DpsCommandUi::startTimedSession(player, DpsSessionManager::FIVE_MINUTES_MILLIS,
				selectedDummyID, selectedDummyLabel, selectedDummyProfile);
			} else {
				player->sendSystemMessage("Invalid DPS duration. Use /dps start 1 or /dps start 5.");
				return INVALIDPARAMETERS;
			}
		} else if (action == "stop") {
			String report;

			if (manager->stopSession(player, report))
				DpsCommandUi::showMessage(player, "DPS Session Results", report);
			else
				player->sendSystemMessage("You do not have an active DPS test.");
		} else if (action == "status") {
			DpsCommandUi::showMessage(player, "DPS Session Status", manager->getStatusReport(player));
		} else if (action == "reset" || action == "restart") {
			if (manager->restartSession(player)) {
				uint64 durationMillis = manager->getConfiguredDurationMillis(player);
				uint64 targetObjectID = 0;
				String targetLabel;
				String targetProfile;
				manager->getSessionTargetInfo(player, targetObjectID, targetLabel,
					targetProfile);
				DpsCommandUi::sendArmedMessage(player, durationMillis, targetObjectID,
					targetLabel, targetProfile);
			}
		} else if (action == "updates") {
			String setting;

			if (tokenizer.hasMoreTokens())
				tokenizer.getStringToken(setting);

			bool enabled;

			if (setting == "on")
				enabled = true;
			else if (setting == "off")
				enabled = false;
			else
				enabled = !manager->getLiveUpdates(player);

			manager->setLiveUpdates(player, enabled);
			player->sendSystemMessage(enabled ?
				"DPS progress updates enabled. Active timed tests will report every 10 seconds." :
				"DPS progress updates disabled.");
		} else if (action == "help") {
			DpsCommandUi::showHelp(player);
		} else {
			player->sendSystemMessage("Unknown DPS option. Use /dps help for the command list.");
			return INVALIDPARAMETERS;
		}

		return SUCCESS;
	}
};

#endif /* DPSCOMMAND_H_ */
