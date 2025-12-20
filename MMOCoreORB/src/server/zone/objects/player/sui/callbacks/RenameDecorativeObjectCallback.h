/*
 * RenameDecorativeObjectCallback.h
 *
 * SuiCallback for renaming decorative objects (furniture, paintings)
 * Includes profanity filtering and permission validation
 */

#ifndef RENAMEDECORATIVEOBJECTCALLBACK_H_
#define RENAMEDECORATIVEOBJECTCALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/managers/name/NameManager.h"
#include "server/zone/objects/tangible/components/TangibleObjectMenuComponent.h"
#include "server/zone/ZoneProcessServer.h"

class RenameDecorativeObjectCallback : public SuiCallback {
public:
	RenameDecorativeObjectCallback(ZoneServer* serv) : SuiCallback(serv) {
	}

	void run(CreatureObject* player, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		// Cancel pressed or invalid input
		if (!sui->isInputBox() || eventIndex == 1 || args->size() < 1)
			return;

		// Get object being renamed
		ManagedReference<SceneObject*> object = sui->getUsingObject().get();
		if (object == nullptr || !object->isTangibleObject())
			return;

		auto tano = object.castTo<TangibleObject*>();
		if (tano == nullptr || !tano->isDecorativeObject())
			return;

		// Get new name
		UnicodeString newName = args->get(0);
		String nameString = newName.toString();

		// Profanity filtering (skip for empty names)
		if (!nameString.isEmpty()) {
			ZoneProcessServer* zps = player->getZoneProcessServer();
			if (zps == nullptr)
				return;

			NameManager* nameManager = zps->getNameManager();
			if (nameManager == nullptr)
				return;

			// Validate with profanity filter
			int result = nameManager->checkNamingFilter(nameString);

			if (result != NameManagerResult::ACCEPTED) {
				// Send error message based on rejection reason
				switch (result) {
					case NameManagerResult::DECLINED_PROFANE:
						player->sendSystemMessage("@ui:name_declined_profane");
						break;
					case NameManagerResult::DECLINED_DEVELOPER:
						player->sendSystemMessage("@ui:name_declined_developer");
						break;
					case NameManagerResult::DECLINED_RESERVED:
						player->sendSystemMessage("@ui:name_declined_reserved");
						break;
					case NameManagerResult::DECLINED_FICT_RESERVED:
						player->sendSystemMessage("@ui:name_declined_fictionally_reserved");
						break;
					default:
						player->sendSystemMessage("@ui:name_declined_syntax");
						break;
				}
				return;
			}
		}

		// Re-check permissions at callback time (security!)
		if (!TangibleObjectMenuComponent::hasRenamePermission(player, tano)) {
			player->sendSystemMessage("You no longer have permission to rename this object.");
			return;
		}

		// Set the name
		Locker objLock(tano, player);
		tano->setCustomObjectName(newName, true);

		// Success message
		if (nameString.isEmpty()) {
			player->sendSystemMessage("Object name cleared.");
		} else {
			StringIdChatParameter params("@player_structure:rename_success");
			params.setTO(newName);
			player->sendSystemMessage(params);
		}
	}
};

#endif /* RENAMEDECORATIVEOBJECTCALLBACK_H_ */
