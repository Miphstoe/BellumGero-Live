#ifndef SELECTPERFORMANCESUICALLBACK_H
#define SELECTPERFORMANCESUICALLBACK_H

#include "server/zone/objects/player/sui/SuiCallback.h"

class SelectPerformanceSuiCallback : public SuiCallback {
	int performanceType;
	bool bandCommand;
	uint64 instrumentID;
public:
	SelectPerformanceSuiCallback(ZoneServer* server, int type, bool bandCmd, uint64 instrID = 0)
		: SuiCallback(server) {
		performanceType = type;
		bandCommand = bandCmd;
		instrumentID = instrID;

	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (!suiBox->isListBox() || cancelPressed)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);
		int index = Integer::valueOf(args->get(0).toString());

		if (listBox == nullptr || index < 0 || index >= listBox->getMenuSize()) {
			if (performanceType == PerformanceType::MUSIC)
				player->sendSystemMessage("@performance:music_invalid_song"); // That is not a valid song name.
			else if (performanceType == PerformanceType::DANCE)
				player->sendSystemMessage("@performance:dance_unknown_self"); // You do not know that dance.

			return;
		}

		String performanceName = listBox->getMenuItemName(index);

		if (performanceType == PerformanceType::MUSIC) {
			if (player->isPlayingMusic()) {
				if (bandCommand)
					player->executeObjectControllerAction(STRING_HASHCODE("changebandmusic"), instrumentID, performanceName);
				else
					player->executeObjectControllerAction(STRING_HASHCODE("changemusic"), instrumentID, performanceName);
			} else {
				if (bandCommand)
					player->executeObjectControllerAction(STRING_HASHCODE("startband"), instrumentID, performanceName);
				else
					player->executeObjectControllerAction(STRING_HASHCODE("startmusic"), instrumentID, performanceName);
			}
		} else if (performanceType == PerformanceType::DANCE) {
			if (player->isDancing()) {
				player->executeObjectControllerAction(STRING_HASHCODE("changedance"), 0, performanceName);
			} else {
				player->executeObjectControllerAction(STRING_HASHCODE("startdance"), 0, performanceName);
			}
		}
	}
};

#endif /* SELECTPERFORMANCESUICALLBACK_H */
