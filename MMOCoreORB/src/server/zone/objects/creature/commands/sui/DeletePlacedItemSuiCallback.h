#ifndef DELETEPLACEDITEMSUICALLBACK_H_
#define DELETEPLACEDITEMSUICALLBACK_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/transaction/TransactionLog.h"

// Administrative cleanup of individual placed items, including items without
// pickup radials. Never recursively delete a structure or another item's contents.
class DeletePlacedItemSuiCallback : public SuiCallback {
	uint64 objectID;
	uint64 parentID;

public:
	DeletePlacedItemSuiCallback(ZoneServer* server, uint64 id, uint64 parent)
		: SuiCallback(server), objectID(id), parentID(parent) {
	}

	static bool validate(CreatureObject* player, SceneObject* object) {
		if (player == nullptr || !player->isPlayerCreature())
			return false;

		auto ghost = player->getPlayerObject();
		if (ghost == nullptr || !ghost->isPrivileged() || !ghost->hasGodMode() || !ghost->hasAbility("object")) {
			player->sendSystemMessage("GM access to /object is required.");
			return false;
		}

		if (object == nullptr || object->_isMarkedForDeletion()) {
			player->sendSystemMessage("The item no longer exists.");
			return false;
		}

		if (!object->isTangibleObject() || object->isCreatureObject() ||
			object->isStructureObject() || object->isShipObject() ||
			object->isVehicleObject() || object->isVendor() || object->isControlDevice()) {
			player->sendSystemMessage("Only individual placed items can be deleted; creatures, structures, ships, vehicles, vendors and control devices are protected.");
			return false;
		}

		auto parent = object->getParent().get();
		if (parent == nullptr || !parent->isCellObject()) {
			player->sendSystemMessage("The item must be placed directly inside a structure cell.");
			return false;
		}

		auto root = object->getRootParent();
		if (root == nullptr || root->containsChildObject(object) ||
			object->getChildObjects()->size() != 0 || object->getContainerObjectsSize() != 0 ||
			object->getSlottedObjectsSize() != 0) {
			player->sendSystemMessage("Built-in structure objects and items with contents or child objects cannot be deleted with this command.");
			return false;
		}

		if (player->getZone() == nullptr || object->getZone() != player->getZone() ||
			player->getParentID() != parent->getObjectID() || object->getDistanceTo(player) > 32.f) {
			player->sendSystemMessage("Stand in the same room, within 32 meters of the item.");
			return false;
		}

		return true;
	}

	void run(CreatureObject* player, SuiBox* box, uint32 eventIndex, Vector<UnicodeString>* args) override {
		if (box == nullptr || !box->isMessageBox() || eventIndex != 0 || player == nullptr)
			return;

		ManagedReference<SceneObject*> object = server->getObject(objectID, false);
		if (object == nullptr) {
			player->sendSystemMessage("The item no longer exists.");
			return;
		}

		Locker locker(object, player);
		if (!validate(player, object))
			return;

		if (object->getParentID() != parentID) {
			player->sendSystemMessage("The item moved after confirmation opened. Run /object delete again.");
			return;
		}

		TransactionLog trx(player, TrxCode::SERVERDESTROYOBJECT, object);
		trx.addState("command", String("object delete"));
		trx.addState("parentID", parentID);
		if (trx.isVerbose()) {
			trx.addRelatedObject(object, true);
			trx.setExportRelatedObjects(true);
			trx.exportRelated();
		}

		player->info(true) << "/object delete: GM " << player->getObjectID()
			<< " deleting item " << objectID << " parent " << parentID
			<< " template " << object->getObjectTemplate()->getFullTemplateString();
		object->destroyObjectFromWorld(true);
		object->destroyObjectFromDatabase(false);
		player->sendSystemMessage("Permanently deleted placed item " + String::valueOf(objectID) + ".");
	}
};

#endif
