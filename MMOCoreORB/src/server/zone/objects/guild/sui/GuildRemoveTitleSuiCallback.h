/*
 * GuildRemoveTitleSuiCallback.h
 *
 *  Created on: Jan 11, 2026
 *      Author: BellumGero
 */

#ifndef GUILDREMOVETITLESUICALLBACK_H_
#define GUILDREMOVETITLESUICALLBACK_H_

#include "server/zone/managers/guild/GuildManager.h"
#include "server/zone/objects/player/sui/SuiCallback.h"

class GuildRemoveTitleSuiCallback : public SuiCallback {
public:
	GuildRemoveTitleSuiCallback(ZoneServer* server)
		: SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {

		bool cancelPressed = (eventIndex == 1);
		if (!suiBox->isMessageBox() || cancelPressed)
			return;

		ManagedReference<GuildManager*> guildManager = server->getGuildManager();

		if (guildManager == nullptr)
			return;

		ManagedReference<SceneObject*> obj = suiBox->getUsingObject().get();

		if (obj == nullptr || !obj->isPlayerCreature())
			return;

		CreatureObject* target = cast<CreatureObject*>( obj.get());

		// Remove title by setting it to an empty string
		guildManager->setMemberTitle(player, target, "");
	}
};

#endif /* GUILDREMOVETITLESUICALLBACK_H_ */
