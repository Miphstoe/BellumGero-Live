#ifndef WORLDBUILDERTRAVELPOINTEDITOR_H_
#define WORLDBUILDERTRAVELPOINTEDITOR_H_

#include "server/zone/managers/worldbuilder/WorldBuilderManager.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"

class WorldBuilderTravelPointEditor;

class WorldBuilderTravelPointInputCallback : public SuiCallback {
	int action;
public:
	WorldBuilderTravelPointInputCallback(ZoneServer* server, int value) : SuiCallback(server), action(value) {}
	void run(CreatureObject* player, SuiBox* box, uint32 eventIndex, Vector<UnicodeString>* args);
};

class WorldBuilderTravelPointListCallback : public SuiCallback {
public:
	WorldBuilderTravelPointListCallback(ZoneServer* server) : SuiCallback(server) {}
	void run(CreatureObject* player, SuiBox* box, uint32 eventIndex, Vector<UnicodeString>* args);
};

class WorldBuilderTravelPointEditor {
public:
	enum Action { STATUS=0, RENAME=1, ARRIVAL=2, INCOMING=3, INTERPLANETARY=4, RANGE=5, REMOVE=6, BACK=7 };
	static void show(CreatureObject* player) {
		WorldBuilderManager* manager = WorldBuilderManager::instance();
		WorldBuilderTravelPointState point; bool exists = false; String message;
		if (!manager->getSelectedTravelPoint(player, point, exists, message)) {
			player->sendSystemMessage("[World Builder] ERROR: " + message); return;
		}
		ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
		box->setPromptTitle("Travel Point / Selected Shuttleport");
		StringBuffer status;
		if (!exists) status << "No Travel Point. Create one by naming it.";
		else status << point.pointName << "\nArrival x/z/y: " << point.x << " / " << point.z << " / " << point.y
			<< "\nIncoming: " << (point.incomingTravelAllowed ? "Yes" : "No")
			<< " | Interplanetary: " << (point.interplanetaryTravelAllowed ? "Yes" : "No")
			<< " | Landing range: " << point.landingRange << "m";
		box->setPromptText(status.toString()); box->setUsingObject(player); box->setCancelButton(true, "@cancel"); box->setOkButton(true, "@ok");
		box->setCallback(new WorldBuilderTravelPointListCallback(player->getZoneServer()));
		box->addMenuItem("Status", STATUS); box->addMenuItem("Create / Rename Travel Point", RENAME);
		box->addMenuItem("Set Arrival Point to My Current Position", ARRIVAL); box->addMenuItem("Toggle Incoming Travel", INCOMING);
		box->addMenuItem("Toggle Interplanetary Travel", INTERPLANETARY); box->addMenuItem("Set Landing Range", RANGE);
		box->addMenuItem("Remove Travel Point", REMOVE); box->addMenuItem("Back", BACK);
		player->getPlayerObject()->addSuiBox(box); player->sendMessage(box->generateMessage());
	}
	static void input(CreatureObject* player, int action, const String& title, const String& prompt) {
		ManagedReference<SuiInputBox*> box = new SuiInputBox(player, SuiWindowType::NONE);
		box->setPromptTitle(title); box->setPromptText(prompt); box->setUsingObject(player); box->setCancelButton(true, "@cancel"); box->setOkButton(true, "@ok");
		box->setCallback(new WorldBuilderTravelPointInputCallback(player->getZoneServer(), action));
		player->getPlayerObject()->addSuiBox(box); player->sendMessage(box->generateMessage());
	}
};

inline void WorldBuilderTravelPointInputCallback::run(CreatureObject* player, SuiBox*, uint32 eventIndex, Vector<UnicodeString>* args) {
	if (player == nullptr || eventIndex == 1 || args == nullptr || args->size() < 1) return;
	String value=args->get(0).toString(); String message; bool ok=false; WorldBuilderManager* manager=WorldBuilderManager::instance();
	try { if(action==WorldBuilderTravelPointEditor::RENAME) ok=manager->setSelectedTravelPointName(player,value,message);
		else if(action==WorldBuilderTravelPointEditor::RANGE) ok=manager->setSelectedTravelPointLandingRange(player,Float::valueOf(value),message); }
	catch(Exception&){message="Invalid value.";} player->sendSystemMessage(String("[World Builder] ")+(ok?"":"ERROR: ")+message); WorldBuilderTravelPointEditor::show(player);
}

inline void WorldBuilderTravelPointListCallback::run(CreatureObject* player, SuiBox*, uint32 eventIndex, Vector<UnicodeString>* args) {
	if(player==nullptr||eventIndex==1||args==nullptr||args->size()<1)return; int action=Integer::valueOf(args->get(0).toString()); String message; bool ok=false; WorldBuilderManager* manager=WorldBuilderManager::instance();
	if(action==WorldBuilderTravelPointEditor::RENAME){WorldBuilderTravelPointEditor::input(player,action,"Create / Rename Travel Point","Enter the destination name:");return;}
	if(action==WorldBuilderTravelPointEditor::RANGE){WorldBuilderTravelPointEditor::input(player,action,"Landing Range","Enter 0.5 through 64 meters:");return;}
	if(action==WorldBuilderTravelPointEditor::ARRIVAL)ok=manager->setSelectedTravelPointArrival(player,message);
	else if(action==WorldBuilderTravelPointEditor::INCOMING)ok=manager->toggleSelectedTravelPointIncoming(player,message);
	else if(action==WorldBuilderTravelPointEditor::INTERPLANETARY)ok=manager->toggleSelectedTravelPointInterplanetary(player,message);
	else if(action==WorldBuilderTravelPointEditor::REMOVE)ok=manager->removeSelectedTravelPoint(player,message);
	else if(action==WorldBuilderTravelPointEditor::BACK)return;
	else {ok=true;message="Status refreshed.";}
	player->sendSystemMessage(String("[World Builder] ")+(ok?"":"ERROR: ")+message); WorldBuilderTravelPointEditor::show(player);
}

#endif
