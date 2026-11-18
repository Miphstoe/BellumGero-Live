/*
 * Bellum Gero — /dropinventory shared helpers.
 *
 * Bulk-moves eligible DIRECT children of the player's main inventory into a
 * player-selected carried container. Never touches equipped items, locked
 * items, containers, or anything the normal transfer rules would refuse.
 * Every decision is re-evaluated at transfer time (fail closed).
 */

#ifndef DROPINVENTORYHELPER_H_
#define DROPINVENTORYHELPER_H_

#include "server/ServerCore.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/scene/TransferErrorCode.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/managers/objectcontroller/ObjectController.h"
#include "server/zone/objects/transaction/TransactionLog.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "system/lang/Integer.h"

class DropInventoryHelper {
public:
	enum ItemStatus {
		ELIGIBLE = 0,
		SKIP_LOCKED,
		SKIP_EQUIPPED,
		SKIP_CONTAINER,
		SKIP_RESTRICTED,
		SKIP_CAPACITY
	};

	struct Result {
		Vector<ManagedReference<SceneObject*> > eligible;
		int locked = 0;
		int equipped = 0;
		int containers = 0;
		int restricted = 0;
		int capacity = 0;
		int moved = 0;
		bool aborted = false;
	};

	static SceneObject* getInventory(CreatureObject* creature) {
		return creature->getSlottedObject("inventory");
	}

	// "Locked" = Bellum item lock radial. Fail closed: any non-empty value other than "0" counts as locked.
	static bool isItemLocked(SceneObject* item) {
		TangibleObject* tano = dynamic_cast<TangibleObject*>(item);

		if (tano == nullptr)
			return false;

		String lockValue = tano->getLuaStringData("item_locked");

		return !lockValue.isEmpty() && lockValue != "0";
	}

	static bool isProtectedDescriptor(SceneObject* obj) {
		for (int i = 0; i < obj->getArrangementDescriptorSize(); ++i) {
			const Vector<String>* descriptors = obj->getArrangementDescriptor(i);

			for (int j = 0; j < descriptors->size(); ++j) {
				const String& d = descriptors->get(j);

				if (d == "inventory" || d == "datapad" || d == "default_weapon" || d == "mission_bag" || d == "ghost" || d == "bank" || d == "hair")
					return true;
			}
		}

		return false;
	}

	// Player-side blocking states shared by command and callbacks.
	static bool playerBusy(CreatureObject* creature) {
		if (creature == nullptr || !creature->isPlayerCreature() || creature->isIncapacitated() || creature->isDead())
			return true;

		return creature->containsActiveSession(SessionFacadeType::TRADE) || creature->containsActiveSession(SessionFacadeType::CRAFTING);
	}

	enum TargetStatus {
		TARGET_OK = 0,
		TARGET_NONE,
		TARGET_INVALID,
		TARGET_RANGE,
		TARGET_PERMISSION
	};

	static constexpr float MAX_RANGE = 16.5f; // same reach the stock drag-and-drop transfer allows

	// Destination must be a storage container placed inside a player structure the player may use.
	// All permission decisions come from the engine (container -> cell -> building inheritance); nothing is granted here.
	static TargetStatus validateTarget(CreatureObject* creature, SceneObject* inventory, SceneObject* dest) {
		if (creature == nullptr || inventory == nullptr || dest == nullptr)
			return TARGET_NONE;

		if (dest == inventory || dest->isVendor() || !dest->isContainerObject() || dest->isClientObject() || isProtectedDescriptor(dest))
			return TARGET_INVALID;

		if (dest->getContainerType() == ContainerType::NONE)
			return TARGET_INVALID;

		// Must be placed in a cell of a (non-civic) player-owned building, not carried or worn.
		ManagedReference<SceneObject*> parent = dest->getParent().get();

		if (parent == nullptr || !parent->isCellObject() || dest->isASubChildOf(creature))
			return TARGET_INVALID;

		ManagedReference<SceneObject*> root = dest->getRootParent();

		if (root == nullptr || !root->isBuildingObject())
			return TARGET_INVALID;

		BuildingObject* building = cast<BuildingObject*>(root.get());

		if (building == nullptr || building->isClientObject() || building->getOwnerObjectID() == 0 || building->isCivicStructure())
			return TARGET_INVALID;

		// Player must be inside that same building, allowed in it, and close enough.
		if (creature->getRootParent() != root || !building->isAllowedEntry(creature) || building->isOnBanList(creature))
			return TARGET_PERMISSION;

		if (dest->getDistanceTo(creature) > MAX_RANGE)
			return TARGET_RANGE;

		if (!dest->checkContainerPermission(creature, ContainerPermissions::OPEN) || !dest->checkContainerPermission(creature, ContainerPermissions::MOVEIN))
			return TARGET_PERMISSION;

		return TARGET_OK;
	}

	static const char* targetMessage(TargetStatus s) {
		switch (s) {
		case TARGET_NONE: return "Target a storage container inside a house before using /dropinventory.";
		case TARGET_INVALID: return "The selected object is not a valid storage container.";
		case TARGET_RANGE: return "You must be closer to the selected container.";
		default: return "You do not have permission to store items in this container.";
		}
	}

	static int freeSlots(SceneObject* dest) {
		int free = (int)dest->getContainerVolumeLimit() - dest->getContainerObjectsSize();

		return free > 0 ? free : 0;
	}

	// Classify one inventory child against one destination. ignoreFull=true lets the preview pass count items that
	// are only blocked by the (separately computed) capacity.
	static ItemStatus classifyItem(CreatureObject* creature, SceneObject* inventory, SceneObject* dest, SceneObject* item, bool ignoreFull) {
		if (item == nullptr || item == dest || item == inventory)
			return SKIP_RESTRICTED;

		if (item->getParent().get() != inventory)
			return SKIP_RESTRICTED;

		if ((int)item->getContainmentType() != -1)
			return SKIP_EQUIPPED;

		if (item->isContainerObject() || item->getContainerObjectsSize() > 0 || item->getSlottedObjectsSize() > 0)
			return SKIP_CONTAINER;

		if (isItemLocked(item))
			return SKIP_LOCKED;

		if (!item->isTangibleObject() || item->isClientObject() || item->isVendor() || item->isCreatureObject() || item->isStructureObject() || item->isManufactureSchematic() || isProtectedDescriptor(item))
			return SKIP_RESTRICTED;

		if (!item->checkContainerPermission(creature, ContainerPermissions::MOVECONTAINER))
			return SKIP_RESTRICTED;

		if (!item->canBeTransferred(dest))
			return SKIP_RESTRICTED;

		String errorDescription;
		int err = dest->canAddObject(item, -1, errorDescription);

		if (err == TransferErrorCode::CONTAINERFULL)
			return ignoreFull ? ELIGIBLE : SKIP_CAPACITY;
		else if (err != 0)
			return SKIP_RESTRICTED;

		return ELIGIBLE;
	}

	static void tally(Result& r, ItemStatus s) {
		switch (s) {
		case SKIP_LOCKED: r.locked++; break;
		case SKIP_EQUIPPED: r.equipped++; break;
		case SKIP_CONTAINER: r.containers++; break;
		case SKIP_CAPACITY: r.capacity++; break;
		case SKIP_RESTRICTED: r.restricted++; break;
		default: break;
		}
	}

	// Preview. Caller must hold the inventory lock.
	static Result scan(CreatureObject* creature, SceneObject* inventory, SceneObject* dest) {
		Result r;

		if (!dest->checkContainerPermission(creature, ContainerPermissions::MOVEIN) || !inventory->checkContainerPermission(creature, ContainerPermissions::MOVEOUT))
			return r;

		// Snapshot first so nothing iterates a collection that is changing.
		Vector<ManagedReference<SceneObject*> > snapshot;
		int size = inventory->getContainerObjectsSize();

		for (int i = 0; i < size; ++i) {
			ManagedReference<SceneObject*> item = inventory->getContainerObject(i);

			if (item != nullptr)
				snapshot.add(item);
		}

		for (int i = 0; i < snapshot.size(); ++i) {
			ItemStatus s = classifyItem(creature, inventory, dest, snapshot.get(i), true);

			if (s == ELIGIBLE)
				r.eligible.add(snapshot.get(i));
			else
				tally(r, s);
		}

		int free = freeSlots(dest);

		if (r.eligible.size() > free)
			r.capacity += r.eligible.size() - free;

		return r;
	}

	// Perform the transfer. Caller must hold creature lock; this takes the inventory lock (cross-locked to creature).
	// Everything is re-validated per item; failures are isolated unless containment integrity is in doubt.
	static Result execute(CreatureObject* creature, SceneObject* inventory, SceneObject* dest) {
		Result r = scan(creature, inventory, dest);

		Vector<ManagedReference<SceneObject*> > toMove = r.eligible;
		r.eligible.removeAll();
		r.capacity = 0; // recomputed below from real transfer results

		ZoneServer* zoneServer = creature->getZoneServer();
		ObjectController* controller = (zoneServer != nullptr) ? zoneServer->getObjectController() : nullptr;

		if (controller == nullptr) {
			r.aborted = true;
			return r;
		}

		for (int i = 0; i < toMove.size(); ++i) {
			SceneObject* item = toMove.get(i);

			ItemStatus s = classifyItem(creature, inventory, dest, item, false);

			if (s == SKIP_CAPACITY) {
				// Destination is full: everything left stays in the inventory.
				r.capacity += toMove.size() - i;
				break;
			}

			if (s != ELIGIBLE) {
				tally(r, s);
				continue;
			}

			auto src = TransactionLog::getTrxParticipant(inventory, creature);
			auto dst = TransactionLog::getTrxParticipant(dest, dest);
			TransactionLog trx(src, dst, item, TrxCode::TRANSFERITEMMISC);

			bool ok = controller->transferObject(item, dest, -1, true);
			ManagedReference<SceneObject*> newParent = item->getParent().get();

			if (ok && newParent == dest) {
				r.moved++;
				trx.commit();
				continue;
			}

			trx.abort() << "dropinventory transfer failed";

			if (newParent == inventory) {
				// Isolated failure, item is intact in the source.
				r.restricted++;
				continue;
			}

			// Item is somewhere unexpected: stop immediately rather than risk more damage.
			creature->error() << "DropInventory: containment integrity problem, item " << item->getObjectID() << " ended in unexpected parent; aborting.";
			r.aborted = true;
			break;
		}

		return r;
	}

	static String itemLabel(SceneObject* obj) {
		String name = obj->getDisplayedName();
		String idStr = String::valueOf((uint64)obj->getObjectID());
		int len = idStr.length();
		String tail = len > 4 ? idStr.subString(len - 4) : idStr;

		return name + " [" + String::valueOf(obj->getContainerObjectsSize()) + "/" + String::valueOf((int)obj->getContainerVolumeLimit()) + "] (#" + tail + ")";
	}
};

#endif /* DROPINVENTORYHELPER_H_ */
