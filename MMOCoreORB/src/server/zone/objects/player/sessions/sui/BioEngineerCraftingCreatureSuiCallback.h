/*
 * BioEngineerCraftingCreatureSuiCallback.h
 *
 * Handles creature selection for the dedicated
 * Bio-Engineer Creature Crafting Tool.
 */

#ifndef BIOENGINEERCRAFTINGCREATURESUICALLBACK_H_
#define BIOENGINEERCRAFTINGCREATURESUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sessions/crafting/CraftingSession.h"

class BioEngineerCraftingCreatureSuiCallback : public SuiCallback {
	int minimumLevel;

public:
	BioEngineerCraftingCreatureSuiCallback(ZoneServer* server, int minimumLevel)
		: SuiCallback(server), minimumLevel(minimumLevel) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox())
			return;

		ManagedReference<CraftingSession*> session =
			player->getActiveSession(SessionFacadeType::CRAFTING).castTo<CraftingSession*>();

		if (session == nullptr)
			return;

		Locker locker(session);

		// Cancel is used as Back on the creature list.
		if (eventIndex == 1) {
			session->openBioEngineerCategorySelection();
			return;
		}

		if (args == nullptr || args->size() < 1)
			return;

		int selectedRow = -1;

		try {
			selectedRow = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			player->error("Invalid selection sent to BioEngineerCraftingCreatureSuiCallback.");
			return;
		}

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);

		if (selectedRow < 0 || selectedRow >= listBox->getMenuSize()) {
			session->openBioEngineerCreatureSelection(minimumLevel);
			return;
		}

		int schematicIndex = static_cast<int>(listBox->getMenuObjectID(selectedRow));
		session->selectBioEngineerCreatureSchematic(schematicIndex);
	}
};

#endif /* BIOENGINEERCRAFTINGCREATURESUICALLBACK_H_ */
