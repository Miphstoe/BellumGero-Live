/*
 * Bellum Gero — /housepackinfo
 *
 * Read-only administrator diagnostic for the House Pack-Up system. Reports the
 * current transactional state of a packed structure/deed (state, expected
 * item count, original structure, pack timestamp, and whether the manifest is
 * stored in the new persisted format or an old-format legacy payload) without
 * ever modifying, restoring, or deleting anything.
 *
 * Usage: target a StructureDeed or a placed BuildingObject and run
 * "/housepackinfo", or pass an object ID explicitly: "/housepackinfo <oid>".
 */

#ifndef HOUSEPACKINFOCOMMAND_H_
#define HOUSEPACKINFOCOMMAND_H_

#include "server/zone/objects/creature/commands/QueueCommand.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/managers/housepackup/HousePackupManager.h"
#include "server/zone/managers/object/ObjectManager.h"
#include "server/zone/ZoneServer.h"

#include <ctime>

class HousePackInfoCommand : public QueueCommand {
public:
	HousePackInfoCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (creature == nullptr || !creature->isPlayerCreature())
			return GENERALERROR;

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		PlayerObject* ghost = creature->getPlayerObject();

		if (ghost == nullptr || ghost->getAdminLevel() < 15) {
			creature->sendSystemMessage("You do not have access to this command.");
			return GENERALERROR;
		}

		uint64 oid = target;

		if (oid == 0) {
			StringTokenizer tokenizer(arguments.toString());

			if (tokenizer.hasMoreTokens()) {
				try {
					oid = tokenizer.getUnsignedLongToken();
				} catch (...) {
					oid = 0;
				}
			}
		}

		if (oid == 0) {
			creature->sendSystemMessage("Syntax: target a packed deed or structure and use /housepackinfo, or /housepackinfo <objectID>");
			return GENERALERROR;
		}

		ManagedReference<SceneObject*> sceneObj = server->getZoneServer()->getObject(oid);

		// Diagnostics must work even for a deed sitting untouched in an
		// offline player's inventory (never loaded into RAM this session) --
		// fall back to loading it directly from its Berkeley DB row, exactly
		// like the fixed restoreFromDeed() does for packed items themselves.
		// Strictly read-only: nothing about the loaded object is mutated,
		// re-parented, or saved back.
		if (sceneObj == nullptr) {
			Reference<DistributedObjectStub*> stub = ObjectManager::instance()->loadPersistentObject(oid);
			sceneObj = (stub != nullptr) ? cast<SceneObject*>(stub.get()) : nullptr;
		}

		if (sceneObj == nullptr) {
			creature->sendSystemMessage("No object found for ID " + String::valueOf((int64) oid) + ".");
			return GENERALERROR;
		}

		HousePackupManager::PackDiagnostics diag = HousePackupManager::instance()->getPackDiagnostics(sceneObj.get());

		if (!diag.found) {
			creature->sendSystemMessage("Object " + String::valueOf((int64) oid) +
				" is not a structure deed or building, or has never been part of a House Pack-Up operation.");
			return SUCCESS;
		}

		StringBuffer body;
		body << "House Pack Diagnostic" << endl << endl;
		body << "Object: " << oid << (diag.isDeed ? " (Deed)" : " (Structure)") << endl;
		body << "State: " << stateName(diag.isDeed, diag.packState) << endl;

		if (diag.isDeed)
			body << "Original Structure: " << diag.originalStructureID << endl;

		body << "Expected Objects: " << diag.itemCount << endl;

		if (diag.timestamp > 0) {
			Time packTime((uint32) diag.timestamp);
			body << "Packed: " << packTime.getFormattedTime() << endl;
		} else {
			body << "Packed: <unknown>" << endl;
		}

		body << "Payload Storage: " << (diag.hasPayload ? "current (persisted on object)" :
			(diag.legacyPayload ? "LEGACY (pre-fix RAM/disk payload -- migrates automatically on next restore)" : "none")) << endl;

		if (diag.packState == 1 /* PACKING, building-only enum value */ && !diag.isDeed) {
			body << endl << "WARNING: state is PACKING. This normally only happens while a pack" << endl;
			body << "operation is actively running. If this persists with no pack in progress," << endl;
			body << "the server may have crashed mid-operation -- investigate before taking any action." << endl;
		}

		if (diag.isDeed && diag.packState == 4 /* PARTIAL */) {
			body << endl << "WARNING: a prior restore attempt on this deed was INCOMPLETE." << endl;
			body << "Check the server log for [HOUSEPACK ERROR] entries for this deed and the" << endl;
			body << "housepacks/unresolved-" << oid << ".txt recovery file before taking any action." << endl;
		}

		ManagedReference<SuiMessageBox*> box = new SuiMessageBox(creature, 0);
		box->setPromptTitle("House Pack Diagnostic");
		box->setPromptText(body.toString());
		box->setOkButton(true, "@ok");
		box->setUsingObject(creature);

		creature->sendMessage(box->generateMessage());

		return SUCCESS;
	}

private:
	static String stateName(bool isDeed, int state) {
		if (isDeed) {
			switch (state) {
				case 0: return "NONE";
				case 1: return "PACKED";
				case 2: return "RESTORING";
				case 3: return "CONSUMED";
				case 4: return "PARTIAL (needs review)";
				default: return "UNKNOWN(" + String::valueOf(state) + ")";
			}
		}

		switch (state) {
			case 0: return "NORMAL";
			case 1: return "PACKING";
			case 2: return "PACKED";
			default: return "UNKNOWN(" + String::valueOf(state) + ")";
		}
	}
};

#endif /* HOUSEPACKINFOCOMMAND_H_ */
