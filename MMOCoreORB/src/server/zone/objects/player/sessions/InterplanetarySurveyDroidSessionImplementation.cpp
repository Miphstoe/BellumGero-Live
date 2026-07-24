#include "server/zone/objects/player/sessions/InterplanetarySurveyDroidSession.h"
#include "server/zone/managers/resource/ResourceManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/scene/SessionFacadeType.h"
#include "server/zone/objects/tangible/tool/SurveyTool.h"
#include "server/zone/objects/player/sessions/sui/SurveyDroidSessionSuiCallback.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/tangible/component/Component.h"
#include "server/zone/managers/resource/InterplanetarySurvey.h"
#include "server/zone/managers/resource/InterplanetarySurveyTask.h"
#include "server/zone/objects/resource/ResourceSpawn.h"

// Minimum time a player must wait between planetary survey droid hotspot scan requests.
static const uint64 PLANETARY_SURVEY_DROID_SCAN_COOLDOWN = 15 * 60 * 1000; // 15 minutes

int InterplanetarySurveyDroidSessionImplementation::cancelSession() {
	ManagedReference<CreatureObject*> player = this->player.get();
	if (player != nullptr) {
		player->dropActiveSession(SessionFacadeType::INTERPLANETARYSURVEYDROID);
		player->getPlayerObject()->removeSuiBoxType(SuiWindowType::SURVERY_DROID_MENU);
	}

	clearSession();

	return 0;
}

bool InterplanetarySurveyDroidSessionImplementation::hasSurveyTool() {
	ManagedReference<CreatureObject*> player = this->player.get();

	if (player == nullptr)
		return false;

	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");

	if (inventory == nullptr)
		return false;

	Locker inventoryLocker(inventory);

	for (int i = 0; i < inventory->getContainerObjectsSize(); ++i) {
		ManagedReference<SceneObject*> sceno = inventory->getContainerObject(i);

		uint32 objType = sceno->getGameObjectType();

		if (objType == SceneObjectType::SURVEYTOOL) {
			return true;
		}
	}

	return false;
}

void InterplanetarySurveyDroidSessionImplementation::initalizeDroid(TangibleObject* droid) {
	droidObject = droid;
	ManagedReference<CreatureObject*> player = this->player.get();

	// Scan cooldown: prevents spamming hotspot scan requests from this (or any) survey droid
	if (!player->getCooldownTimerMap()->isPast("planetary_survey_droid_scan")) {
		player->sendSystemMessage("The survey droid's scanner is still recalibrating. Please try again later.");
		cancelSession();
		return;
	}

	if (!hasSurveyTool()) {
		player->sendSystemMessage("@pet/droid_modules:survey_no_survey_tools");
		cancelSession();
		return;
	}

	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");

	if (inventory == nullptr) {
		cancelSession();
		return;
	}

	Locker invLocker(inventory);

	// fire up sui box
	droidSuiBox = new SuiListBox(player, SuiWindowType::SURVERY_DROID_MENU, 2);
	droidSuiBox->setPromptTitle("@pet/droid_modules:survey_select_tool_title");
	droidSuiBox->setPromptText("@pet/droid_modules:survey_select_tool_prompt");
	droidSuiBox->setUsingObject(droid);
	droidSuiBox->setCallback(new SurveyDroidSessionSuiCallback(player->getZoneServer()));

	for (int i = 0; i < inventory->getContainerObjectsSize(); ++i) {
		ManagedReference<SceneObject*> sceno = inventory->getContainerObject(i);
		uint32 objType = sceno->getGameObjectType();

		if (objType == SceneObjectType::SURVEYTOOL) {
			droidSuiBox->addMenuItem(sceno->getDisplayedName(), sceno->getObjectID());
		}
	}

	step = 1;
	droidSuiBox->setCancelButton(true, "@cancel");
	player->getPlayerObject()->addSuiBox(droidSuiBox);
	player->sendMessage(droidSuiBox->generateMessage());
}

void InterplanetarySurveyDroidSessionImplementation::handleMenuSelect(CreatureObject* pl, uint64 menuID, SuiListBox* suiBox) {
	ManagedReference<CreatureObject*> player = this->player.get();
	ManagedReference<TangibleObject*> tangibleObject = this->droidObject.get();

	if (tangibleObject == nullptr || player == nullptr || player != pl)
		return;

	// which did he pick? first or second callback?
	if (step == 1) {
		// Get the id back
		uint64 chosen = droidSuiBox->getMenuObjectID(menuID);
		ManagedReference<SceneObject*> obj = pl->getZoneServer()->getObject(chosen);

		if (obj == nullptr) {
			player->sendSystemMessage("@pet/droid_modules:survey_no_survey_tools");
			cancelSession();
			return;
		}

		Locker toolLock(obj);

		SurveyTool* tool = cast<SurveyTool*>(obj.get());

		if (tool == nullptr) {
			player->sendSystemMessage("@pet/droid_modules:survey_no_survey_tools");
			cancelSession();
			return;
		}

		setTool(tool);

		// reset title and prompt and menu
		droidSuiBox->removeAllMenuItems();
		droidSuiBox->setPromptTitle("@pet/droid_modules:survey_planet_title");
		droidSuiBox->setPromptText("@pet/droid_modules:survey_planet_prompt");

		// Loop planets and add them in
		pl->getZoneServer()->getResourceManager()->addPlanetsToListBox(droidSuiBox);
		player->getPlayerObject()->addSuiBox(droidSuiBox);
		player->sendMessage(droidSuiBox->generateMessage());
		step = 2;
	} else if (step == 2) {
		// Picked planet. Next, let the player narrow the scan to a specific active resource
		// in this droid's category, or auto-select the strongest match on report.
		ManagedReference<SurveyTool*> tool = this->toolObject.get();

		if (tool == nullptr) {
			cancelSession();
			return;
		}

		uint64 chosen = droidSuiBox->getMenuObjectID(menuID);
		this->targetPlanet = pl->getZoneServer()->getResourceManager()->getPlanetByIndex(chosen);

		// Pull the list of currently active (in-shift) resources matching this droid's
		// survey category on the chosen planet -- this is the resource concentration
		// lookup entry point (ResourceManager -> ResourceSpawner -> ZoneResourceMap).
		Vector<ManagedReference<ResourceSpawn*> > resources;
		pl->getZoneServer()->getResourceManager()->getResourceListByType(resources, tool->getToolType(), targetPlanet);

		if (resources.size() == 0) {
			player->sendSystemMessage("No active resources of that type were found on " + targetPlanet + ".");
			cancelSession();
			return;
		}

		droidSuiBox->removeAllMenuItems();
		droidSuiBox->setPromptTitle("Select Resource");
		droidSuiBox->setPromptText("Select a specific resource to scan for concentration hotspots, or let the droid automatically pick the strongest match.");
		droidSuiBox->addMenuItem("Best Match (Auto-Select)", 0);

		for (int i = 0; i < resources.size(); ++i) {
			ManagedReference<ResourceSpawn*> spawn = resources.get(i);
			droidSuiBox->addMenuItem(spawn->getName(), spawn->_getObjectID());
		}

		player->getPlayerObject()->addSuiBox(droidSuiBox);
		player->sendMessage(droidSuiBox->generateMessage());
		step = 3;
	} else {
		// Picked resource (or auto-select) -- schedule the hotspot scan.
		ManagedReference<SurveyTool*> tool = this->toolObject.get();

		if (tool == nullptr) {
			cancelSession();
			return;
		}

		Locker toolLocker(tool);
		Locker droidLocker(tangibleObject);

		Component* component = dynamic_cast<Component*>(tangibleObject.get());

		if (component == nullptr) {
			cancelSession();
			return;
		}

		float quality = component->getAttributeValue("mechanism_quality");
		uint64 chosen = droidSuiBox->getMenuObjectID(menuID);

		// chosen == 0 is the "Best Match (Auto-Select)" sentinel -- an empty resourceName
		// tells the report task to scan every matching resource and pick the best hotspot.
		String resourceName;

		if (chosen != 0) {
			ManagedReference<SceneObject*> resObj = pl->getZoneServer()->getObject(chosen);
			ResourceSpawn* spawn = cast<ResourceSpawn*>(resObj.get());

			if (spawn != nullptr)
				resourceName = spawn->getName();
		}

		int duration = 1000 * (3600 - (27 * quality));
		int minutes = duration/60000;

		StringBuffer buffer;
		buffer << "Droid sent, ETA for the report is ";
		buffer << minutes;
		buffer << " minutes.";
		pl->sendSystemMessage(buffer.toString());

		// Create a bogus task to run to show the output to the console
		ManagedReference<InterplanetarySurvey*> data = new InterplanetarySurvey();
		Time expireTime;
		uint64 currentTime = expireTime.getMiliTime();

		// TEst case: add this for the future and persist it.
		data->setPlanet(this->targetPlanet);
		data->setSurveyToolType(tool->getToolType());
		data->setRequestor(pl->getFirstName());
		data->setCurTime(currentTime);
		data->setTimeStamp(duration);
		data->setSurveyType(tool->getSurveyType());
		data->setResourceName(resourceName);

		Reference<InterplanetarySurveyTask*> task = new InterplanetarySurveyTask(data.get());
		task->schedule(duration); // remove the tools form the world

		ObjectManager::instance()->persistObject(data, 1, "surveys");

		tool->destroyObjectFromWorld(true);
		tool->destroyObjectFromDatabase(true);

		tangibleObject->decreaseUseCount();

		// Start the scan cooldown now that a scan has actually been queued
		player->getCooldownTimerMap()->updateToCurrentAndAddMili("planetary_survey_droid_scan", PLANETARY_SURVEY_DROID_SCAN_COOLDOWN);

		cancelSession();
	}
}
