/*
 * BioEngineerCraftingCategorySuiCallback.h
 *
 * Handles Minimum CL category selection for the dedicated
 * Bio-Engineer Creature Crafting Tool.
 */

#ifndef BIOENGINEERCRAFTINGCATEGORYSUICALLBACK_H_
#define BIOENGINEERCRAFTINGCATEGORYSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sessions/crafting/CraftingSession.h"

class BioEngineerCraftingCategorySuiCallback : public SuiCallback {
public:
	BioEngineerCraftingCategorySuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox())
			return;

		ManagedReference<CraftingSession*> session =
			player->getActiveSession(SessionFacadeType::CRAFTING).castTo<CraftingSession*>();

		if (session == nullptr)
			return;

		Locker locker(session);

		if (eventIndex == 1) {
			session->cancelSessionCommand();
			return;
		}

		if (args == nullptr || args->size() < 1)
			return;

		int selectedRow = -1;

		try {
			selectedRow = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			player->error("Invalid selection sent to BioEngineerCraftingCategorySuiCallback.");
			return;
		}

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);

		if (selectedRow < 0 || selectedRow >= listBox->getMenuSize())
			return;

		int minimumLevel = static_cast<int>(listBox->getMenuObjectID(selectedRow));

		if (minimumLevel <= 0)
			return;

		session->openBioEngineerCreatureSelection(minimumLevel);
	}
};

#endif /* BIOENGINEERCRAFTINGCATEGORYSUICALLBACK_H_ */
