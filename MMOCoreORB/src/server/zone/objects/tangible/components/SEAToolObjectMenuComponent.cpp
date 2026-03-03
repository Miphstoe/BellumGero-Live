#include "SEAToolObjectMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/callbacks/CombineSEAToolSuiCallback.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "templates/SharedObjectTemplate.h"
#include "server/zone/objects/tangible/TangibleObject.h"

namespace {
	static bool isSEATool(SceneObject* so) {
		if (!so) return false;
		SharedObjectTemplate* tmpl = so->getObjectTemplate();
		if (!tmpl) return false;
		const String full = tmpl->getFullTemplateString();
		return full.indexOf("sea_removal_tool.iff") != -1;
	}

	static void collectOtherSEATools(SceneObject* container, SceneObject* exclude,
	                                  Vector< ManagedReference<TangibleObject*> >& out) {
		if (!container) return;
		const int n = container->getContainerObjectsSize();
		for (int i = 0; i < n; ++i) {
			SceneObject* child = container->getContainerObject(i);
			if (!child || child == exclude) continue;
			if (isSEATool(child)) {
				if (TangibleObject* t = child->asTangibleObject())
					out.add(t);
			}
			if (child->isContainerObject())
				collectOtherSEATools(child, exclude, out);
		}
	}
}

void SEAToolObjectMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	if (!player) return;

	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");
	if (!inventory) return;

	Vector< ManagedReference<TangibleObject*> > others;
	collectOtherSEATools(inventory, sceneObject, others);

	if (!others.isEmpty())
		menuResponse->addRadialMenuItem(166, 3, "Combine SEA Tools");
}

int SEAToolObjectMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (selectedID != 166)
		return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);

	if (!player) return 0;

	ZoneServer* server = player->getZoneServer();
	if (!server) return 0;

	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");
	if (!inventory) return 0;

	Vector< ManagedReference<TangibleObject*> > others;
	collectOtherSEATools(inventory, sceneObject, others);

	if (others.isEmpty()) {
		player->sendSystemMessage("You have no other SEA Removal Tools to combine.");
		return 0;
	}

	ManagedReference<SuiListBox*> listBox = new SuiListBox(player, SuiWindowType::CUSTOMIZE_KIT);
	listBox->setPromptTitle("Combine SEA Tools");
	listBox->setPromptText("Select a tool to absorb into this one:");
	listBox->setUsingObject(sceneObject);
	listBox->setCallback(new CombineSEAToolSuiCallback(server));
	listBox->setCancelButton(true, "");
	listBox->setOkButton(true, "@ok");

	for (int i = 0; i < others.size(); ++i) {
		TangibleObject* t = others.get(i);
		if (!t) continue;
		int charges = t->getUseCount() > 0 ? t->getUseCount() : 1;
		String label = String("SEA Removal Tool (") + String::valueOf(charges)
		               + (charges == 1 ? " charge)" : " charges)");
		listBox->addMenuItem(label, t->getObjectID());
	}

	ManagedReference<PlayerObject*> ghost = player->getPlayerObject();
	if (ghost)
		ghost->addSuiBox(listBox);

	player->sendMessage(listBox->generateMessage());
	return 0;
}
