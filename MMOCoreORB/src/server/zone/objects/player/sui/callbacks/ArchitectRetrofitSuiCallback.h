/*
 * ArchitectRetrofitSuiCallback.h
 *
 * Shown to the Architect after they choose "Architect Retrofit Service" at the terminal.
 * Presents two retrofit types; after the Architect picks one:
 *   - If Architect == Owner  → applies the retrofit immediately.
 *   - If Architect != Owner  → finds the owner online and sends them a confirm/deny SUI.
 *
 * The actual application logic and file-persistence helpers live in
 * ArchitectRetrofitOwnerConfirmSuiCallback.h, which is included here.
 */

#ifndef ARCHITECTRETROFITSUICALLBACK_H_
#define ARCHITECTRETROFITSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/SuiBox.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/player/sui/callbacks/ArchitectRetrofitOwnerConfirmSuiCallback.h"

class ArchitectRetrofitSuiCallback : public SuiCallback {
public:
	ArchitectRetrofitSuiCallback(ZoneServer* server, BuildingObject* bld)
		: SuiCallback(server), building(bld) {}

	void run(CreatureObject* architect, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (architect == nullptr || sui == nullptr || cancelPressed)
			return;

		if (building == nullptr) {
			architect->sendSystemMessage("Retrofit failed: structure no longer exists.");
			return;
		}

		if (!architect->hasSkill("crafting_architect_master")) {
			architect->sendSystemMessage("You must be a Master Architect to apply the retrofit service.");
			return;
		}

		if (args == nullptr || args->size() == 0)
			return;

		int selectedIndex = Integer::valueOf(args->get(0).toString());
		if (selectedIndex < 0 || selectedIndex > 1) {
			architect->sendSystemMessage("Invalid selection.");
			return;
		}

		const String retrofitType = (selectedIndex == 0) ? "STORAGE" : "MAINTENANCE";

		// Quick pre-check (definitive check is under building lock in the apply path)
		if (ArchitectRetrofitOwnerConfirmSuiCallback::isRetrofitApplied(building->getObjectID())) {
			architect->sendSystemMessage("This structure has already received its one-time Architect retrofit.");
			return;
		}

		ManagedReference<PlayerObject*> ghost = architect->getPlayerObject();
		if (ghost == nullptr)
			return;

		// Fast path: Architect is the structure owner — no approval needed
		if (ghost->isOwnedStructure(building.get())) {
			Locker buildingLocker(building);

			if (ArchitectRetrofitOwnerConfirmSuiCallback::isRetrofitApplied(building->getObjectID())) {
				architect->sendSystemMessage("This structure has already received its one-time Architect retrofit.");
				return;
			}

			ArchitectRetrofitOwnerConfirmSuiCallback::applyRetrofit(architect, architect, building.get(), retrofitType);
			return;
		}

		// Service path: Architect is NOT the owner — find owner and request approval
		uint64 ownerID = building->getOwnerObjectID();
		ManagedReference<SceneObject*> ownerScene = server->getObject(ownerID);

		if (ownerScene == nullptr || !ownerScene->isCreatureObject()) {
			architect->sendSystemMessage("The structure owner must be online to authorize this retrofit.");
			return;
		}

		CreatureObject* owner = cast<CreatureObject*>(ownerScene.get());
		if (owner == nullptr) {
			architect->sendSystemMessage("The structure owner must be online to authorize this retrofit.");
			return;
		}

		ManagedReference<PlayerObject*> ownerGhost = owner->getPlayerObject();
		if (ownerGhost == nullptr) {
			architect->sendSystemMessage("Unable to contact the structure owner.");
			return;
		}

		// Build confirmation message for the owner with the correct lot-scaled values
		int lots = building->getLotSize();
		if (lots < 1) lots = 1;
		int storageBonus = lots * 50;

		StringBuffer confirmMsg;
		confirmMsg << "Architect " << architect->getFirstName()
		           << " is offering a one-time retrofit to your structure.\n\n";

		if (retrofitType == "STORAGE") {
			confirmMsg << "Retrofit type: Storage Expansion (+" << storageBonus
			           << " item capacity for " << lots << " lot" << (lots == 1 ? "" : "s") << ")\n\n";
		} else {
			confirmMsg << "Retrofit type: Maintenance Efficiency (25% reduction, stacks with Merchant discount up to 50% combined)\n\n";
		}

		confirmMsg << "This upgrade is permanent and cannot be reversed.\nDo you authorize this retrofit?";

		ManagedReference<SuiMessageBox*> confirmBox =
			new SuiMessageBox(owner, SuiWindowType::STRUCTURE_ARCHITECT_RETROFIT);
		confirmBox->setPromptTitle("Architect Retrofit Authorization");
		confirmBox->setPromptText(confirmMsg.toString());
		confirmBox->setUsingObject(building.get());
		confirmBox->setCancelButton(true, "@cancel");

		ArchitectRetrofitOwnerConfirmSuiCallback* confirmCallback =
			new ArchitectRetrofitOwnerConfirmSuiCallback(server, building.get(), architect, retrofitType);
		confirmBox->setCallback(confirmCallback);

		ownerGhost->addSuiBox(confirmBox);
		owner->sendMessage(confirmBox->generateMessage());

		// Tell the architect to wait
		StringBuffer waitMsg;
		waitMsg << "Retrofit request sent to " << owner->getFirstName() << ". Waiting for their approval.";
		architect->sendSystemMessage(waitMsg.toString());
	}

	// Convenience forwarder so StructureTerminalMenuComponent can check the flag
	// without having to include the owner-confirm header directly.
	static bool isRetrofitApplied(uint64 structureOID) {
		return ArchitectRetrofitOwnerConfirmSuiCallback::isRetrofitApplied(structureOID);
	}

private:
	ManagedReference<BuildingObject*> building;
};

#endif // ARCHITECTRETROFITSUICALLBACK_H_
