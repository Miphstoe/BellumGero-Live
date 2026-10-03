/*
 * FactoryObjectImplementation.cpp
 *
 *  Created on: Jun 4, 2010
 *      Author: kyle
 */

#include "server/zone/objects/installation/factory/FactoryObject.h"
#include "server/zone/objects/installation/factory/FactoryHopperObserver.h"
#include "sui/InsertSchematicSuiCallback.h"
#include "sui/ManageFactoryQueueSuiCallback.h"
#include "tasks/CreateFactoryObjectTask.h"
#include "tasks/FactoryQueueRetryTask.h"
#include "server/zone/ZoneProcessServer.h"
#include "server/zone/ZoneClientSession.h"
#include "server/chat/ChatManager.h"
#include "server/zone/packets/factory/FactoryCrateObjectDeltaMessage3.h"
#include "server/zone/packets/scene/SceneObjectCreateMessage.h"
#include "server/zone/packets/scene/ClientOpenContainerMessage.h"
#include "server/zone/managers/object/ObjectManager.h"
#include "server/zone/managers/resource/ResourceManager.h"
#include "server/zone/objects/resource/ResourceSpawn.h"

#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"
#include "server/zone/objects/resource/ResourceContainer.h"
#include "server/zone/objects/draftschematic/DraftSchematic.h"
#include "server/zone/objects/manufactureschematic/ManufactureSchematic.h"
#include "server/zone/objects/factorycrate/FactoryCrate.h"
#include "server/zone/objects/tangible/weapon/WeaponObject.h"

#include "templates/installation/FactoryObjectTemplate.h"
#include "server/zone/objects/transaction/TransactionLog.h"

//#define DEBUG_FACTORIES

namespace {
const int MAX_FACTORY_QUEUE = 10;

String makeFactoryQueueResourceLabel(const String& value) {
	if (value.isEmpty())
		return "";

	return value.replaceAll("_", " ");
}

void appendFactoryQueueIngredientIdentity(
		StringBuffer& row,
		BlueprintEntry* entry,
		ResourceManager* resourceManager) {

	if (entry == nullptr)
		return;

	if (entry->getType() == "resource") {
		row << entry->getDisplayedName();

		if (resourceManager == nullptr)
			return;

		ManagedReference<ResourceSpawn*> spawn =
			resourceManager->getResourceSpawn(entry->getKey());

		if (spawn == nullptr)
			return;

		String resourceClass = makeFactoryQueueResourceLabel(spawn->getFinalClass());

		if (!resourceClass.isEmpty() && resourceClass != entry->getDisplayedName())
			row << " | " << resourceClass;

		return;
	}

	row << entry->getDisplayedName();

	if (entry->needsIdentical() && !entry->getSerial().isEmpty())
		row << " | Serial " << entry->getSerial();
}
}
const int FactoryObjectImplementation::QUEUE_ACTIVE;
const int FactoryObjectImplementation::QUEUE_WAITING;
const int FactoryObjectImplementation::QUEUE_BLOCKED_RESOURCES;
const int FactoryObjectImplementation::QUEUE_BLOCKED_COMPONENTS;
const int FactoryObjectImplementation::QUEUE_BLOCKED_OUTPUT_FULL;
const int FactoryObjectImplementation::QUEUE_BLOCKED_POWER;
const int FactoryObjectImplementation::QUEUE_BLOCKED_MAINTENANCE;
const int FactoryObjectImplementation::QUEUE_BLOCKED_INVALID;
const int FactoryObjectImplementation::QUEUE_COMPLETED;

void FactoryObjectImplementation::loadTemplateData(SharedObjectTemplate* templateData) {
	InstallationObjectImplementation::loadTemplateData(templateData);

	if (!templateData->isFactoryObjectTemplate())
		return;

	FactoryObjectTemplate* factory = dynamic_cast<FactoryObjectTemplate*>(templateData);

	craftingTabsSupported = factory->getCraftingTabsSupported();
}

void FactoryObjectImplementation::notifyLoadFromDatabase() {
	InstallationObjectImplementation::notifyLoadFromDatabase();

	FactoryObject* thisFactory = _this.getReferenceUnsafeStaticCast();
	restoreQueueMetadata();

	if (queueSchematicIDs.size() > MAX_FACTORY_QUEUE) {
		warning() << "Factory queue loaded in non-destructive recovery state above the normal queue cap. FactoryID: "
			<< getObjectID() << " QueueSize: " << queueSchematicIDs.size()
			<< " MaxNormalQueue: " << MAX_FACTORY_QUEUE
			<< ". No new schematics can be added until entries are removed.";
	}

	if (isActive() && !queueEnabled)
		queueEnabled = true;

	setLoggingName("FactoryObject");

	if (queueEnabled) {
		Core::getTaskManager()->executeTask([factory = WeakReference<FactoryObject*>(_this.getReferenceUnsafeStaticCast())]() {
			auto factoryStrong = factory.get();

			if (factoryStrong != nullptr) {
				Locker lock(factoryStrong);
				factoryStrong->setActive(false, true);
				factoryStrong->evaluateManufacturingQueue();
			}
		}, "StartFactoryLambda");
	}

	hopperObserver = new FactoryHopperObserver(_this.getReferenceUnsafeStaticCast());
	ManagedReference<SceneObject*> inputHopper = getSlottedObject("ingredient_hopper");
	ManagedReference<SceneObject*> outputHopper = getSlottedObject("output_hopper");

	if (inputHopper != nullptr) {
		Locker lock(inputHopper, thisFactory);

		inputHopper->registerObserver(ObserverEventType::OPENCONTAINER, hopperObserver);
		inputHopper->registerObserver(ObserverEventType::CLOSECONTAINER, hopperObserver);
		inputHopper->registerObserver(ObserverEventType::CONTAINERCONTENTSCHANGED, hopperObserver);

		inputHopper->setContainerDefaultDenyPermission(ContainerPermissions::MOVECONTAINER);
	}

	if (outputHopper != nullptr) {
		Locker lock(outputHopper, thisFactory);

		outputHopper->registerObserver(ObserverEventType::OPENCONTAINER, hopperObserver);
		outputHopper->registerObserver(ObserverEventType::CLOSECONTAINER, hopperObserver);
		outputHopper->registerObserver(ObserverEventType::CONTAINERCONTENTSCHANGED, hopperObserver);

		outputHopper->setContainerDefaultDenyPermission(ContainerPermissions::MOVECONTAINER);
	}
}

void FactoryObjectImplementation::createChildObjects() {
	FactoryObject* thisFactory = _this.getReferenceUnsafeStaticCast();

	// Create the observer for the hoppers
	hopperObserver = new FactoryHopperObserver(_this.getReferenceUnsafeStaticCast());

	if (hopperObserver == nullptr) {
		error() << "Factory has a nullptr to its hopper observer - FactoryID: " << getObjectID();
		return;
	}

	// Create ingredient hopper
	String ingredientHopperName = "object/tangible/hopper/manufacture_installation_ingredient_hopper_1.iff";
	ManagedReference<SceneObject*> ingredientHopper = server->getZoneServer()->createObject(ingredientHopperName.hashCode(), getPersistenceLevel());

	if (ingredientHopper == nullptr) {
		error() << "Factory has a nullptr to its ingredient hopper - FactoryID: " << getObjectID();
		return;
	}

	Locker ilocker(ingredientHopper, thisFactory);

	ingredientHopper->setContainerDefaultDenyPermission(ContainerPermissions::MOVECONTAINER);

	transferObject(ingredientHopper, 4);

	ingredientHopper->registerObserver(ObserverEventType::OPENCONTAINER, hopperObserver);
	ingredientHopper->registerObserver(ObserverEventType::CLOSECONTAINER, hopperObserver);
	ingredientHopper->registerObserver(ObserverEventType::CONTAINERCONTENTSCHANGED, hopperObserver);

	ilocker.release();

	// Create Output hopper
	String outputHopperName = "object/tangible/hopper/manufacture_installation_output_hopper_1.iff";
	ManagedReference<SceneObject*> outputHopper = server->getZoneServer()->createObject(outputHopperName.hashCode(), getPersistenceLevel());

	if (outputHopper == nullptr) {
		error() << "Factory has a nullptr to its output hopper - FactoryID: " << getObjectID();
		return;
	}

	Locker olocker(outputHopper, thisFactory);
	outputHopper->setContainerDefaultDenyPermission(ContainerPermissions::MOVECONTAINER);

	transferObject(outputHopper, 4);

	outputHopper->registerObserver(ObserverEventType::OPENCONTAINER, hopperObserver);
	outputHopper->registerObserver(ObserverEventType::CLOSECONTAINER, hopperObserver);
	outputHopper->registerObserver(ObserverEventType::CONTAINERCONTENTSCHANGED, hopperObserver);
}

void FactoryObjectImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* object) {
	InstallationObjectImplementation::fillAttributeList(alm, object);

	if (object != nullptr && isOnAdminList(object)) {
		alm->insertAttribute("examine_maintenance_rate", String::valueOf((int)getMaintenanceRate()) + " / hour");
		alm->insertAttribute("examine_maintenance", String::valueOf((int)surplusMaintenance));

		int basePowerRate = getBasePowerRate();
		if (basePowerRate > 0)
			alm->insertAttribute("examine_power", String::valueOf((int)surplusPower) + " (Rate: " + String::valueOf(basePowerRate) + " / hour)");
		else
			alm->insertAttribute("examine_power", String::valueOf((int)surplusPower));
	}

	if (!isActive() || object == nullptr || !isOnAdminList(object))
		return;

	ManagedReference<ManufactureSchematic*> schematic = getActiveQueuedSchematic();

	if (schematic == nullptr)
		return;

	ManagedReference<TangibleObject*> prototype = dynamic_cast<TangibleObject*>(schematic->getPrototype());

	if (prototype != nullptr)
		alm->insertAttribute("manufacture_object", prototype->getDisplayedName());

	alm->insertAttribute("manufacture_time", timer);

	int queueIndex = findQueueEntry(schematic->getObjectID());
	int remaining = schematic->getManufactureLimit();
	int produced = currentRunCount;

	if (queueIndex >= 0 && queueIndex < queueRemainingLimits.size()) {
		remaining = queueRemainingLimits.get(queueIndex);

		if (queueIndex < queueRequestedLimits.size()) {
			int requested = queueRequestedLimits.get(queueIndex);
			produced = requested > remaining ? requested - remaining : 0;
		}
	}

	alm->insertAttribute("manf_limit", remaining);
	alm->insertAttribute("manufacture_count", produced);
}


void FactoryObjectImplementation::sendTo(SceneObject* player, bool doClose, bool forceLoadContainer) {
	if (player == nullptr || player->getClient() == nullptr)
		return;

#ifdef DEBUG_FACTORIES
	info(true) << "sendTo - Player: " << player->getDisplayedName();
#endif

	BaseMessage* msg = new SceneObjectCreateMessage(asSceneObject());
	player->sendMessage(msg);

	link(player, containmentType);

	try {
		sendBaselinesTo(player);
	} catch (const Exception& e) {
		error(e.getMessage());
		e.printStackTrace();
	}

	if (doClose) {
		SceneObjectImplementation::close(player);
	}
}

void FactoryObjectImplementation::restoreQueueMetadata() {
	int size = queueSchematicIDs.size();

	// Keep all persisted vectors aligned with the queue ID vector. If older or
	// partially-written metadata is missing a requested/remaining value, use the
	// schematic's current lifetime as the safest non-destructive fallback.
	while (queueSequence.size() > size)
		queueSequence.remove(queueSequence.size() - 1);
	while (queueRequestedLimits.size() > size)
		queueRequestedLimits.remove(queueRequestedLimits.size() - 1);
	while (queueRemainingLimits.size() > size)
		queueRemainingLimits.remove(queueRemainingLimits.size() - 1);
	while (queueStatuses.size() > size)
		queueStatuses.remove(queueStatuses.size() - 1);
	while (queueBlockedReasons.size() > size)
		queueBlockedReasons.remove(queueBlockedReasons.size() - 1);
	while (queueEvaluationTimes.size() > size)
		queueEvaluationTimes.remove(queueEvaluationTimes.size() - 1);

	while (queueSequence.size() < size)
		queueSequence.add(queueSequence.size() + 1);

	while (queueRequestedLimits.size() < size) {
		int index = queueRequestedLimits.size();
		int fallback = 0;

		ManagedReference<ManufactureSchematic*> schematic =
			server->getZoneServer()->getObject(queueSchematicIDs.get(index)).castTo<ManufactureSchematic*>();

		if (schematic != nullptr)
			fallback = schematic->getManufactureLimit();

		queueRequestedLimits.add(fallback);
	}

	while (queueRemainingLimits.size() < size) {
		int index = queueRemainingLimits.size();
		queueRemainingLimits.add(queueRequestedLimits.get(index));
	}

	while (queueStatuses.size() < size)
		queueStatuses.add(QUEUE_WAITING);
	while (queueBlockedReasons.size() < size)
		queueBlockedReasons.add("");
	while (queueEvaluationTimes.size() < size)
		queueEvaluationTimes.add(0);

	// Duplicate metadata is safe to collapse because it points at the same
	// physical schematic object. Never destroy or move an object during repair.
	for (int i = queueSchematicIDs.size() - 1; i >= 0; --i) {
		bool duplicate = false;

		for (int j = 0; j < i; ++j) {
			if (queueSchematicIDs.get(j) == queueSchematicIDs.get(i)) {
				duplicate = true;
				break;
			}
		}

		if (!duplicate)
			continue;

		unsigned long long duplicateID = queueSchematicIDs.get(i);

		queueSchematicIDs.remove(i);
		queueSequence.remove(i);
		queueRequestedLimits.remove(i);
		queueRemainingLimits.remove(i);
		queueStatuses.remove(i);
		queueBlockedReasons.remove(i);
		queueEvaluationTimes.remove(i);

		warning() << "Factory queue duplicate metadata removed without moving the schematic. FactoryID: "
			<< getObjectID() << " SchematicID: " << duplicateID;
	}

	// The factory's physical contents are authoritative for ownership. Recover
	// any contained manufacturing schematic that is missing from queue metadata.
	// This is intentionally non-destructive and may temporarily preserve more
	// than MAX_FACTORY_QUEUE entries so an owner can see/remove every object.
	for (int i = 0; i < getContainerObjectsSize(); ++i) {
		ManagedReference<ManufactureSchematic*> schematic =
			getContainerObject(i).castTo<ManufactureSchematic*>();

		if (schematic == nullptr || findQueueEntry(schematic->getObjectID()) >= 0)
			continue;

		int usesRemaining = schematic->getManufactureLimit();

		queueSchematicIDs.add(schematic->getObjectID());
		queueSequence.add(queueSchematicIDs.size());
		queueRequestedLimits.add(usesRemaining > 0 ? usesRemaining : 0);
		queueRemainingLimits.add(usesRemaining > 0 ? usesRemaining : 0);
		queueStatuses.add(usesRemaining > 0 ? QUEUE_WAITING : QUEUE_COMPLETED);
		queueBlockedReasons.add("");
		queueEvaluationTimes.add(0);

		warning() << "Factory queue recovered a physically contained schematic missing from metadata. FactoryID: "
			<< getObjectID() << " SchematicID: " << schematic->getObjectID()
			<< " QueueSize: " << queueSchematicIDs.size();
	}

	size = queueSchematicIDs.size();

	// Sanitize recoverable counter/state mismatches without reducing a requested
	// batch or destroying anything. Stale entries that resolve outside this
	// factory are retained as INVALID so the owner can explicitly remove them.
	for (int i = 0; i < size; ++i) {
		ManagedReference<ManufactureSchematic*> schematic =
			server->getZoneServer()->getObject(queueSchematicIDs.get(i)).castTo<ManufactureSchematic*>();

		if (schematic == nullptr)
			continue;

		ManagedReference<SceneObject*> parent = schematic->getParent().get();

		if (parent == nullptr || parent->getObjectID() != getObjectID()) {
			queueStatuses.set(i, QUEUE_BLOCKED_INVALID);
			queueBlockedReasons.set(i, "Manufacturing schematic is not contained by this factory.");
			continue;
		}

		int requested = queueRequestedLimits.get(i);
		int remaining = queueRemainingLimits.get(i);
		int usesRemaining = schematic->getManufactureLimit();

		if (queueStatuses.get(i) != QUEUE_COMPLETED &&
				requested <= 0 && remaining <= 0 && usesRemaining > 0) {
			queueRequestedLimits.set(i, usesRemaining);
			queueRemainingLimits.set(i, usesRemaining);
			requested = usesRemaining;
			remaining = usesRemaining;

			warning() << "Factory queue repaired missing batch counters using schematic lifetime. FactoryID: "
				<< getObjectID() << " SchematicID: " << schematic->getObjectID()
				<< " RestoredAmount: " << usesRemaining;
		}

		if (requested < remaining) {
			queueRequestedLimits.set(i, remaining);

			warning() << "Factory queue repaired requested amount below remaining amount. FactoryID: "
				<< getObjectID() << " SchematicID: " << schematic->getObjectID()
				<< " Requested: " << requested << " Remaining: " << remaining;
		}

		if (remaining <= 0 && queueStatuses.get(i) != QUEUE_COMPLETED) {
			queueStatuses.set(i, QUEUE_COMPLETED);
			queueBlockedReasons.set(i, "");
		}
	}

	for (int i = 0; i < queueSequence.size(); ++i)
		queueSequence.set(i, i + 1);

	bool activeFound = false;

	for (int i = 0; i < size; ++i) {
		if (queueStatuses.get(i) != QUEUE_ACTIVE)
			continue;

		if (queueRemainingLimits.get(i) <= 0) {
			queueStatuses.set(i, QUEUE_COMPLETED);
			queueBlockedReasons.set(i, "");
			continue;
		}

		if (activeFound)
			queueStatuses.set(i, QUEUE_WAITING);
		else
			activeFound = true;
	}

	if (!activeFound) {
		for (int i = 0; i < size; ++i) {
			if (queueStatuses.get(i) == QUEUE_WAITING && queueRemainingLimits.get(i) > 0) {
				queueStatuses.set(i, QUEUE_ACTIVE);
				break;
			}
		}
	}
}


int FactoryObjectImplementation::findQueueEntry(unsigned long long schematicID) {
	for (int i = 0; i < queueSchematicIDs.size(); ++i)
		if (queueSchematicIDs.get(i) == schematicID)
			return i;
	return -1;
}

int FactoryObjectImplementation::getManufacturingQueueIndex(unsigned long long schematicID) {
	restoreQueueMetadata();
	return findQueueEntry(schematicID);
}


ManufactureSchematic* FactoryObjectImplementation::getActiveQueuedSchematic() {
	restoreQueueMetadata();
	for (int i = 0; i < queueSchematicIDs.size(); ++i) {
		if (queueStatuses.get(i) != QUEUE_ACTIVE)
			continue;
		return server->getZoneServer()->getObject(queueSchematicIDs.get(i)).castTo<ManufactureSchematic*>();
	}
	return nullptr;
}

ManufactureSchematic* FactoryObjectImplementation::syncActiveQueueEntryToFactory() {
	restoreQueueMetadata();

	for (int i = 0; i < queueSchematicIDs.size(); ++i) {
		if (queueStatuses.get(i) != QUEUE_ACTIVE)
			continue;

		ManagedReference<ManufactureSchematic*> schematic =
			server->getZoneServer()->getObject(queueSchematicIDs.get(i)).castTo<ManufactureSchematic*>();

		if (schematic == nullptr) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Active manufacturing schematic could not be resolved.");
			return nullptr;
		}

		ManagedReference<SceneObject*> parent = schematic->getParent().get();

		if (parent == nullptr || parent->getObjectID() != getObjectID()) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Active manufacturing schematic is not contained by this factory.");
			return nullptr;
		}

		int batchRemaining = queueRemainingLimits.get(i);

		if (batchRemaining <= 0) {
			queueStatuses.set(i, QUEUE_COMPLETED);
			queueBlockedReasons.set(i, "");
			return nullptr;
		}

		int schematicUsesRemaining = schematic->getManufactureLimit();

		if (schematicUsesRemaining <= 0) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Manufacturing schematic has no uses remaining.");
			return nullptr;
		}

		if (batchRemaining > schematicUsesRemaining) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Requested batch exceeds the manufacturing schematic uses remaining.");
			return nullptr;
		}

		return schematic;
	}

	return nullptr;
}


bool FactoryObjectImplementation::activateQueueEntry(int queueIndex) {
	restoreQueueMetadata();

	if (queueIndex < 0 || queueIndex >= queueStatuses.size())
		return false;

	for (int i = 0; i < queueStatuses.size(); ++i) {
		if (i != queueIndex && queueStatuses.get(i) == QUEUE_ACTIVE)
			queueStatuses.set(i, QUEUE_WAITING);
	}

	queueStatuses.set(queueIndex, QUEUE_ACTIVE);
	queueBlockedReasons.set(queueIndex, "");
	queueEvaluationTimes.set(queueIndex, (unsigned long long)Time().getTime());

	int requested = queueIndex < queueRequestedLimits.size() ? queueRequestedLimits.get(queueIndex) : 0;
	int remaining = queueIndex < queueRemainingLimits.size() ? queueRemainingLimits.get(queueIndex) : 0;
	currentRunCount = requested > remaining ? requested - remaining : 0;

	return syncActiveQueueEntryToFactory() != nullptr;
}


void FactoryObjectImplementation::markQueueEntryBlocked(int index, int status, const String& reason) {
	if (index < 0 || index >= queueStatuses.size())
		return;
	bool stateChanged = queueStatuses.get(index) != status || queueBlockedReasons.get(index) != reason;
	queueStatuses.set(index, status);
	queueBlockedReasons.set(index, reason);
	queueEvaluationTimes.set(index, (unsigned long long)Time().getTime());

	// Only log when the entry actually transitions into a new blocked state.
	// Periodic queue re-evaluations (the 60s retry task) re-mark already-blocked
	// entries with the same reason; repeating the message every retry spams the log.
	if (!stateChanged)
		return;

	// A fresh block transition is worth one idle summary again.
	queueIdleNoticeLogged = false;

	// Insufficient maintenance / power / resources / components and a full output
	// hopper are expected, player-recoverable conditions - report the transition
	// once at info level. Only genuine faults stay at WARNING.
	if (status == QUEUE_BLOCKED_INVALID)
		warning() << "Factory queue entry blocked. FactoryID: " << getObjectID() << " SchematicID: " << queueSchematicIDs.get(index) << " Position: " << index + 1 << " Reason: " << reason;
	else
		info() << "Factory queue entry waiting. FactoryID: " << getObjectID() << " SchematicID: " << queueSchematicIDs.get(index) << " Position: " << index + 1 << " Reason: " << reason;
}

bool FactoryObjectImplementation::isQueuedOutputReady(ManufactureSchematic* schematic) {
	ManagedReference<SceneObject*> outputHopper = getSlottedObject("output_hopper");
	ManagedReference<TangibleObject*> prototype = schematic == nullptr ? nullptr : schematic->getPrototype();
	if (outputHopper == nullptr || prototype == nullptr)
		return false;
	if (schematic->getFactoryCrateSize() > 1 && locateCrateInOutputHopper(prototype) != nullptr)
		return true;
	return !outputHopper->isContainerFull();
}

bool FactoryObjectImplementation::refreshQueuedSchematicReadiness(int queueIndex) {
	restoreQueueMetadata();

	if (queueIndex < 0 || queueIndex >= queueSchematicIDs.size())
		return false;

	if (queueStatuses.get(queueIndex) == QUEUE_COMPLETED || queueRemainingLimits.get(queueIndex) <= 0) {
		queueStatuses.set(queueIndex, QUEUE_COMPLETED);
		queueBlockedReasons.set(queueIndex, "");
		return false;
	}

	bool wasActive = queueStatuses.get(queueIndex) == QUEUE_ACTIVE;

	// Power and maintenance are factory-wide gates. Only stamp them onto an
	// entry while the factory is stopped/paused; a running factory is already
	// past these gates and its active production tick owns that validation.
	if (!isActive()) {
		if (getMaintenanceRate() != 0 && getSurplusMaintenance() <= 0) {
			markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_MAINTENANCE, "Factory maintenance is insufficient.");
			return false;
		}

		if (getBasePowerRate() != 0 && getSurplusPower() <= 0) {
			markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_POWER, "Factory power is insufficient.");
			return false;
		}
	}

	ManagedReference<ManufactureSchematic*> schematic =
		server->getZoneServer()->getObject(queueSchematicIDs.get(queueIndex)).castTo<ManufactureSchematic*>();

	if (schematic == nullptr) {
		markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_INVALID, "Manufacturing schematic could not be resolved.");
		return false;
	}

	ManagedReference<SceneObject*> parent = schematic->getParent().get();

	if (parent == nullptr || parent->getObjectID() != getObjectID()) {
		markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_INVALID, "Manufacturing schematic is not contained by this factory.");
		return false;
	}

	int schematicUsesRemaining = schematic->getManufactureLimit();

	if (schematicUsesRemaining <= 0) {
		markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_INVALID, "Manufacturing schematic has no uses remaining.");
		return false;
	}

	if (queueRemainingLimits.get(queueIndex) > schematicUsesRemaining) {
		markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_INVALID, "Requested batch exceeds the manufacturing schematic uses remaining.");
		return false;
	}

	if (schematic->getPrototype() == nullptr) {
		markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_INVALID, "Manufacturing schematic has no prototype.");
		return false;
	}

	if (!populateSchematicBlueprint(schematic)) {
		markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_INVALID, "Factory ingredient hopper is unavailable.");
		return false;
	}

	String type = "";
	String displayedName = "";

	schematic->canManufactureItem(type, displayedName);

	if (!displayedName.isEmpty()) {
		markQueueEntryBlocked(
			queueIndex,
			type == "resource" ? QUEUE_BLOCKED_RESOURCES : QUEUE_BLOCKED_COMPONENTS,
			displayedName);

		return false;
	}

	if (!isQueuedOutputReady(schematic)) {
		markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_OUTPUT_FULL, "Output hopper is full.");
		return false;
	}

	queueStatuses.set(queueIndex, wasActive && !isActive() ? QUEUE_ACTIVE : QUEUE_WAITING);
	queueBlockedReasons.set(queueIndex, "");
	queueEvaluationTimes.set(queueIndex, (unsigned long long)Time().getTime());
	queueIdleNoticeLogged = false;

	info() << "Factory queue entry readiness refreshed. FactoryID: " << getObjectID()
		<< " SchematicID: " << schematic->getObjectID()
		<< " Position: " << queueIndex + 1
		<< " Validation: READY";

	return true;
}

void FactoryObjectImplementation::evaluateManufacturingQueue() {
	if (queueEvaluationInProgress)
		return;

	queueEvaluationInProgress = true;
	restoreQueueMetadata();

	if (!queueEnabled) {
		queueEvaluationInProgress = false;
		return;
	}

	if (isActive()) {
		queueEvaluationInProgress = false;
		return;
	}

	bool hasUnfinishedBatch = false;

	for (int i = 0; i < queueSchematicIDs.size(); ++i) {
		if (queueStatuses.get(i) != QUEUE_COMPLETED && queueRemainingLimits.get(i) > 0) {
			hasUnfinishedBatch = true;
			break;
		}
	}

	if (!hasUnfinishedBatch) {
		queueEnabled = false;
		queueIdleNoticeLogged = false;
		currentUserName = "";

		Reference<Task*> retryTask = getPendingTask("factoryQueueRetry");
		removePendingTask("factoryQueueRetry");

		if (retryTask != nullptr && retryTask->isScheduled())
			retryTask->cancel();

		queueEvaluationInProgress = false;
		return;
	}

	if (queueSchematicIDs.size() > 0) {
		int gateStatus = 0;
		String gateReason;

		if (getMaintenanceRate() != 0 && getSurplusMaintenance() <= 0) {
			gateStatus = QUEUE_BLOCKED_MAINTENANCE;
			gateReason = "Factory maintenance is insufficient.";
		} else if (getBasePowerRate() != 0 && getSurplusPower() <= 0) {
			gateStatus = QUEUE_BLOCKED_POWER;
			gateReason = "Factory power is insufficient.";
		}

		if (gateStatus != 0) {
			for (int i = 0; i < queueSchematicIDs.size(); ++i) {
				if (queueStatuses.get(i) == QUEUE_COMPLETED || queueRemainingLimits.get(i) <= 0)
					continue;

				markQueueEntryBlocked(i, gateStatus, gateReason);
				break;
			}

			if (!queueIdleNoticeLogged) {
				queueIdleNoticeLogged = true;
				info() << "Factory queue idle. FactoryID: " << getObjectID() << " Reason: " << gateReason;
			}

			queueEnabled = false;
			currentUserName = "";

			Reference<Task*> retryTask = getPendingTask("factoryQueueRetry");
			removePendingTask("factoryQueueRetry");

			if (retryTask != nullptr && retryTask->isScheduled())
				retryTask->cancel();

			info() << "Factory queue session auto-stopped. FactoryID: " << getObjectID()
				<< " Reason: " << gateReason;

			queueIdleNoticeLogged = false;
			queueEvaluationInProgress = false;
			return;
		}
	}

	bool activated = false;

	for (int i = 0; i < queueSchematicIDs.size(); ++i) {
		if (queueStatuses.get(i) == QUEUE_COMPLETED)
			continue;

		if (queueRemainingLimits.get(i) <= 0) {
			queueStatuses.set(i, QUEUE_COMPLETED);
			queueBlockedReasons.set(i, "");
			continue;
		}

		ManagedReference<ManufactureSchematic*> schematic =
			server->getZoneServer()->getObject(queueSchematicIDs.get(i)).castTo<ManufactureSchematic*>();

		if (schematic == nullptr) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Manufacturing schematic could not be resolved.");
			continue;
		}

		ManagedReference<SceneObject*> parent = schematic->getParent().get();

		if (parent == nullptr || parent->getObjectID() != getObjectID()) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Manufacturing schematic is not contained by this factory.");
			continue;
		}

		int schematicUsesRemaining = schematic->getManufactureLimit();

		if (schematicUsesRemaining <= 0) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Manufacturing schematic has no uses remaining.");
			continue;
		}

		if (queueRemainingLimits.get(i) > schematicUsesRemaining) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Requested batch exceeds the manufacturing schematic uses remaining.");
			continue;
		}

		if (schematic->getPrototype() == nullptr) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Manufacturing schematic has no prototype.");
			continue;
		}

		if (!populateSchematicBlueprint(schematic)) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Factory ingredient hopper is unavailable.");
			continue;
		}

		String type = "";
		String displayedName = "";

		schematic->canManufactureItem(type, displayedName);

		if (displayedName != "") {
			if (!queueIdleNoticeLogged) {
				info() << "Factory queue readiness failed. FactoryID: " << getObjectID()
					<< " SchematicID: " << schematic->getObjectID()
					<< " Position: " << i + 1
					<< " Validation: " << (type == "resource" ? "MISSING_RESOURCES" : "MISSING_COMPONENTS")
					<< " Detail: " << displayedName;

				logIngredientValidationFailure(schematic, i, "QUEUE_READINESS");
			}

			markQueueEntryBlocked(
				i,
				type == "resource" ? QUEUE_BLOCKED_RESOURCES : QUEUE_BLOCKED_COMPONENTS,
				displayedName);

			continue;
		}

		if (!isQueuedOutputReady(schematic)) {
			if (!queueIdleNoticeLogged)
				info() << "Factory queue readiness failed. FactoryID: " << getObjectID()
					<< " SchematicID: " << schematic->getObjectID()
					<< " Position: " << i + 1
					<< " Validation: OUTPUT_FULL";

			markQueueEntryBlocked(i, QUEUE_BLOCKED_OUTPUT_FULL, "Output hopper is full.");
			continue;
		}

		info() << "Factory queue readiness passed. FactoryID: " << getObjectID()
			<< " SchematicID: " << schematic->getObjectID()
			<< " Position: " << i + 1
			<< " BatchRemaining: " << queueRemainingLimits.get(i)
			<< " SchematicUsesRemaining: " << schematicUsesRemaining
			<< " Validation: RUNNABLE Output: READY";

		if (!activateQueueEntry(i)) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Factory could not synchronize the active schematic.");
			continue;
		}

		if (startFactory())
			activated = true;
		else {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Factory could not start this schematic.");
			continue;
		}

		break;
	}

	if (activated) {
		queueIdleNoticeLogged = false;
	} else {
		if (!queueIdleNoticeLogged)
			info() << "Factory queue exhausted or blocked. FactoryID: " << getObjectID();

		queueEnabled = false;
		currentUserName = "";

		Reference<Task*> retryTask = getPendingTask("factoryQueueRetry");
		removePendingTask("factoryQueueRetry");

		if (retryTask != nullptr && retryTask->isScheduled())
			retryTask->cancel();

		info() << "Factory queue session auto-stopped. FactoryID: " << getObjectID()
			<< " HasUnfinishedBatch: " << (hasUnfinishedBatch ? "true" : "false")
			<< " Reason: no runnable queue entries remain.";

		queueIdleNoticeLogged = false;
	}

	queueEvaluationInProgress = false;
}


void FactoryObjectImplementation::scheduleManufacturingQueueEvaluation() {
	Core::getTaskManager()->executeTask([factory = WeakReference<FactoryObject*>(_this.getReferenceUnsafeStaticCast())]() {
		auto factoryStrong = factory.get();
		if (factoryStrong == nullptr)
			return;
		Locker lock(factoryStrong);
		factoryStrong->evaluateManufacturingQueue();
	}, "FactoryQueueEvaluation");
}

bool FactoryObjectImplementation::addQueuedSchematic(CreatureObject* player, ManufactureSchematic* schematic) {
	if (schematic == nullptr)
		return false;

	return addQueuedSchematicBatch(player, schematic, schematic->getManufactureLimit());
}

bool FactoryObjectImplementation::addQueuedSchematicBatch(CreatureObject* player, ManufactureSchematic* schematic, int requestedAmount) {
	if (player == nullptr || schematic == nullptr || !isOnAdminList(player) || !schematic->isASubChildOf(player))
		return false;

	restoreQueueMetadata();

	int previousQueueSize = queueSchematicIDs.size();
	unsigned long long existingActiveID = 0;
	bool hasUnfinishedEntry = false;

	for (int i = 0; i < queueStatuses.size(); ++i) {
		if (queueStatuses.get(i) == QUEUE_ACTIVE)
			existingActiveID = queueSchematicIDs.get(i);

		if (queueStatuses.get(i) != QUEUE_COMPLETED && queueRemainingLimits.get(i) > 0)
			hasUnfinishedEntry = true;
	}

	if (queueSchematicIDs.size() >= MAX_FACTORY_QUEUE) {
		player->sendSystemMessage("This factory queue already contains 10 manufacturing schematics.");
		return false;
	}

	if (!schematic->isManufactureSchematic() || schematic->getDraftSchematic() == nullptr)
		return false;

	int schematicUsesRemaining = schematic->getManufactureLimit();

	if (schematicUsesRemaining <= 0) {
		player->sendSystemMessage("That manufacturing schematic has no uses remaining.");
		return false;
	}

	if (requestedAmount < 1 || requestedAmount > schematicUsesRemaining) {
		player->sendSystemMessage(
			"Enter a production amount between 1 and " + String::valueOf(schematicUsesRemaining) + ".");
		return false;
	}

	ManagedReference<SceneObject*> parent = schematic->getParent().get();

	if (findQueueEntry(schematic->getObjectID()) >= 0 || (parent != nullptr && parent->isFactory())) {
		player->sendSystemMessage("That manufacturing schematic is already assigned to another factory.");
		return false;
	}

	bool match = false;

	for (int i = 0; i < craftingTabsSupported.size(); ++i) {
		if (craftingTabsSupported.get(i) == schematic->getDraftSchematic()->getToolTab()) {
			match = true;
			break;
		}
	}

	if (!match) {
		player->sendSystemMessage("This schematic is not compatible with this type of manufacturing installation.");
		return false;
	}

	if (!transferObject(schematic, -1, true, true)) {
		player->sendSystemMessage("The manufacturing schematic could not be stored in this factory.");
		return false;
	}

	queueSchematicIDs.add(schematic->getObjectID());
	queueSequence.add(queueSchematicIDs.size());
	queueRequestedLimits.add(requestedAmount);
	queueRemainingLimits.add(requestedAmount);
	queueStatuses.add(hasUnfinishedEntry ? QUEUE_WAITING : QUEUE_ACTIVE);
	queueBlockedReasons.add("");
	queueEvaluationTimes.add(0);

	int newIndex = queueSchematicIDs.size() - 1;

	if (!hasUnfinishedEntry && syncActiveQueueEntryToFactory() == nullptr)
		markQueueEntryBlocked(newIndex, QUEUE_BLOCKED_INVALID, "New manufacturing batch could not be synchronized.");

	unsigned long long activeAfterInsert = existingActiveID;

	for (int i = 0; i < queueStatuses.size(); ++i) {
		if (queueStatuses.get(i) == QUEUE_ACTIVE) {
			activeAfterInsert = queueSchematicIDs.get(i);
			break;
		}
	}

	info() << "Factory batch insertion accepted. FactoryID: " << getObjectID()
		<< " SchematicID: " << schematic->getObjectID()
		<< " QueueSizeBefore: " << previousQueueSize
		<< " Position: " << queueSchematicIDs.size()
		<< " RequestedBatch: " << requestedAmount
		<< " SchematicUsesRemaining: " << schematicUsesRemaining
		<< " ActiveSchematicID: " << activeAfterInsert;

	if (queueEnabled && !isActive())
		evaluateManufacturingQueue();

	return true;
}



/*
 * Opens a SUI with all manufacturing schematics available for the player to insert into factory
 */
void FactoryObjectImplementation::sendInsertManuSui(CreatureObject* player) {
	if (player == nullptr || !isOnAdminList(player))
		return;

	restoreQueueMetadata();

	if (queueSchematicIDs.size() >= MAX_FACTORY_QUEUE) {
		player->sendSystemMessage("This factory queue already contains the maximum of 10 manufacturing schematics.");
		sendManufacturingQueueSui(player);
		return;
	}

	ManagedReference<SuiListBox*> schematics =
		new SuiListBox(player, SuiWindowType::FACTORY_SCHEMATIC3BUTTON, SuiListBox::HANDLETHREEBUTTON);

	StringBuffer prompt;
	prompt << "Choose a manufacturing schematic to add to this factory queue.\n\n";
	prompt << "Queue: " << queueSchematicIDs.size() << " / " << MAX_FACTORY_QUEUE;

	schematics->setPromptText(prompt.toString());
	schematics->setHandlerText("handleUpdateSchematic");
	schematics->setPromptTitle("ADD MANUFACTURING SCHEMATIC");
	schematics->setOtherButton(true, "@back");
	schematics->setOkButton(true, "@add");
	schematics->setCancelButton(true, "@cancel");

	ManagedReference<SceneObject*> datapad = player->getSlottedObject("datapad");

	if (datapad == nullptr) {
		player->sendSystemMessage("Your datapad could not be accessed.");
		return;
	}

	for (int i = 0; i < datapad->getContainerObjectsSize(); ++i) {
		ManagedReference<SceneObject*> object = datapad->getContainerObject(i);

		if (object == nullptr || !object->isManufactureSchematic())
			continue;

		ManagedReference<ManufactureSchematic*> schematic =
			dynamic_cast<ManufactureSchematic*>(object.get());

		if (schematic == nullptr || schematic->getDraftSchematic() == nullptr)
			continue;

		uint32 tab = schematic->getDraftSchematic()->getToolTab();
		bool match = false;

		for (int j = 0; j < craftingTabsSupported.size(); ++j) {
			if (tab == craftingTabsSupported.get(j)) {
				match = true;
				break;
			}
		}

		if (!match)
			continue;

		String name = schematic->getCustomObjectName().isEmpty()
			? "@" + schematic->getObjectNameStringIdFile() + ":" + schematic->getObjectNameStringIdName()
			: schematic->getCustomObjectName().toString();

		schematics->addMenuItem(name, schematic->getObjectID());
	}

	schematics->setCallback(new InsertSchematicSuiCallback(server->getZoneServer()));
	schematics->setUsingObject(_this.getReferenceUnsafeStaticCast());
	player->getPlayerObject()->addSuiBox(schematics);
	player->sendMessage(schematics->generateMessage());
}

void FactoryObjectImplementation::sendManufacturingBatchAmountSui(CreatureObject* player, ManufactureSchematic* schematic, int defaultAmount) {
	if (player == nullptr || schematic == nullptr || !isOnAdminList(player) || !schematic->isASubChildOf(player))
		return;

	int schematicUsesRemaining = schematic->getManufactureLimit();

	if (schematicUsesRemaining <= 0) {
		player->sendSystemMessage("That manufacturing schematic has no uses remaining.");
		sendInsertManuSui(player);
		return;
	}

	if (defaultAmount < 1 || defaultAmount > schematicUsesRemaining)
		defaultAmount = schematicUsesRemaining;

	String name = schematic->getCustomObjectName().isEmpty()
		? "@" + schematic->getObjectNameStringIdFile() + ":" + schematic->getObjectNameStringIdName()
		: schematic->getCustomObjectName().toString();

	ManagedReference<SuiInputBox*> input =
		new SuiInputBox(player, SuiWindowType::FACTORY_QUEUE_BATCH_AMOUNT);

	StringBuffer prompt;
	prompt << name << "\n\n";
	prompt << "Manufacturing schematic uses remaining: " << schematicUsesRemaining << "\n\n";
	prompt << "Enter how many items this factory should manufacture for this batch.\n";
	prompt << "Minimum: 1   Maximum: " << schematicUsesRemaining << "\n\n";
	prompt << "Cancel returns to schematic selection.";

	input->setPromptTitle("PRODUCTION AMOUNT");
	input->setPromptText(prompt.toString());
	input->setMaxInputSize(10);
	input->setDefaultInput(String::valueOf(defaultAmount));
	input->setCancelButton(true, "@cancel");
	input->setOkButton(true, "@ok");
	input->setCallback(new FactoryQueueBatchAmountSuiCallback(server->getZoneServer(), schematic->getObjectID()));
	input->setUsingObject(_this.getReferenceUnsafeStaticCast());

	player->getPlayerObject()->addSuiBox(input);
	player->sendMessage(input->generateMessage());
}

void FactoryObjectImplementation::sendManufacturingBatchConfirmSui(CreatureObject* player, ManufactureSchematic* schematic, int requestedAmount) {
	if (player == nullptr || schematic == nullptr || !isOnAdminList(player) || !schematic->isASubChildOf(player))
		return;

	int schematicUsesRemaining = schematic->getManufactureLimit();

	if (requestedAmount < 1 || requestedAmount > schematicUsesRemaining) {
		player->sendSystemMessage(
			"This manufacturing schematic currently has " + String::valueOf(schematicUsesRemaining) +
			" uses remaining. Please choose a valid production amount.");

		sendManufacturingBatchAmountSui(player, schematic, schematicUsesRemaining);
		return;
	}

	if (!populateSchematicBlueprint(schematic)) {
		player->sendSystemMessage("The factory ingredient hopper is unavailable.");
		return;
	}

	ResourceManager* resourceManager =
		server->getZoneServer()->getResourceManager();

	String name = schematic->getCustomObjectName().isEmpty()
		? "@" + schematic->getObjectNameStringIdFile() + ":" + schematic->getObjectNameStringIdName()
		: schematic->getCustomObjectName().toString();

	ManagedReference<SuiListBox*> confirm =
		new SuiListBox(player, SuiWindowType::FACTORY_QUEUE_BATCH_CONFIRM, SuiListBox::HANDLETHREEBUTTON);

	confirm->setPromptTitle("CONFIRM MANUFACTURING BATCH");

	StringBuffer prompt;
	prompt << name << "\n\n";
	prompt << "Requested production: " << requestedAmount << "\n";
	prompt << "Schematic uses remaining: " << schematicUsesRemaining << "\n\n";
	prompt << "Exact resource/component identity and totals for this batch. ";
	prompt << "Hopper amounts are current snapshots; shortages do not prevent queueing.";

	confirm->setPromptText(prompt.toString());
	confirm->setOtherButton(true, "@back");
	confirm->setOkButton(true, "@add");
	confirm->setCancelButton(true, "@cancel");

	for (int i = 0; i < schematic->getBlueprintSize(); ++i) {
		BlueprintEntry* entry = schematic->getBlueprintEntry(i);

		if (entry == nullptr)
			continue;

		unsigned long long perItem = entry->getQuantity();
		unsigned long long batchRequired = perItem * (unsigned long long)requestedAmount;
		unsigned long long available = entry->getAvailableQuantity();
		unsigned long long missing = batchRequired > available ? batchRequired - available : 0;

		StringBuffer row;

		if (available >= batchRequired)
			row << "[READY] ";
		else if (available >= perItem)
			row << "[PARTIAL] ";
		else
			row << "[MISSING] ";

		appendFactoryQueueIngredientIdentity(row, entry, resourceManager);

		row << " | " << perItem << " ea";
		row << " | Need " << batchRequired;
		row << " | Have " << available;

		if (missing > 0)
			row << " | Short " << missing;

		confirm->addMenuItem(row.toString(), 0);
	}

	confirm->setCallback(
		new FactoryQueueBatchConfirmSuiCallback(
			server->getZoneServer(), schematic->getObjectID(), requestedAmount));

	confirm->setUsingObject(_this.getReferenceUnsafeStaticCast());
	player->getPlayerObject()->addSuiBox(confirm);
	player->sendMessage(confirm->generateMessage());
}

void FactoryObjectImplementation::sendManufacturingBatchEditAmountSui(CreatureObject* player, int queueIndex) {
	if (player == nullptr || !isOnAdminList(player))
		return;

	restoreQueueMetadata();

	if (queueIndex < 0 || queueIndex >= queueSchematicIDs.size()) {
		player->sendSystemMessage("That manufacturing queue entry is no longer available.");
		sendManufacturingQueueSui(player);
		return;
	}

	if (isActive() && queueStatuses.get(queueIndex) == QUEUE_ACTIVE) {
		player->sendSystemMessage("Stop the factory before changing the batch that is currently being manufactured.");
		sendManufacturingQueueEntrySui(player, queueIndex);
		return;
	}

	ManagedReference<ManufactureSchematic*> schematic =
		server->getZoneServer()->getObject(queueSchematicIDs.get(queueIndex)).castTo<ManufactureSchematic*>();

	if (schematic == nullptr) {
		player->sendSystemMessage("The selected manufacturing schematic could not be resolved.");
		sendManufacturingQueueSui(player);
		return;
	}

	if (queueStatuses.get(queueIndex) == QUEUE_COMPLETED && schematic->getManufactureLimit() <= 0) {
		player->sendSystemMessage("This completed manufacturing schematic has no lifetime uses remaining.");
		sendManufacturingQueueEntrySui(player, queueIndex);
		return;
	}

	ManagedReference<SceneObject*> parent = schematic->getParent().get();

	if (parent == nullptr || parent->getObjectID() != getObjectID()) {
		player->sendSystemMessage("The selected manufacturing schematic is not contained by this factory.");
		sendManufacturingQueueSui(player);
		return;
	}

	int currentRequested = queueRequestedLimits.get(queueIndex);
	int currentRemaining = queueRemainingLimits.get(queueIndex);
	int produced = currentRequested > currentRemaining ? currentRequested - currentRemaining : 0;
	int minimum = produced > 0 ? produced : 1;
	int maximum = produced + schematic->getManufactureLimit();

	if (maximum < minimum) {
		player->sendSystemMessage("This manufacturing batch cannot be resized because its remaining schematic uses are inconsistent.");
		sendManufacturingQueueEntrySui(player, queueIndex);
		return;
	}

	ManagedReference<SuiInputBox*> input =
		new SuiInputBox(player, SuiWindowType::FACTORY_QUEUE_BATCH_EDIT_AMOUNT);

	String name = schematic->getCustomObjectName().isEmpty()
		? "@" + schematic->getObjectNameStringIdFile() + ":" + schematic->getObjectNameStringIdName()
		: schematic->getCustomObjectName().toString();

	StringBuffer prompt;
	prompt << name << "\n\n";
	prompt << "Current Requested Batch: " << currentRequested << "\n";
	prompt << "Already Produced: " << produced << "\n";
	prompt << "Current Remaining: " << currentRemaining << "\n";
	prompt << "Schematic Uses Remaining: " << schematic->getManufactureLimit() << "\n\n";
	prompt << "Enter the NEW TOTAL batch size.\n";
	prompt << "Minimum: " << minimum << "   Maximum: " << maximum << "\n\n";

	if (queueStatuses.get(queueIndex) == QUEUE_COMPLETED)
		prompt << "This batch is COMPLETE. Enter a total greater than " << produced << " to reopen it for additional production.\n";
	else if (produced > 0)
		prompt << "Setting the total to " << produced << " will mark this batch complete with no additional production.\n";

	prompt << "Existing ingredients already in the factory hopper are not automatically removed if you reduce the batch.";

	input->setPromptTitle("UPDATE BATCH AMOUNT");
	input->setPromptText(prompt.toString());
	input->setMaxInputSize(10);
	input->setDefaultInput(String::valueOf(currentRequested));
	input->setCancelButton(true, "@cancel");
	input->setOkButton(true, "@ok");
	input->setCallback(
		new FactoryQueueBatchEditAmountSuiCallback(
			server->getZoneServer(), schematic->getObjectID()));
	input->setUsingObject(_this.getReferenceUnsafeStaticCast());

	player->getPlayerObject()->addSuiBox(input);
	player->sendMessage(input->generateMessage());
}

void FactoryObjectImplementation::sendManufacturingBatchEditConfirmSui(
		CreatureObject* player,
		int queueIndex,
		int requestedAmount) {

	if (player == nullptr || !isOnAdminList(player))
		return;

	restoreQueueMetadata();

	if (queueIndex < 0 || queueIndex >= queueSchematicIDs.size()) {
		player->sendSystemMessage("That manufacturing queue entry is no longer available.");
		sendManufacturingQueueSui(player);
		return;
	}

	if (isActive() && queueStatuses.get(queueIndex) == QUEUE_ACTIVE) {
		player->sendSystemMessage("Stop the factory before changing the batch that is currently being manufactured.");
		sendManufacturingQueueEntrySui(player, queueIndex);
		return;
	}

	ManagedReference<ManufactureSchematic*> schematic =
		server->getZoneServer()->getObject(queueSchematicIDs.get(queueIndex)).castTo<ManufactureSchematic*>();

	if (schematic == nullptr)
		return;

	if (queueStatuses.get(queueIndex) == QUEUE_COMPLETED && schematic->getManufactureLimit() <= 0) {
		player->sendSystemMessage("This completed manufacturing schematic has no lifetime uses remaining.");
		sendManufacturingQueueEntrySui(player, queueIndex);
		return;
	}

	int currentRequested = queueRequestedLimits.get(queueIndex);
	int currentRemaining = queueRemainingLimits.get(queueIndex);
	int produced = currentRequested > currentRemaining ? currentRequested - currentRemaining : 0;
	int minimum = produced > 0 ? produced : 1;
	int maximum = produced + schematic->getManufactureLimit();

	if (requestedAmount < minimum || requestedAmount > maximum) {
		player->sendSystemMessage(
			"Enter a total batch amount between " + String::valueOf(minimum) +
			" and " + String::valueOf(maximum) + ".");
		sendManufacturingBatchEditAmountSui(player, queueIndex);
		return;
	}

	int newRemaining = requestedAmount - produced;

	if (!populateSchematicBlueprint(schematic)) {
		player->sendSystemMessage("The factory ingredient hopper is unavailable.");
		return;
	}

	ResourceManager* resourceManager = server->getZoneServer()->getResourceManager();

	ManagedReference<SuiListBox*> confirm =
		new SuiListBox(player, SuiWindowType::FACTORY_QUEUE_BATCH_EDIT_CONFIRM, SuiListBox::HANDLETHREEBUTTON);

	confirm->setPromptTitle("CONFIRM BATCH UPDATE");

	StringBuffer prompt;
	prompt << "Current Requested: " << currentRequested << "\n";
	prompt << "Already Produced: " << produced << "\n";
	prompt << "New Requested: " << requestedAmount << "\n";
	prompt << "New Remaining: " << newRemaining << "\n\n";

	if (newRemaining == 0)
		prompt << "This will mark the batch COMPLETE immediately.";
	else
		prompt << "Requirements below are for the NEW remaining production amount.";

	prompt << "\nExisting hopper contents remain in the factory even if the batch is reduced.";

	confirm->setPromptText(prompt.toString());
	confirm->setOtherButton(true, "@back");
	confirm->setOkButton(true, "Update");
	confirm->setCancelButton(true, "@cancel");

	if (newRemaining <= 0) {
		confirm->addMenuItem("[COMPLETE] No additional items will be manufactured.", 0);
	} else {
		for (int i = 0; i < schematic->getBlueprintSize(); ++i) {
			BlueprintEntry* entry = schematic->getBlueprintEntry(i);

			if (entry == nullptr)
				continue;

			unsigned long long perItem = entry->getQuantity();
			unsigned long long batchRequired = perItem * (unsigned long long)newRemaining;
			unsigned long long available = entry->getAvailableQuantity();
			unsigned long long missing = batchRequired > available ? batchRequired - available : 0;

			StringBuffer row;

			if (available >= batchRequired)
				row << "[READY] ";
			else if (available >= perItem)
				row << "[PARTIAL] ";
			else
				row << "[MISSING] ";

			appendFactoryQueueIngredientIdentity(row, entry, resourceManager);

			row << " | " << perItem << " ea";
			row << " | Need " << batchRequired;
			row << " | Have " << available;

			if (missing > 0)
				row << " | Short " << missing;

			confirm->addMenuItem(row.toString(), 0);
		}
	}

	confirm->setCallback(
		new FactoryQueueBatchEditConfirmSuiCallback(
			server->getZoneServer(), schematic->getObjectID(), requestedAmount));
	confirm->setUsingObject(_this.getReferenceUnsafeStaticCast());

	player->getPlayerObject()->addSuiBox(confirm);
	player->sendMessage(confirm->generateMessage());
}

bool FactoryObjectImplementation::updateQueuedSchematicBatchAmount(
		CreatureObject* player,
		int queueIndex,
		int requestedAmount) {

	if (player == nullptr || !isOnAdminList(player))
		return false;

	restoreQueueMetadata();

	if (queueIndex < 0 || queueIndex >= queueSchematicIDs.size())
		return false;

	if (isActive() && queueStatuses.get(queueIndex) == QUEUE_ACTIVE) {
		player->sendSystemMessage("Stop the factory before changing the batch that is currently being manufactured.");
		return false;
	}

	ManagedReference<ManufactureSchematic*> schematic =
		server->getZoneServer()->getObject(queueSchematicIDs.get(queueIndex)).castTo<ManufactureSchematic*>();

	if (schematic == nullptr)
		return false;

	if (queueStatuses.get(queueIndex) == QUEUE_COMPLETED && schematic->getManufactureLimit() <= 0) {
		player->sendSystemMessage("This completed manufacturing schematic has no lifetime uses remaining.");
		return false;
	}

	ManagedReference<SceneObject*> parent = schematic->getParent().get();

	if (parent == nullptr || parent->getObjectID() != getObjectID())
		return false;

	int oldRequested = queueRequestedLimits.get(queueIndex);
	int oldRemaining = queueRemainingLimits.get(queueIndex);
	int produced = oldRequested > oldRemaining ? oldRequested - oldRemaining : 0;
	int minimum = produced > 0 ? produced : 1;
	int maximum = produced + schematic->getManufactureLimit();

	if (requestedAmount < minimum || requestedAmount > maximum) {
		player->sendSystemMessage(
			"Enter a total batch amount between " + String::valueOf(minimum) +
			" and " + String::valueOf(maximum) + ".");
		return false;
	}

	int newRemaining = requestedAmount - produced;
	bool wasActiveEntry = queueStatuses.get(queueIndex) == QUEUE_ACTIVE;
	bool wasCompletedEntry = queueStatuses.get(queueIndex) == QUEUE_COMPLETED;

	TransactionLog trx(asSceneObject(), player, schematic, TrxCode::FACTORYOPERATION);
	trx.setType("factory_queue_batch_update");
	trx.addState("factoryId", (uint64)getObjectID());
	trx.addState("playerId", (uint64)player->getObjectID());
	trx.addState("schematicId", (uint64)schematic->getObjectID());
	trx.addState("queuePosition", queueIndex + 1);
	trx.addState("oldRequested", oldRequested);
	trx.addState("oldRemaining", oldRemaining);
	trx.addState("produced", produced);
	trx.addState("newRequested", requestedAmount);
	trx.addState("newRemaining", newRemaining);
	trx.addState("schematicUsesRemaining", schematic->getManufactureLimit());

	queueRequestedLimits.set(queueIndex, requestedAmount);
	queueRemainingLimits.set(queueIndex, newRemaining);
	queueEvaluationTimes.set(queueIndex, (unsigned long long)Time().getTime());

	if (newRemaining <= 0) {
		queueStatuses.set(queueIndex, QUEUE_COMPLETED);
		queueBlockedReasons.set(queueIndex, "");
	} else {
		if (wasCompletedEntry)
			queueStatuses.set(queueIndex, QUEUE_WAITING);
		else if (wasActiveEntry && !isActive())
			queueStatuses.set(queueIndex, QUEUE_ACTIVE);

		refreshQueuedSchematicReadiness(queueIndex);
	}

	trx.commit();

	info() << "Factory queue batch amount updated. FactoryID: " << getObjectID()
		<< " PlayerID: " << player->getObjectID()
		<< " SchematicID: " << schematic->getObjectID()
		<< " QueuePosition: " << queueIndex + 1
		<< " OldRequested: " << oldRequested
		<< " Produced: " << produced
		<< " NewRequested: " << requestedAmount
		<< " NewRemaining: " << newRemaining
		<< " SchematicUsesRemaining: " << schematic->getManufactureLimit();

	player->sendSystemMessage(
		"Manufacturing batch updated to " + String::valueOf(requestedAmount) +
		" total items with " + String::valueOf(newRemaining) + " remaining.");

	if (queueEnabled && !isActive())
		evaluateManufacturingQueue();

	return true;
}






void FactoryObjectImplementation::sendManufacturingQueueSui(CreatureObject* player) {
	if (player == nullptr || !isOnAdminList(player))
		return;

	restoreQueueMetadata();

	// Refresh displayed readiness whenever the dashboard opens.
	// Do not mutate the currently running ACTIVE job. Power/maintenance
	// remain factory-wide dashboard state rather than per-entry noise.
	bool factoryWideBlocked =
		(!isActive() && getMaintenanceRate() != 0 && getSurplusMaintenance() <= 0) ||
		(!isActive() && getBasePowerRate() != 0 && getSurplusPower() <= 0);

	if (!factoryWideBlocked) {
		for (int i = 0; i < queueSchematicIDs.size(); ++i) {
			if (queueStatuses.get(i) == QUEUE_COMPLETED || queueRemainingLimits.get(i) <= 0)
				continue;

			if (isActive() && queueStatuses.get(i) == QUEUE_ACTIVE)
				continue;

			refreshQueuedSchematicReadiness(i);
		}
	}

	ManagedReference<SuiListBox*> queue =
		new SuiListBox(player, SuiWindowType::FACTORY_SCHEMATIC3BUTTON, SuiListBox::HANDLETHREEBUTTON);

	queue->setPromptTitle("MANUFACTURING QUEUE");

	String factoryState;

	if (!queueEnabled)
		factoryState = "STOPPED";
	else if (isActive())
		factoryState = "RUNNING";
	else
		factoryState = "PAUSED / WAITING";

	String blockedSummary;

	if (queueEnabled && !isActive()) {
		if (getMaintenanceRate() != 0 && getSurplusMaintenance() <= 0)
			blockedSummary = "Factory maintenance is insufficient.";
		else if (getBasePowerRate() != 0 && getSurplusPower() <= 0)
			blockedSummary = "Factory power is insufficient.";
		else {
			for (int i = 0; i < queueBlockedReasons.size(); ++i) {
				if (queueStatuses.get(i) != QUEUE_COMPLETED && !queueBlockedReasons.get(i).isEmpty()) {
					blockedSummary = queueBlockedReasons.get(i);
					break;
				}
			}
		}
	}

	StringBuffer prompt;
	prompt << "Factory Status: " << factoryState << "\n";
	prompt << "Queue: " << queueSchematicIDs.size() << " / " << MAX_FACTORY_QUEUE << "\n";

	if (queueSchematicIDs.size() > MAX_FACTORY_QUEUE)
		prompt << "Recovery State: remove entries until the queue is back to " << MAX_FACTORY_QUEUE << " or fewer.\n";

	prompt << "Queue Mode: Skip blocked entries\n";

	if (!blockedSummary.isEmpty())
		prompt << "Current Issue: " << blockedSummary << "\n";

	prompt << "\nBatch progress is separate from schematic lifetime uses.";
	prompt << "\nSelect a schematic and press OK to manage it. Use Add to queue another batch.";

	queue->setPromptText(prompt.toString());
	queue->setOtherButton(true, "@add");
	queue->setOkButton(true, "@ok");
	queue->setCancelButton(true, "@cancel");

	for (int i = 0; i < queueSchematicIDs.size(); ++i) {
		ManagedReference<ManufactureSchematic*> schematic =
			server->getZoneServer()->getObject(queueSchematicIDs.get(i)).castTo<ManufactureSchematic*>();

		String name = "Invalid schematic";
		int schematicUsesRemaining = 0;

		if (schematic != nullptr) {
			schematicUsesRemaining = schematic->getManufactureLimit();

			if (schematic->getCustomObjectName().isEmpty())
				name = "@" + schematic->getObjectNameStringIdFile() + ":" + schematic->getObjectNameStringIdName();
			else
				name = schematic->getCustomObjectName().toString();
		}

		String status = "WAITING";

		switch (queueStatuses.get(i)) {
		case QUEUE_ACTIVE: status = queueEnabled && isActive() ? "RUNNING" : "NEXT"; break;
		case QUEUE_BLOCKED_RESOURCES: status = "MISSING RESOURCE"; break;
		case QUEUE_BLOCKED_COMPONENTS: status = "MISSING COMPONENT"; break;
		case QUEUE_BLOCKED_OUTPUT_FULL: status = "OUTPUT FULL"; break;
		case QUEUE_BLOCKED_POWER: status = "NEEDS POWER"; break;
		case QUEUE_BLOCKED_MAINTENANCE: status = "NEEDS MAINTENANCE"; break;
		case QUEUE_BLOCKED_INVALID: status = "INVALID"; break;
		case QUEUE_COMPLETED: status = "COMPLETE"; break;
		default: break;
		}

		int requested = i < queueRequestedLimits.size() ? queueRequestedLimits.get(i) : 0;
		int remaining = i < queueRemainingLimits.size() ? queueRemainingLimits.get(i) : 0;
		int produced = requested > remaining ? requested - remaining : 0;

		StringBuffer row;
		row << (i + 1) << ". [" << status << "] " << name;
		row << " | Batch " << produced << "/" << requested;
		row << " | Left " << remaining;
		row << " | Schematic Uses " << schematicUsesRemaining;

		if (i < queueBlockedReasons.size() && !queueBlockedReasons.get(i).isEmpty())
			row << " | " << queueBlockedReasons.get(i);

		queue->addMenuItem(row.toString(), queueSchematicIDs.get(i));
	}

	if (queueSchematicIDs.size() == 0)
		queue->addMenuItem("The manufacturing queue is empty. Choose Add to begin.", 0);

	queue->setCallback(new ManageFactoryQueueSuiCallback(server->getZoneServer()));
	queue->setUsingObject(_this.getReferenceUnsafeStaticCast());

	player->getPlayerObject()->addSuiBox(queue);
	player->sendMessage(queue->generateMessage());
}


void FactoryObjectImplementation::sendManufacturingQueueEntrySui(CreatureObject* player, int queueIndex) {
	if (player == nullptr || !isOnAdminList(player))
		return;

	restoreQueueMetadata();

	if (queueIndex < 0 || queueIndex >= queueSchematicIDs.size()) {
		player->sendSystemMessage("That manufacturing queue entry is no longer available.");
		sendManufacturingQueueSui(player);
		return;
	}

	unsigned long long schematicID = queueSchematicIDs.get(queueIndex);

	ManagedReference<ManufactureSchematic*> schematic =
		server->getZoneServer()->getObject(schematicID).castTo<ManufactureSchematic*>();

	String name = "Invalid schematic";
	int schematicUsesRemaining = 0;

	if (schematic != nullptr) {
		schematicUsesRemaining = schematic->getManufactureLimit();

		name = schematic->getCustomObjectName().isEmpty()
			? "@" + schematic->getObjectNameStringIdFile() + ":" + schematic->getObjectNameStringIdName()
			: schematic->getCustomObjectName().toString();
	}

	String status = "WAITING";

	switch (queueStatuses.get(queueIndex)) {
	case QUEUE_ACTIVE: status = queueEnabled && isActive() ? "RUNNING" : "NEXT"; break;
	case QUEUE_BLOCKED_RESOURCES: status = "MISSING RESOURCE"; break;
	case QUEUE_BLOCKED_COMPONENTS: status = "MISSING COMPONENT"; break;
	case QUEUE_BLOCKED_OUTPUT_FULL: status = "OUTPUT FULL"; break;
	case QUEUE_BLOCKED_POWER: status = "NEEDS POWER"; break;
	case QUEUE_BLOCKED_MAINTENANCE: status = "NEEDS MAINTENANCE"; break;
	case QUEUE_BLOCKED_INVALID: status = "INVALID"; break;
	case QUEUE_COMPLETED: status = "COMPLETE"; break;
	default: break;
	}

	int requested = queueIndex < queueRequestedLimits.size() ? queueRequestedLimits.get(queueIndex) : 0;
	int remaining = queueIndex < queueRemainingLimits.size() ? queueRemainingLimits.get(queueIndex) : 0;
	int produced = requested > remaining ? requested - remaining : 0;

	ManagedReference<SuiListBox*> actions =
		new SuiListBox(player, SuiWindowType::FACTORY_SCHEMATIC3BUTTON, SuiListBox::HANDLETHREEBUTTON);

	actions->setPromptTitle("QUEUE ENTRY");

	StringBuffer prompt;
	prompt << name << "\n\n";
	prompt << "Queue Position: " << (queueIndex + 1) << " of " << queueSchematicIDs.size() << "\n";
	prompt << "Status: " << status << "\n\n";
	prompt << "Requested Batch: " << requested << "\n";
	prompt << "Batch Produced: " << produced << "\n";
	prompt << "Batch Remaining: " << remaining << "\n";
	prompt << "Schematic Uses Remaining: " << schematicUsesRemaining;

	if (queueIndex < queueBlockedReasons.size() && !queueBlockedReasons.get(queueIndex).isEmpty())
		prompt << "\nReason: " << queueBlockedReasons.get(queueIndex);

	if (queueStatuses.get(queueIndex) == QUEUE_COMPLETED && schematic != nullptr && schematicUsesRemaining > 0)
		prompt << "\n\nThis batch is complete. Use Update Batch Amount to manufacture additional items, or remove the schematic to return it to your datapad.";

	actions->setPromptText(prompt.toString());
	actions->setOtherButton(true, "@back");
	actions->setOkButton(true, "@ok");
	actions->setCancelButton(true, "@cancel");

	if (schematic != nullptr)
		actions->addMenuItem("View Ingredient Requirements", ManageFactoryQueueSuiCallback::ACTION_VIEW_REQUIREMENTS);

	if (schematic != nullptr && queueStatuses.get(queueIndex) != QUEUE_COMPLETED && remaining > 0)
		actions->addMenuItem("Load Batch Ingredients", ManageFactoryQueueSuiCallback::ACTION_LOAD_BATCH_INGREDIENTS);

	if (schematic != nullptr &&
			!(isActive() && queueStatuses.get(queueIndex) == QUEUE_ACTIVE) &&
			(queueStatuses.get(queueIndex) != QUEUE_COMPLETED || schematic->getManufactureLimit() > 0))
		actions->addMenuItem("Update Batch Amount", ManageFactoryQueueSuiCallback::ACTION_UPDATE_BATCH_AMOUNT);

	actions->addMenuItem("Manage Ingredient Hopper", ManageFactoryQueueSuiCallback::ACTION_MANAGE_INGREDIENT_HOPPER);

	if (queueIndex > 0)
		actions->addMenuItem("Move Up", ManageFactoryQueueSuiCallback::ACTION_MOVE_UP);

	if (queueIndex < queueSchematicIDs.size() - 1)
		actions->addMenuItem("Move Down", ManageFactoryQueueSuiCallback::ACTION_MOVE_DOWN);

	if (queueStatuses.get(queueIndex) != QUEUE_COMPLETED)
		actions->addMenuItem("Recheck Status", ManageFactoryQueueSuiCallback::ACTION_RECHECK);

	actions->addMenuItem("Remove From Queue", ManageFactoryQueueSuiCallback::ACTION_REMOVE);

	actions->setCallback(new ManageFactoryQueueSuiCallback(server->getZoneServer(), schematicID));
	actions->setUsingObject(_this.getReferenceUnsafeStaticCast());

	player->getPlayerObject()->addSuiBox(actions);
	player->sendMessage(actions->generateMessage());
}



void FactoryObjectImplementation::sendQueuedSchematicIngredientsSui(CreatureObject* player, int queueIndex) {
	if (player == nullptr || !isOnAdminList(player))
		return;

	restoreQueueMetadata();

	if (queueIndex < 0 || queueIndex >= queueSchematicIDs.size()) {
		player->sendSystemMessage("That manufacturing queue entry is no longer available.");
		return;
	}

	unsigned long long schematicID = queueSchematicIDs.get(queueIndex);

	ManagedReference<ManufactureSchematic*> schematic =
		server->getZoneServer()->getObject(schematicID).castTo<ManufactureSchematic*>();

	if (schematic == nullptr) {
		player->sendSystemMessage("The selected manufacturing schematic could not be resolved.");
		return;
	}

	if (!populateSchematicBlueprint(schematic)) {
		player->sendSystemMessage("The factory ingredient hopper is unavailable.");
		return;
	}

	ResourceManager* resourceManager =
		server->getZoneServer()->getResourceManager();

	int requested = queueIndex < queueRequestedLimits.size() ? queueRequestedLimits.get(queueIndex) : 0;
	int remaining = queueIndex < queueRemainingLimits.size() ? queueRemainingLimits.get(queueIndex) : 0;
	int produced = requested > remaining ? requested - remaining : 0;

	ManagedReference<SuiListBox*> list =
		new SuiListBox(player, SuiWindowType::FACTORY_INGREDIENTS, SuiListBox::HANDLETWOBUTTON);

	list->setPromptTitle("SCHEMATIC REQUIREMENTS");

	StringBuffer prompt;
	prompt << "Requested Batch: " << requested;
	prompt << " | Produced: " << produced;
	prompt << " | Remaining: " << remaining << "\n";
	prompt << "Schematic Uses Remaining: " << schematic->getManufactureLimit() << "\n\n";
	prompt << "Exact resource/component identity and totals for the remaining batch. ";
	prompt << "Hopper amounts are current.";

	list->setPromptText(prompt.toString());
	list->setOkButton(true, "@back");
	list->setCancelButton(true, "@cancel");

	for (int i = 0; i < schematic->getBlueprintSize(); ++i) {
		BlueprintEntry* entry = schematic->getBlueprintEntry(i);

		if (entry == nullptr)
			continue;

		unsigned long long perItem = entry->getQuantity();
		unsigned long long batchRequired = perItem * (unsigned long long)remaining;
		unsigned long long available = entry->getAvailableQuantity();
		unsigned long long missing = batchRequired > available ? batchRequired - available : 0;

		StringBuffer row;

		if (remaining <= 0)
			row << "[COMPLETE] ";
		else if (available >= batchRequired)
			row << "[READY] ";
		else if (available >= perItem)
			row << "[PARTIAL] ";
		else
			row << "[MISSING] ";

		appendFactoryQueueIngredientIdentity(row, entry, resourceManager);

		row << " | " << perItem << " ea";
		row << " | Need " << batchRequired;
		row << " | Have " << available;

		if (missing > 0)
			row << " | Short " << missing;

		list->addMenuItem(row.toString(), 0);
	}

	list->setCallback(new ManageFactoryQueueSuiCallback(server->getZoneServer(), schematicID));
	list->setUsingObject(_this.getReferenceUnsafeStaticCast());

	player->getPlayerObject()->addSuiBox(list);
	player->sendMessage(list->generateMessage());
}

void FactoryObjectImplementation::sendLoadBatchIngredientsSui(CreatureObject* player, int queueIndex) {
	if (player == nullptr || !isOnAdminList(player))
		return;

	restoreQueueMetadata();

	if (queueIndex < 0 || queueIndex >= queueSchematicIDs.size()) {
		player->sendSystemMessage("That manufacturing queue entry is no longer available.");
		sendManufacturingQueueSui(player);
		return;
	}

	if (queueStatuses.get(queueIndex) == QUEUE_COMPLETED || queueRemainingLimits.get(queueIndex) <= 0) {
		player->sendSystemMessage("That manufacturing batch is already complete.");
		sendManufacturingQueueEntrySui(player, queueIndex);
		return;
	}

	unsigned long long schematicID = queueSchematicIDs.get(queueIndex);

	ManagedReference<ManufactureSchematic*> schematic =
		server->getZoneServer()->getObject(schematicID).castTo<ManufactureSchematic*>();

	if (schematic == nullptr) {
		player->sendSystemMessage("The selected manufacturing schematic could not be resolved.");
		return;
	}

	if (!populateSchematicBlueprint(schematic)) {
		player->sendSystemMessage("The factory ingredient hopper is unavailable.");
		return;
	}

	int batchRemaining = queueRemainingLimits.get(queueIndex);

	ManagedReference<SuiListBox*> preview =
		new SuiListBox(player, SuiWindowType::FACTORY_QUEUE_LOAD_INGREDIENTS, SuiListBox::HANDLETHREEBUTTON);

	preview->setPromptTitle("LOAD BATCH INGREDIENTS");

	StringBuffer prompt;
	prompt << "Batch Remaining: " << batchRemaining << "\n\n";
	prompt << "Only items directly in your inventory are considered. Bags and other inventory containers are never searched.\n";
	prompt << "Only exact factory matches are eligible. Resources and factory crates are split when needed so excess is not intentionally loaded.\n\n";
	prompt << "Nothing moves until you press OK. Hopper capacity and contents are rechecked before loading.";

	preview->setPromptText(prompt.toString());
	preview->setOtherButton(true, "@back");
	preview->setOkButton(true, "@ui:ok");
	preview->setCancelButton(true, "@ui:cancel");

	bool hasShortage = false;
	ResourceManager* resourceManager = server->getZoneServer()->getResourceManager();

	for (int i = 0; i < schematic->getBlueprintSize(); ++i) {
		BlueprintEntry* entry = schematic->getBlueprintEntry(i);

		if (entry == nullptr)
			continue;

		unsigned long long totalNeeded =
			(unsigned long long)entry->getQuantity() * (unsigned long long)batchRemaining;

		unsigned long long hopperQuantity = entry->getAvailableQuantity();
		unsigned long long shortage =
			totalNeeded > hopperQuantity ? totalNeeded - hopperQuantity : 0;

		unsigned long long inventoryQuantity =
			getFactoryQueueInventoryMatchQuantity(player, entry);

		unsigned long long plannedLoad =
			getFactoryQueueInventoryLoadableQuantity(player, entry, (int)shortage);

		unsigned long long stillMissing =
			shortage > plannedLoad ? shortage - plannedLoad : 0;

		StringBuffer row;

		if (shortage == 0) {
			row << "[READY] ";
		} else if (plannedLoad >= shortage) {
			row << "[LOAD] ";
			hasShortage = true;
		} else if (plannedLoad > 0) {
			row << "[PARTIAL] ";
			hasShortage = true;
		} else {
			row << "[MISSING] ";
			hasShortage = true;
		}

		appendFactoryQueueIngredientIdentity(row, entry, resourceManager);

		row << " | Need " << totalNeeded;
		row << " | Hopper " << hopperQuantity;
		row << " | Inv " << inventoryQuantity;

		if (shortage > 0)
			row << " | Load " << plannedLoad;

		if (stillMissing > 0)
			row << " | Still Short " << stillMissing;

		preview->addMenuItem(row.toString(), 0);
	}

	if (!hasShortage)
		preview->addMenuItem("[READY] The factory hopper already contains the full remaining batch requirements.", 0);

	preview->setCallback(new ManageFactoryQueueSuiCallback(server->getZoneServer(), schematicID));
	preview->setUsingObject(_this.getReferenceUnsafeStaticCast());

	player->getPlayerObject()->addSuiBox(preview);
	player->sendMessage(preview->generateMessage());
}

void FactoryObjectImplementation::sendFactoryIngredientHopperManagerSui(CreatureObject* player, int queueIndex) {
	if (player == nullptr || !isOnAdminList(player))
		return;

	restoreQueueMetadata();

	if (queueIndex < 0 || queueIndex >= queueSchematicIDs.size()) {
		player->sendSystemMessage("That manufacturing queue entry is no longer available.");
		sendManufacturingQueueSui(player);
		return;
	}

	ManagedReference<SceneObject*> inputHopper = getSlottedObject("ingredient_hopper");

	if (inputHopper == nullptr) {
		player->sendSystemMessage("The factory ingredient hopper could not be accessed.");
		return;
	}

	ManagedReference<SuiListBox*> manager =
		new SuiListBox(player, SuiWindowType::FACTORY_QUEUE_HOPPER_MANAGER, SuiListBox::HANDLETHREEBUTTON);

	manager->setPromptTitle("MANAGE INGREDIENT HOPPER");

	StringBuffer prompt;
	prompt << "Server-side hopper contents: " << inputHopper->getContainerObjectsSize() << " object(s).\n\n";
	prompt << "This reads the actual factory container directly, even if the stock hopper window does not render an item.\n";

	if (isActive())
		prompt << "The factory is RUNNING. Hopper contents are viewable, but ingredients cannot be returned until production is stopped.";
	else
		prompt << "Select one object and press Return to move that exact stack/crate back to your inventory.";

	manager->setPromptText(prompt.toString());
	manager->setOtherButton(true, "@back");
	manager->setOkButton(true, "Retrieve");
	manager->setCancelButton(true, "@cancel");

	for (int i = 0; i < inputHopper->getContainerObjectsSize(); ++i) {
		ManagedReference<TangibleObject*> object =
			inputHopper->getContainerObject(i).castTo<TangibleObject*>();

		if (object == nullptr)
			continue;

		int quantity = getFactoryQueueInventoryObjectQuantity(object);

		StringBuffer row;
		row << object->getDisplayedName();

		if (object->isResourceContainer())
			row << " | Resource";
		else if (object->isFactoryCrate())
			row << " | Factory Crate";

		row << " | Qty " << quantity;
		row << " | OID " << object->getObjectID();

		manager->addMenuItem(row.toString(), object->getObjectID());
	}

	if (inputHopper->getContainerObjectsSize() == 0)
		manager->addMenuItem("The server-side ingredient hopper is empty.", 0);

	manager->setCallback(
		new ManageFactoryQueueSuiCallback(
			server->getZoneServer(), queueSchematicIDs.get(queueIndex)));

	manager->setUsingObject(_this.getReferenceUnsafeStaticCast());

	player->getPlayerObject()->addSuiBox(manager);
	player->sendMessage(manager->generateMessage());
}


bool FactoryObjectImplementation::returnFactoryIngredientToInventory(CreatureObject* player, unsigned long long objectID) {
	if (player == nullptr || !isOnAdminList(player) || objectID == 0)
		return false;

	if (isActive()) {
		player->sendSystemMessage("Stop the factory before returning ingredients from the hopper.");
		return false;
	}

	ManagedReference<SceneObject*> inputHopper = getSlottedObject("ingredient_hopper");
	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");

	if (inputHopper == nullptr || inventory == nullptr)
		return false;

	ManagedReference<TangibleObject*> object =
		server->getZoneServer()->getObject(objectID).castTo<TangibleObject*>();

	if (object == nullptr || object->getParentID() != inputHopper->getObjectID()) {
		player->sendSystemMessage("That ingredient is no longer in this factory hopper.");
		return false;
	}

	String transferError;

	if (inventory->canAddObject(object, -1, transferError) != 0) {
		player->sendSystemMessage(
			"The ingredient could not be returned to your inventory. Make sure you have enough inventory space.");

		info() << "Factory hopper return preflight rejected. FactoryID: " << getObjectID()
			<< " PlayerID: " << player->getObjectID()
			<< " IngredientOID: " << objectID
			<< " Reason: " << transferError;

		return false;
	}

	int quantity = getFactoryQueueInventoryObjectQuantity(object);

	Locker objectLocker(object, player);

	TransactionLog trx(inputHopper.get(), inventory.get(), object.get(), TrxCode::FACTORYOPERATION);
	trx.setType("factory_queue_hopper_return");
	trx.addRelatedObject(asSceneObject());
	trx.addState("factoryId", (uint64)getObjectID());
	trx.addState("playerId", (uint64)player->getObjectID());
	trx.addState("ingredientObjectId", (uint64)objectID);
	trx.addState("quantity", quantity);
	trx.addState("resourceContainer", object->isResourceContainer());
	trx.addState("factoryCrate", object->isFactoryCrate());

	if (!inventory->transferObject(object, -1, true)) {
		trx.abort() << "Factory queue ingredient return transfer failed.";

		player->sendSystemMessage(
			"The ingredient could not be returned to your inventory. Make sure you have enough inventory space.");
		return false;
	}

	inventory->broadcastObject(object, true);
	object->sendTo(player, true, true);

	trx.commit();

	info() << "Factory hopper ingredient returned. FactoryID: " << getObjectID()
		<< " PlayerID: " << player->getObjectID()
		<< " IngredientOID: " << objectID
		<< " Quantity: " << quantity;

	player->sendSystemMessage(
		"Returned " + object->getDisplayedName() + " to your inventory.");

	return true;
}



void FactoryObjectImplementation::loadBatchIngredientsFromInventory(CreatureObject* player, int queueIndex) {
	if (player == nullptr || !isOnAdminList(player))
		return;

	restoreQueueMetadata();

	if (queueIndex < 0 || queueIndex >= queueSchematicIDs.size())
		return;

	if (queueStatuses.get(queueIndex) == QUEUE_COMPLETED || queueRemainingLimits.get(queueIndex) <= 0) {
		player->sendSystemMessage("That manufacturing batch is already complete.");
		return;
	}

	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");
	ManagedReference<SceneObject*> inputHopper = getSlottedObject("ingredient_hopper");

	if (inventory == nullptr || inputHopper == nullptr) {
		player->sendSystemMessage("The inventory or factory ingredient hopper could not be accessed.");
		return;
	}

	unsigned long long schematicID = queueSchematicIDs.get(queueIndex);

	ManagedReference<ManufactureSchematic*> schematic =
		server->getZoneServer()->getObject(schematicID).castTo<ManufactureSchematic*>();

	if (schematic == nullptr) {
		player->sendSystemMessage("The selected manufacturing schematic could not be resolved.");
		return;
	}

	if (!populateSchematicBlueprint(schematic)) {
		player->sendSystemMessage("The factory ingredient hopper is unavailable.");
		return;
	}

	int batchRemaining = queueRemainingLimits.get(queueIndex);
	int totalLoaded = 0;
	StringBuffer summary;

	summary << "Batch ingredient load complete:";

	for (int i = 0; i < schematic->getBlueprintSize(); ++i) {
		BlueprintEntry* entry = schematic->getBlueprintEntry(i);

		if (entry == nullptr)
			continue;

		int totalNeeded = entry->getQuantity() * batchRemaining;
		int hopperBefore = entry->getAvailableQuantity();
		int shortage = totalNeeded > hopperBefore ? totalNeeded - hopperBefore : 0;

		if (shortage <= 0)
			continue;

		int loaded = loadFactoryQueueIngredientFromInventory(player, entry, shortage, schematicID, queueIndex);
		totalLoaded += loaded;

		populateSchematicBlueprint(schematic);

		int hopperAfter = entry->getAvailableQuantity();
		int stillMissing = totalNeeded > hopperAfter ? totalNeeded - hopperAfter : 0;

		summary << "\n" << entry->getDisplayedName() << ": loaded " << loaded;

		if (stillMissing > 0)
			summary << ", still missing " << stillMissing;
		else
			summary << ", ready";
	}

	if (totalLoaded <= 0) {
		player->sendSystemMessage(
			"No matching batch ingredients were loaded from your direct inventory. "
			"Check the preview, inventory location, exact resource/component identity, and hopper capacity.");
	} else {
		player->sendSystemMessage(summary.toString());

		info() << "Factory batch ingredients loaded from inventory. FactoryID: " << getObjectID()
			<< " PlayerID: " << player->getObjectID()
			<< " SchematicID: " << schematicID
			<< " QueuePosition: " << queueIndex + 1
			<< " BatchRemaining: " << batchRemaining
			<< " TotalLoadedUnits: " << totalLoaded;
	}

	retryQueuedSchematic(queueIndex);
}








/*
 * Opens a SUI with all manufacturing schematics available for the player to insert into factory
 */
void FactoryObjectImplementation::sendIngredientsNeededSui(CreatureObject* player) {
	if (player == nullptr)
		return;

	restoreQueueMetadata();

	if (queueSchematicIDs.size() == 0) {
		player->sendSystemMessage("No manufacturing schematic is currently queued.");
		return;
	}

	int queueIndex = -1;

	for (int i = 0; i < queueStatuses.size(); ++i) {
		if (queueStatuses.get(i) == QUEUE_ACTIVE) {
			queueIndex = i;
			break;
		}
	}

	if (queueIndex < 0) {
		for (int i = 0; i < queueSchematicIDs.size(); ++i) {
			ManagedReference<ManufactureSchematic*> schematic = server->getZoneServer()->getObject(queueSchematicIDs.get(i)).castTo<ManufactureSchematic*>();

			if (schematic != nullptr) {
				queueIndex = i;
				break;
			}
		}
	}

	if (queueIndex < 0) {
		player->sendSystemMessage("No valid manufacturing schematic is available in this factory queue.");
		return;
	}

	sendQueuedSchematicIngredientsSui(player, queueIndex);
}


void FactoryObjectImplementation::sendIngredientHopper(CreatureObject* player) {
	if (player == nullptr)
		return;

	ManagedReference<SceneObject*> inputHopper = getSlottedObject("ingredient_hopper");

	if (inputHopper == nullptr)
		return;

#ifdef DEBUG_FACTORIES
	info(true) << "sendIngredientHopper - Player: " << player->getFirstName();
#endif

	// Match the proven output-hopper client flow: introduce the container,
	// open it, then explicitly introduce each current child once with root
	// notification enabled. This is required for server-created split resource
	// stacks / factory crates that otherwise exist correctly server-side but
	// may not render in the stock client hopper window.
	inputHopper->sendWithoutContainerObjectsTo(player);

	ClientOpenContainerMessage* cont = new ClientOpenContainerMessage(inputHopper);
	player->sendMessage(cont);

	int hopperSize = inputHopper->getContainerObjectsSize();

#ifdef DEBUG_FACTORIES
	info(true) << "sendIngredientHopper - Hopper Size = " << hopperSize;
#endif

	for (int i = 0; i < hopperSize; ++i) {
		ManagedReference<SceneObject*> child = inputHopper->getContainerObject(i);

		if (child == nullptr)
			continue;

#ifdef DEBUG_FACTORIES
		child->info(true) << "Sending Ingredient Hopper Object To Player: "
			<< player->getDisplayedName()
			<< " Object: " << child->getDisplayedName();
#endif

		child->sendTo(player, true, true);
	}

	inputHopper->notifyObservers(ObserverEventType::OPENCONTAINER, player);
}


void FactoryObjectImplementation::sendOutputHopper(CreatureObject* player) {
	ManagedReference<SceneObject*> outputHopper = getSlottedObject("output_hopper");

	if (outputHopper == nullptr) {
		return;
	}

#ifdef DEBUG_FACTORIES
	info(true) << "sendOutputHopper - Player: " << player->getFirstName();
#endif

	outputHopper->sendWithoutContainerObjectsTo(player);

	ClientOpenContainerMessage* cont = new ClientOpenContainerMessage(outputHopper);
	player->sendMessage(cont);

	int hopperSize = outputHopper->getContainerObjectsSize();

#ifdef DEBUG_FACTORIES
	info(true) << "sendOutputHopper - Hopper Size = " << hopperSize;
#endif

	for (int j = 0; j < hopperSize; ++j) {
		SceneObject* child = outputHopper->getContainerObject(j);

		if (child == nullptr) {
			continue;
		}

#ifdef DEBUG_FACTORIES
		child->info(true) << "Sending Object To Player: " << player->getDisplayedName() << " Object: " << child->getDisplayedName();
#endif

		child->sendTo(player, true, true);
	}
}

void FactoryObjectImplementation::openHopper(Observable* observable, ManagedObject* arg1) {
	if (observable == nullptr || arg1 == nullptr)
		return;

	ManagedReference<CreatureObject*> player = cast<CreatureObject*>(arg1);
	ManagedReference<SceneObject*> outputHopper = getSlottedObject("output_hopper");
	ManagedReference<SceneObject*> sceneObserv = cast<SceneObject*>(observable);

	if (player == nullptr || outputHopper == nullptr || sceneObserv == nullptr)
		return;

#ifdef DEBUG_FACTORIES
	info(true) << "openHopper - Player: " << player->getFirstName();
#endif

	Locker clock(player, _this.getReferenceUnsafeStaticCast());

	addOperator(player);
}

void FactoryObjectImplementation::closeHopper(Observable* observable, ManagedObject* arg1) {
#ifdef DEBUG_FACTORIES
	info(true) << "closeHopper";
#endif

	ManagedReference<CreatureObject*> player = cast<CreatureObject*>(arg1);
	ManagedReference<SceneObject*> hopper = cast<SceneObject*>(observable);

	if (player == nullptr || hopper == nullptr)
		return;

#ifdef DEBUG_FACTORIES
	info(true) << "closeHopper - Player: " << player->getFirstName();
#endif

	FactoryObject* thisFactory = _this.getReferenceUnsafeStaticCast();

	Locker lock(thisFactory);
	/*
	for (int i = 0; i < outputHopper->getContainerObjectsSize(); ++i) {
		ManagedReference<SceneObject*> item = outputHopper->getContainerObject(i);

		if (item == nullptr)
			continue;

#ifdef DEBUG_FACTORIES
		info(true) << "closeHopper - Item sending destroy: " << item->getDisplayedName();
#endif
		item->sendDestroyTo(player);
	}

#ifdef DEBUG_FACTORIES
		info(true) << "closeHopper - Hopper sending destroy.";
#endif

	hopper->sendDestroyTo(player);*/

	Locker clock(player, thisFactory);

	removeOperator(player);
}

void FactoryObjectImplementation::handleInsertFactorySchem(CreatureObject* player, ManufactureSchematic* schematic) {
	if (player == nullptr || schematic == nullptr || !schematic->isASubChildOf(player))
		return;

	sendManufacturingBatchAmountSui(player, schematic, schematic->getManufactureLimit());
}



bool FactoryObjectImplementation::handleRemoveFactorySchem(CreatureObject* player) {
	int activeIndex = -1;
	restoreQueueMetadata();
	for (int i = 0; i < queueStatuses.size(); ++i)
		if (queueStatuses.get(i) == QUEUE_ACTIVE) { activeIndex = i; break; }
	if (activeIndex < 0 && queueSchematicIDs.size() > 0) activeIndex = 0;
	return removeQueuedSchematic(player, activeIndex);
}

bool FactoryObjectImplementation::removeQueuedSchematic(CreatureObject* player, int queueIndex) {
	if (player == nullptr || !isOnAdminList(player) || queueIndex < 0)
		return false;

	restoreQueueMetadata();

	if (queueIndex >= queueSchematicIDs.size())
		return false;

	if (queueStatuses.get(queueIndex) == QUEUE_ACTIVE && isActive()) {
		player->sendSystemMessage("Stop the factory before removing the active schematic.");
		return false;
	}

	auto removeMetadataAt = [this](int index) {
		queueSchematicIDs.remove(index);
		queueSequence.remove(index);
		queueRequestedLimits.remove(index);
		queueRemainingLimits.remove(index);
		queueStatuses.remove(index);
		queueBlockedReasons.remove(index);
		queueEvaluationTimes.remove(index);

		for (int i = 0; i < queueSequence.size(); ++i)
			queueSequence.set(i, i + 1);
	};

	unsigned long long schematicID = queueSchematicIDs.get(queueIndex);
	ManagedReference<SceneObject*> schematic = server->getZoneServer()->getObject(schematicID);

	if (schematic == nullptr) {
		removeMetadataAt(queueIndex);

		player->sendSystemMessage("The invalid manufacturing queue entry was removed.");
		info() << "Invalid factory queue metadata removed. FactoryID: " << getObjectID()
			<< " SchematicID: " << schematicID << " Position: " << queueIndex + 1;

		restoreQueueMetadata();
		evaluateManufacturingQueue();
		return true;
	}

	if (!schematic->isManufactureSchematic())
		return false;

	ManagedReference<ManufactureSchematic*> manuSchem = schematic.castTo<ManufactureSchematic*>();

	if (manuSchem == nullptr)
		return false;

	ManagedReference<SceneObject*> parent = schematic->getParent().get();

	// A stale metadata row must never pull a schematic out of another factory,
	// datapad, or container. Remove only the stale queue metadata.
	if (parent == nullptr || parent->getObjectID() != getObjectID()) {
		removeMetadataAt(queueIndex);

		player->sendSystemMessage("Removed stale factory queue metadata. The schematic itself was not moved.");
		warning() << "Stale factory queue metadata removed without moving object. FactoryID: " << getObjectID()
			<< " SchematicID: " << schematicID << " Position: " << queueIndex + 1
			<< " ParentID: " << (parent != nullptr ? parent->getObjectID() : 0);

		restoreQueueMetadata();
		evaluateManufacturingQueue();
		return true;
	}

	ManagedReference<SceneObject*> datapad = player->getSlottedObject("datapad");

	if (datapad == nullptr)
		return false;

	Locker locker(schematic);

	TransactionLog trx(asSceneObject(), player, schematic, TrxCode::FACTORYOPERATION);

	int dataSize = manuSchem->getDataSize();

	if ((dataSize + datapad->getContainerObjectsSize()) > datapad->getContainerVolumeLimit()) {
		trx.abort() << "Failed to transfer schematic out of factory due to full datapad.";

		sendRemoveFailureMessage(player, manuSchem);
		return false;
	}

	if (!datapad->transferObject(schematic, -1, false)) {
		trx.abort() << "Failed to transfer schematic out of factory.";

		sendRemoveFailureMessage(player, manuSchem);
		return false;
	}

	datapad->broadcastObject(schematic, true);

	StringIdChatParameter message("manf_station", "schematic_removed");

	if (schematic->getCustomObjectName().isEmpty())
		message.setTT(schematic->getObjectNameStringIdFile(), schematic->getObjectNameStringIdName());
	else
		message.setTT(schematic->getCustomObjectName().toString());

	player->sendSystemMessage(message);

	removeMetadataAt(queueIndex);

	info() << "Factory queue entry removed. FactoryID: " << getObjectID()
		<< " SchematicID: " << manuSchem->getObjectID()
		<< " Position: " << queueIndex + 1;

	restoreQueueMetadata();
	evaluateManufacturingQueue();

	return true;
}


bool FactoryObjectImplementation::moveQueuedSchematic(CreatureObject* player, int queueIndex, int direction) {
	if (player == nullptr || !isOnAdminList(player))
		return false;

	restoreQueueMetadata();

	int other = queueIndex + direction;

	if (queueIndex < 0 || queueIndex >= queueSchematicIDs.size() || other < 0 || other >= queueSchematicIDs.size())
		return false;

	if (isActive() && (queueStatuses.get(queueIndex) == QUEUE_ACTIVE || queueStatuses.get(other) == QUEUE_ACTIVE)) {
		player->sendSystemMessage("The running schematic cannot be reordered while the factory is operating.");
		return false;
	}

	unsigned long long schematicID = queueSchematicIDs.get(queueIndex);
	queueSchematicIDs.set(queueIndex, queueSchematicIDs.get(other));
	queueSchematicIDs.set(other, schematicID);

	unsigned long long sequence = queueSequence.get(queueIndex);
	queueSequence.set(queueIndex, queueSequence.get(other));
	queueSequence.set(other, sequence);

	int requested = queueRequestedLimits.get(queueIndex);
	queueRequestedLimits.set(queueIndex, queueRequestedLimits.get(other));
	queueRequestedLimits.set(other, requested);

	int remaining = queueRemainingLimits.get(queueIndex);
	queueRemainingLimits.set(queueIndex, queueRemainingLimits.get(other));
	queueRemainingLimits.set(other, remaining);

	int status = queueStatuses.get(queueIndex);
	queueStatuses.set(queueIndex, queueStatuses.get(other));
	queueStatuses.set(other, status);

	String reason = queueBlockedReasons.get(queueIndex);
	queueBlockedReasons.set(queueIndex, queueBlockedReasons.get(other));
	queueBlockedReasons.set(other, reason);

	unsigned long long evaluated = queueEvaluationTimes.get(queueIndex);
	queueEvaluationTimes.set(queueIndex, queueEvaluationTimes.get(other));
	queueEvaluationTimes.set(other, evaluated);

	for (int i = 0; i < queueSequence.size(); ++i)
		queueSequence.set(i, i + 1);

	info() << "Factory queue reordered. FactoryID: " << getObjectID() << " FromPosition: " << queueIndex + 1 << " ToPosition: " << other + 1;

	if (queueEnabled && !isActive())
		evaluateManufacturingQueue();

	return true;
}


void FactoryObjectImplementation::retryQueuedSchematic(int queueIndex) {
	restoreQueueMetadata();

	if (queueIndex < 0 || queueIndex >= queueStatuses.size())
		return;

	if (queueStatuses.get(queueIndex) == QUEUE_COMPLETED)
		return;

	// The active running job is validated at every production tick. Do not
	// mutate its ACTIVE state from a management SUI action.
	if (isActive() && queueStatuses.get(queueIndex) == QUEUE_ACTIVE)
		return;

	refreshQueuedSchematicReadiness(queueIndex);

	if (queueEnabled && !isActive())
		evaluateManufacturingQueue();
}



void FactoryObjectImplementation::retryAllQueuedSchematics() {
	restoreQueueMetadata();
	for (int i = 0; i < queueStatuses.size(); ++i)
		if (queueStatuses.get(i) != QUEUE_COMPLETED && queueStatuses.get(i) != QUEUE_ACTIVE) {
			queueStatuses.set(i, QUEUE_WAITING);
			queueBlockedReasons.set(i, "");
		}
	evaluateManufacturingQueue();
}

void FactoryObjectImplementation::clearManufacturingQueue(CreatureObject* player) {
	if (player == nullptr || !isOnAdminList(player)) return;
	queueEnabled = false;
	if (isActive()) stopFactory("manf_done", getDisplayedName(), "", currentRunCount);
	Reference<Task*> retryTask = getPendingTask("factoryQueueRetry");
	removePendingTask("factoryQueueRetry");
	if (retryTask != nullptr && retryTask->isScheduled()) retryTask->cancel();
	while (queueSchematicIDs.size() > 0) {
		if (!removeQueuedSchematic(player, queueSchematicIDs.size() - 1)) break;
	}
}

void FactoryObjectImplementation::handleOperateToggle(CreatureObject* player) {
	if (player == nullptr)
		return;

	restoreQueueMetadata();

	if (queueSchematicIDs.size() == 0) {
		player->sendSystemMessage("No manufacturing schematics are queued, so the factory cannot start.");
		return;
	}

	if (!queueEnabled) {
		queueEnabled = true;
		currentUserName = player->getFirstName();
		currentRunCount = 0;

		int activeIndex = -1;
		unsigned long long activeSchematicID = 0;

		for (int i = 0; i < queueStatuses.size(); ++i) {
			if (queueStatuses.get(i) == QUEUE_ACTIVE) {
				activeIndex = i;
				activeSchematicID = queueSchematicIDs.get(i);
				break;
			}
		}

		ManagedReference<SceneObject*> legacyContainerSchematic = getContainerObjectsSize() > 0 ? getContainerObject(0) : nullptr;

		info() << "Factory start requested. FactoryID: " << getObjectID()
			<< " QueueSize: " << queueSchematicIDs.size()
			<< " ActiveQueueIndex: " << activeIndex
			<< " ActiveSchematicID: " << activeSchematicID
			<< " ResolvedActive: " << (getActiveQueuedSchematic() != nullptr ? "true" : "false")
			<< " LegacyContainerSchematicID: " << (legacyContainerSchematic != nullptr ? legacyContainerSchematic->getObjectID() : 0)
			<< " Operating: " << (isActive() ? "true" : "false");

		evaluateManufacturingQueue();

		if (!queueEnabled && !isActive()) {
			bool hasUnfinishedBatch = false;

			for (int i = 0; i < queueStatuses.size() && i < queueRemainingLimits.size(); ++i) {
				if (queueStatuses.get(i) != QUEUE_COMPLETED && queueRemainingLimits.get(i) > 0) {
					hasUnfinishedBatch = true;
					break;
				}
			}

			if (!hasUnfinishedBatch) {
				player->sendSystemMessage("All queued manufacturing batches are complete. Update a completed batch, remove a completed schematic, or add another batch.");
				return;
			}

			String reason = "";

			if (getMaintenanceRate() != 0 && getSurplusMaintenance() <= 0)
				reason = "Factory maintenance is insufficient.";
			else if (getBasePowerRate() != 0 && getSurplusPower() <= 0)
				reason = "Factory power is insufficient.";
			else {
				for (int i = 0; i < queueBlockedReasons.size(); ++i) {
					if (i < queueStatuses.size() &&
							queueStatuses.get(i) != QUEUE_COMPLETED &&
							!queueBlockedReasons.get(i).isEmpty()) {
						reason = queueBlockedReasons.get(i);
						break;
					}
				}
			}

			if (reason.isEmpty())
				reason = "No queued schematic is currently ready to manufacture.";

			player->sendSystemMessage(
				"The manufacturing queue could not start and has stopped: " +
				reason +
				" Correct the issue, then activate the factory again.");

			return;
		}

		if (isActive()) {
			ManagedReference<ManufactureSchematic*> schematic = syncActiveQueueEntryToFactory();
			player->sendSystemMessage("@manf_station:activated");

			if (schematic != nullptr) {
				int queueIndex = findQueueEntry(schematic->getObjectID());
				int remaining = schematic->getManufactureLimit();

				if (queueIndex >= 0 && queueIndex < queueRemainingLimits.size())
					remaining = queueRemainingLimits.get(queueIndex);

				player->sendSystemMessage("Manufacturing queue started. Current schematic has " + String::valueOf(remaining) + " items remaining.");
			}
		} else {
			String reason = "";

			if (getMaintenanceRate() != 0 && getSurplusMaintenance() <= 0)
				reason = "Factory maintenance is insufficient.";
			else if (getBasePowerRate() != 0 && getSurplusPower() <= 0)
				reason = "Factory power is insufficient.";
			else {
				for (int i = 0; i < queueBlockedReasons.size(); ++i) {
					if (!queueBlockedReasons.get(i).isEmpty()) {
						reason = queueBlockedReasons.get(i);
						break;
					}
				}
			}

			if (reason.isEmpty())
				reason = "No queued schematic is currently ready to manufacture.";

			player->sendSystemMessage(
				"The manufacturing queue is not currently running: " +
				reason +
				" Correct the issue, then activate the factory again.");
		}
	} else {
		queueEnabled = false;
		stopFactory("manf_done", getDisplayedName(), "", currentRunCount);

		Reference<Task*> retryTask = getPendingTask("factoryQueueRetry");
		removePendingTask("factoryQueueRetry");

		if (retryTask != nullptr && retryTask->isScheduled())
			retryTask->cancel();

		player->sendSystemMessage("@manf_station:deactivated");
		currentUserName = "";
	}
}


bool FactoryObjectImplementation::startFactory() {
	restoreQueueMetadata();
	if (queueSchematicIDs.size() == 0) {
		info() << "Factory start rejected. FactoryID: " << getObjectID() << " Reason: QUEUE_EMPTY";
		return false;
	}

#ifdef DEBUG_FACTORIES
	info(true) << "startFactory - called";
#endif

	ManagedReference<ManufactureSchematic*> schematic = syncActiveQueueEntryToFactory();

	if (schematic == nullptr) {
		info() << "Factory start rejected. FactoryID: " << getObjectID() << " Reason: ACTIVE_SCHEMATIC_UNRESOLVED";
		return false;
	}

	int queueIndex = findQueueEntry(schematic->getObjectID());
	info() << "Factory active schematic synchronized. FactoryID: " << getObjectID() << " ActiveQueueIndex: " << queueIndex << " ActiveSchematicID: " << schematic->getObjectID() << " ProductionLimit: " << schematic->getManufactureLimit() << " RemainingProduction: " << (queueIndex >= 0 ? queueRemainingLimits.get(queueIndex) : -1) << " OperatingBeforeStart: " << (isActive() ? "true" : "false");

	ManagedReference<TangibleObject*> prototype = schematic->getPrototype();

	if (prototype == nullptr) {
		info() << "Factory start rejected. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Reason: PROTOTYPE_MISSING";
		return false;
	}

	if (prototype->isSliced() || prototype->hasAntiDecayKit()) {
		info() << "Factory start rejected. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Reason: INVALID_PROTOTYPE_MODIFICATION";
		return false;
	}

	if (prototype->isWeaponObject()) {
		WeaponObject* weapon = prototype.castTo<WeaponObject*>();

		if (weapon->hasPowerup()) {
			info() << "Factory start rejected. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Reason: WEAPON_POWERUP_INSTALLED";
			return false;
		}
	}

#ifdef DEBUG_FACTORIES
	timer = 30;
	info(true) << "Factory Testing Timer Set To: " << timer;
#else
	timer = 1; //1 second per item
#endif

	if (!populateSchematicBlueprint(schematic)) {
		info() << "Factory start rejected. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Reason: BLUEPRINT_POPULATION_FAILED";
		return false;
	}

	// Add sampletask
	Reference<CreateFactoryObjectTask*> createFactoryObjectTask = new CreateFactoryObjectTask(_this.getReferenceUnsafeStaticCast());
	addPendingTask("createFactoryObject", createFactoryObjectTask, timer * 1000);

	setActive(true, true);
	info() << "Factory production task scheduled. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Task: createFactoryObject DelayMS: " << timer * 1000 << " Scheduled: " << (getPendingTask("createFactoryObject") != nullptr ? "true" : "false") << " Operating: " << (isActive() ? "true" : "false");

	return true;
}

bool FactoryObjectImplementation::populateSchematicBlueprint(ManufactureSchematic* schematic) {
	ManagedReference<SceneObject*> inputHopper = getSlottedObject("ingredient_hopper");

	if (inputHopper == nullptr) {
		error("Factory Ingredient Hopper missing.  WTF");
		return false;
	}

	for (int i = 0; i < schematic->getBlueprintSize(); ++i) {
		BlueprintEntry* entry = schematic->getBlueprintEntry(i);
		entry->setHopper(inputHopper);
		collectMatchesInInputHopper(entry, inputHopper);
	}
	return true;
}

void FactoryObjectImplementation::logIngredientValidationFailure(ManufactureSchematic* schematic, int queueIndex, const String& phase) {
	if (schematic == nullptr)
		return;

	unsigned long long activeSchematicID = 0;
	for (int i = 0; i < queueStatuses.size() && i < queueSchematicIDs.size(); ++i) {
		if (queueStatuses.get(i) == QUEUE_ACTIVE) {
			activeSchematicID = queueSchematicIDs.get(i);
			break;
		}
	}

	info() << "[FactoryQueue] START FAILURE Factory: " << getObjectID()
		<< " QueueSize: " << queueSchematicIDs.size()
		<< " QueueIndex: " << queueIndex
		<< " QueuedSchematic: " << schematic->getObjectID()
		<< " ActiveSchematic: " << activeSchematicID
		<< " Schematic: " << schematic->getDisplayedName()
		<< " QueueEnabled: " << (queueEnabled ? "true" : "false")
		<< " Operating: " << (isActive() ? "true" : "false")
		<< " Phase: " << phase;

	for (int i = 0; i < schematic->getBlueprintSize(); ++i) {
		BlueprintEntry* entry = schematic->getBlueprintEntry(i);

		if (entry == nullptr) {
			warning() << "[FactoryQueue] Ingredient Factory: " << getObjectID() << " Schematic: " << schematic->getObjectID() << " Slot: " << i << " Result: INVALID_ENTRY";
			continue;
		}

		int available = entry->getAvailableQuantity();
		info() << "[FactoryQueue] Ingredient Factory: " << getObjectID()
			<< " Schematic: " << schematic->getObjectID()
			<< " Slot: " << i
			<< " Type: " << entry->getType()
			<< " Key: " << entry->getKey()
			<< " Serial: " << entry->getSerial()
			<< " Required: " << entry->getQuantity()
			<< " Available: " << available
			<< " Matches: " << entry->getMatchingHopperItemsSummary()
			<< " Result: " << (available >= entry->getQuantity() ? "PASS" : "FAIL");
	}
}

void FactoryObjectImplementation::stopFactory(const String& message, const String& tt, const String& to, const int di) {
	Locker _locker(_this.getReferenceUnsafeStaticCast());

#ifdef DEBUG_FACTORIES
	info(true) << "stopFactory - called";
#endif

	setActive(false, true);

	Reference<Task*> pending = getPendingTask("createFactoryObject");
	removePendingTask("createFactoryObject");

	if (pending != nullptr && pending->isScheduled())
		pending->cancel();

	// Send out email informing them why their factory stopped
	ManagedReference<ChatManager*> chatManager = server->getChatManager();

	if (chatManager != nullptr && currentUserName != "") {
		StringIdChatParameter emailBody;
		emailBody.setStringId("@system_msg:" + message);
		if (tt != "")
			emailBody.setTT(tt);
		if (to != "")
			emailBody.setTO(to);
		if (di != -1)
			emailBody.setDI(di);
		UnicodeString subject = "@system_msg:manf_done_sub";

		/*WaypointObject* newwaypoint = cast<WaypointObject*>( server->getZoneServer()->createObject(0xc456e788, 1));

		newwaypoint->setCustomName(UnicodeString(this->getDisplayedName()));
		newwaypoint->setPlanetCRC(Planet::getPlanetCRC(getZone()->getPlanetName()));
		newwaypoint->setPosition(this->getPositionX(), this->getPositionZ(), this->getPositionY());
		newwaypoint->setColor(WaypointObject::COLOR_BLUE);
		newwaypoint->setActive(false);

		chatManager->sendMail(getDisplayedName(), subject, emailBody, currentUserName, newwaypoint);*/

		chatManager->sendMail(getDisplayedName(), subject, emailBody, currentUserName);
	}
}

void FactoryObjectImplementation::stopFactory(String& type, String& displayedName) {
	if (type == "resource") {
		if (displayedName == "")
			stopFactory("manf_no_unknown_resource", getDisplayedName(), "", -1);
		else
			stopFactory("manf_no_named_resource", getDisplayedName(), displayedName, -1);

	} else {
		stopFactory("manf_no_component", getDisplayedName(), displayedName, -1);
	}
}

void FactoryObjectImplementation::createNewObject() {
	/// Pre: _this.getReferenceUnsafeStaticCast() locked

#ifdef DEBUG_FACTORIES
	info(true) << "createNewObject - called";
#endif

	if (getContainerObjectsSize() == 0) {
		stopFactory("manf_error", "", "", -1);
		queueEnabled = false;
		currentUserName = "";
		queueIdleNoticeLogged = false;
		return;
	}

	ManagedReference<ManufactureSchematic*> schematic = getActiveQueuedSchematic();

	if (schematic == nullptr || !schematic->isManufactureSchematic()) {
		stopFactory("manf_error_4", "", "", -1);
		evaluateManufacturingQueue();
		return;
	}

	ManagedReference<TangibleObject*> prototype = cast<TangibleObject*>(schematic->getPrototype());

	if (prototype == nullptr) {
		int queueIndex = findQueueEntry(schematic->getObjectID());
		markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_INVALID, "Manufacturing schematic has no prototype.");
		stopFactory("manf_error_2", "", "", -1);
		evaluateManufacturingQueue();
		return;
	}

	/// Shutdown when out of power or maint
	Time timeToWorkTill;
	bool shutdownAfterWork = updateMaintenance(timeToWorkTill);

	if (shutdownAfterWork) {
		Time currentTime;

		float elapsedTime = (currentTime.getTime() - lastMaintenanceTime.getTime());

		float energyAmount = (elapsedTime / 3600.0) * getBasePowerRate();
		if (energyAmount > surplusPower) {
			markQueueEntryBlocked(findQueueEntry(schematic->getObjectID()), QUEUE_BLOCKED_POWER, "Factory power is insufficient.");
			stopFactory("manf_no_power", getDisplayedName(), "", -1);
			evaluateManufacturingQueue();
			return;
		}

		markQueueEntryBlocked(findQueueEntry(schematic->getObjectID()), QUEUE_BLOCKED_MAINTENANCE, "Factory maintenance is insufficient.");
		stopFactory("manf_done_sub", "", "", -1);
		evaluateManufacturingQueue();
		return;
	}

	verifyOperators();

	// Blueprint hopper pointers and match vectors are transient caches. Hopper
	// changes while the factory is active intentionally do not restart queue
	// evaluation, so rebuild the active schematic's matches at the transaction
	// boundary before validating and consuming this item.
	if (!populateSchematicBlueprint(schematic)) {
		markQueueEntryBlocked(findQueueEntry(schematic->getObjectID()), QUEUE_BLOCKED_INVALID, "Factory ingredient hopper is unavailable.");
		stopFactory("manf_error_5", "", "", -1);
		evaluateManufacturingQueue();
		return;
	}

	String type = "";
	String displayedName = "";

	schematic->canManufactureItem(type, displayedName);

	if (displayedName != "") {
		int queueIndex = findQueueEntry(schematic->getObjectID());
		logIngredientValidationFailure(schematic, queueIndex, "PRODUCTION_TICK");
		markQueueEntryBlocked(queueIndex, type == "resource" ? QUEUE_BLOCKED_RESOURCES : QUEUE_BLOCKED_COMPONENTS, displayedName);
		stopFactory(type, displayedName);
		evaluateManufacturingQueue();
		return;
	}

	int crateSize = schematic->getFactoryCrateSize();

	if (crateSize <= 0) {
		int queueIndex = findQueueEntry(schematic->getObjectID());
		markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_INVALID, "Manufacturing schematic has an invalid factory crate size.");
		stopFactory("manf_error", "", "", -1);
		evaluateManufacturingQueue();
		return;
	}

	if (crateSize > 1) {
		String crateType = schematic->getFactoryCrateType();

		ManagedReference<FactoryCrate*> crate = locateCrateInOutputHopper(prototype);

		if (crate == nullptr)
			crate = createNewFactoryCrate(prototype, crateSize, crateType);
		else {
			Locker clocker(crate, _this.getReferenceUnsafeStaticCast());
			crate->setUseCount(crate->getUseCount() + 1, true);
		}

		if (crate == nullptr) {
			int queueIndex = findQueueEntry(schematic->getObjectID());
			markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_OUTPUT_FULL, "Output hopper is full.");
			evaluateManufacturingQueue();
			return;
		}

		FactoryCrateObjectDeltaMessage3* dfcty3 = new FactoryCrateObjectDeltaMessage3(crate);
		dfcty3->setQuantity(crate->getUseCount());
		dfcty3->close();

		broadcastToOperators(dfcty3);
	} else {
		ManagedReference<TangibleObject*> newItem = createNewUncratedItem(prototype);

		if (newItem == nullptr)
		{
			int queueIndex = findQueueEntry(schematic->getObjectID());
			markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_OUTPUT_FULL, "Output hopper is full.");
			evaluateManufacturingQueue();
			return;
		}
	}

	Locker clocker(schematic, _this.getReferenceUnsafeStaticCast());

	schematic->manufactureItem(_this.getReferenceUnsafeStaticCast());
	currentRunCount++;

	int queueIndex = findQueueEntry(schematic->getObjectID());
	int batchRemaining = -1;

	if (queueIndex >= 0) {
		batchRemaining = queueRemainingLimits.get(queueIndex) - 1;

		if (batchRemaining < 0)
			batchRemaining = 0;

		queueRemainingLimits.set(queueIndex, batchRemaining);
	}

	int schematicUsesRemaining = schematic->getManufactureLimit();

	info() << "Factory production item completed. FactoryID: " << getObjectID()
		<< " SchematicID: " << schematic->getObjectID()
		<< " QueuePosition: " << queueIndex + 1
		<< " BatchProduced: " << currentRunCount
		<< " BatchRemaining: " << batchRemaining
		<< " SchematicUsesRemaining: " << schematicUsesRemaining;

	if (queueIndex >= 0 && batchRemaining <= 0) {
		unsigned long long completedSchematicID = schematic->getObjectID();

		queueStatuses.set(queueIndex, QUEUE_COMPLETED);
		queueBlockedReasons.set(queueIndex, "");
		queueEvaluationTimes.set(queueIndex, (unsigned long long)Time().getTime());

		info() << "Factory manufacturing batch completed. FactoryID: " << getObjectID()
			<< " SchematicID: " << completedSchematicID
			<< " Position: " << queueIndex + 1
			<< " BatchSize: " << queueRequestedLimits.get(queueIndex)
			<< " SchematicUsesRemaining: " << schematicUsesRemaining;

		if (schematicUsesRemaining <= 0) {
			queueSchematicIDs.remove(queueIndex);
			queueSequence.remove(queueIndex);
			queueRequestedLimits.remove(queueIndex);
			queueRemainingLimits.remove(queueIndex);
			queueStatuses.remove(queueIndex);
			queueBlockedReasons.remove(queueIndex);
			queueEvaluationTimes.remove(queueIndex);

			for (int i = 0; i < queueSequence.size(); ++i)
				queueSequence.set(i, i + 1);

			schematic->destroyObjectFromWorld(true);
			schematic->destroyObjectFromDatabase(true);
		}

		stopFactory("manf_done", getDisplayedName(), "", currentRunCount);

		bool hasPendingBatch = false;

		for (int i = 0; i < queueSchematicIDs.size(); ++i) {
			if (queueStatuses.get(i) != QUEUE_COMPLETED && queueRemainingLimits.get(i) > 0) {
				hasPendingBatch = true;
				break;
			}
		}

		if (!hasPendingBatch) {
			queueEnabled = false;
			currentUserName = "";
			queueIdleNoticeLogged = false;

			Reference<Task*> retryTask = getPendingTask("factoryQueueRetry");
			removePendingTask("factoryQueueRetry");

			if (retryTask != nullptr && retryTask->isScheduled())
				retryTask->cancel();

			info() << "Factory queue finished all requested batches. FactoryID: " << getObjectID();
		} else {
			evaluateManufacturingQueue();
		}

		return;
	}

	if (schematicUsesRemaining <= 0) {
		if (queueIndex >= 0)
			markQueueEntryBlocked(queueIndex, QUEUE_BLOCKED_INVALID, "Manufacturing schematic was exhausted before the requested batch completed.");

		stopFactory("manf_done", getDisplayedName(), "", currentRunCount);
		evaluateManufacturingQueue();
		return;
	}

	Reference<Task*> pending = getPendingTask("createFactoryObject");

	if (pending != nullptr) {
		pending->reschedule(timer * 1000);
	} else {
		warning() << "Factory production task unexpectedly missing. FactoryID: " << getObjectID()
			<< " SchematicID: " << schematic->getObjectID()
			<< " QueuePosition: " << queueIndex + 1
			<< ". Stopping the queue session to avoid an automatic restart loop.";

		stopFactory("manf_error", "", "", -1);
		queueEnabled = false;
		currentUserName = "";
		queueIdleNoticeLogged = false;
	}
}

FactoryCrate* FactoryObjectImplementation::locateCrateInOutputHopper(TangibleObject* prototype) {
	ManagedReference<SceneObject*> outputHopper = getSlottedObject("output_hopper");

	if (outputHopper == nullptr || prototype == nullptr) {
		stopFactory("manf_error_6", "", "", -1);
		return nullptr;
	}

	for (int i = 0; i < outputHopper->getContainerObjectsSize(); ++i) {
		ManagedReference<SceneObject*> object = outputHopper->getContainerObject(i);

		if (object == nullptr || !object->isFactoryCrate())
			continue;

		FactoryCrate* crate = cast<FactoryCrate*>(object.get());

		if (crate->getPrototype() != nullptr && crate->getPrototype()->getSerialNumber() == prototype->getSerialNumber() && crate->getUseCount() < crate->getMaxCapacity()) {
			return crate;
		}
	}

	return nullptr;
}

FactoryCrate* FactoryObjectImplementation::createNewFactoryCrate(TangibleObject* prototype, int maxSize, String& type) {
	ManagedReference<SceneObject*> outputHopper = getSlottedObject("output_hopper");

	if (outputHopper == nullptr) {
		stopFactory("manf_error_6", "", "", -1);
		return nullptr;
	}

	if (outputHopper->isContainerFull()) {
		stopFactory("manf_output_hopper_full", getDisplayedName(), "", -1);
		return nullptr;
	}

	ManagedReference<FactoryCrate*> crate = prototype->createFactoryCrate(maxSize, type, false);

	if (crate == nullptr) {
		stopFactory("manf_error_7", "", "", -1);
		return nullptr;
	}

	outputHopper->transferObject(crate, -1, true);

	return crate;
}

TangibleObject* FactoryObjectImplementation::createNewUncratedItem(TangibleObject* prototype) {
	ManagedReference<SceneObject*> outputHopper = getSlottedObject("output_hopper");

	if (outputHopper == nullptr) {
		stopFactory("manf_error_6", "", "", -1);
		return nullptr;
	}

	if (outputHopper->isContainerFull()) {
		stopFactory("manf_output_hopper_full", getDisplayedName(), "", -1);
		return nullptr;
	}

	ObjectManager* objectManager = ObjectManager::instance();
	ManagedReference<TangibleObject*> protoclone = cast<TangibleObject*>(objectManager->cloneObject(prototype->asTangibleObject()));

	if (protoclone == nullptr) {
		stopFactory("manf_error_8", "", "", -1);
		return nullptr;
	}

	protoclone->setParent(nullptr);
	outputHopper->transferObject(protoclone, -1, true);

	return protoclone;
}

void FactoryObjectImplementation::collectMatchesInInputHopper(BlueprintEntry* entry, SceneObject* inputHopper) {
	entry->clearMatches();
	for (int i = 0; i < inputHopper->getContainerObjectsSize(); ++i) {
		ManagedReference<TangibleObject*> object = inputHopper->getContainerObject(i).castTo<TangibleObject*>();

		if (object == nullptr) {
			error("nullptr hopper object in FactoryObjectImplementation::countItemInInputHopper");
			continue;
		}

		String key = "";
		String serial = "";

		if (object->isResourceContainer()) {
			ResourceContainer* rcnoObject = cast<ResourceContainer*>(object.get());

			key = rcnoObject->getSpawnName();

			if (entry->getKey() == key) {
				entry->addMatch(object);
				continue;
			}

		} else {
			TangibleObject* prototype = nullptr;

			if (object->isFactoryCrate()) {
				FactoryCrate* crate = cast<FactoryCrate*>(object.get());
				prototype = crate->getPrototype();
			} else {
				prototype = object;
			}

			key = String::valueOf(prototype->getServerObjectCRC());
			serial = prototype->getSerialNumber();

			if (entry->getKey() == key) {
				if (entry->needsIdentical()) {
					if (entry->getSerial() != serial)
						continue;
				}

				entry->addMatch(object);
			}
		}
	}
}

bool FactoryObjectImplementation::factoryQueueInventoryObjectMatches(BlueprintEntry* entry, TangibleObject* object) {
	if (entry == nullptr || object == nullptr)
		return false;

	if (entry->getType() == "resource") {
		if (!object->isResourceContainer())
			return false;

		ResourceContainer* resource = cast<ResourceContainer*>(object);

		return resource != nullptr && resource->getSpawnName() == entry->getKey();
	}

	TangibleObject* prototype = object;

	if (object->isFactoryCrate()) {
		FactoryCrate* crate = cast<FactoryCrate*>(object);

		if (crate == nullptr)
			return false;

		prototype = crate->getPrototype();
	}

	if (prototype == nullptr)
		return false;

	if (String::valueOf(prototype->getServerObjectCRC()) != entry->getKey())
		return false;

	if (entry->needsIdentical() && prototype->getSerialNumber() != entry->getSerial())
		return false;

	return true;
}

int FactoryObjectImplementation::getFactoryQueueInventoryObjectQuantity(TangibleObject* object) {
	if (object == nullptr)
		return 0;

	if (object->isResourceContainer()) {
		ResourceContainer* resource = cast<ResourceContainer*>(object);

		return resource == nullptr ? 0 : resource->getQuantity();
	}

	int useCount = object->getUseCount();

	return useCount <= 0 ? 1 : useCount;
}

int FactoryObjectImplementation::getFactoryQueueInventoryMatchQuantity(CreatureObject* player, BlueprintEntry* entry) {
	if (player == nullptr || entry == nullptr)
		return 0;

	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");

	if (inventory == nullptr)
		return 0;

	int available = 0;

	for (int i = 0; i < inventory->getContainerObjectsSize(); ++i) {
		ManagedReference<TangibleObject*> object =
			inventory->getContainerObject(i).castTo<TangibleObject*>();

		if (!factoryQueueInventoryObjectMatches(entry, object))
			continue;

		available += getFactoryQueueInventoryObjectQuantity(object);
	}

	return available;
}

int FactoryObjectImplementation::getFactoryQueueInventoryLoadableQuantity(
		CreatureObject* player,
		BlueprintEntry* entry,
		int amountNeeded) {

	if (player == nullptr || entry == nullptr || amountNeeded <= 0)
		return 0;

	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");
	ManagedReference<SceneObject*> inputHopper = getSlottedObject("ingredient_hopper");

	if (inventory == nullptr || inputHopper == nullptr)
		return 0;

	int capacityRemaining =
		inputHopper->getContainerVolumeLimit() - inputHopper->getCountableObjectsRecursive();

	if (capacityRemaining <= 0)
		return 0;

	Vector<ManagedReference<TangibleObject*> > candidates;

	for (int i = 0; i < inventory->getContainerObjectsSize(); ++i) {
		ManagedReference<TangibleObject*> object =
			inventory->getContainerObject(i).castTo<TangibleObject*>();

		if (factoryQueueInventoryObjectMatches(entry, object))
			candidates.add(object);
	}

	int remaining = amountNeeded;
	int loadable = 0;

	while (candidates.size() > 0 && remaining > 0 && capacityRemaining > 0) {
		int exactIndex = -1;
		int underIndex = -1;
		int underQuantity = 0;
		int overIndex = -1;
		int overQuantity = 0;

		for (int i = 0; i < candidates.size(); ++i) {
			TangibleObject* object = candidates.get(i);

			if (object == nullptr)
				continue;

			int quantity = getFactoryQueueInventoryObjectQuantity(object);

			if (quantity <= 0)
				continue;

			if (quantity == remaining) {
				exactIndex = i;
				break;
			}

			if (quantity < remaining) {
				if (underIndex < 0 || quantity > underQuantity) {
					underIndex = i;
					underQuantity = quantity;
				}
			} else if ((object->isResourceContainer() || object->isFactoryCrate()) &&
					(overIndex < 0 || quantity < overQuantity)) {
				overIndex = i;
				overQuantity = quantity;
			}
		}

		int selectedIndex = exactIndex >= 0 ? exactIndex : (underIndex >= 0 ? underIndex : overIndex);

		if (selectedIndex < 0)
			break;

		ManagedReference<TangibleObject*> object = candidates.get(selectedIndex);
		candidates.remove(selectedIndex);

		if (object == nullptr)
			continue;

		int objectSize =
			object->isContainerObject() ? object->getContainerObjectsSize() + 1 : 1;

		if (objectSize > capacityRemaining)
			continue;

		String transferError;

		if (inputHopper->canAddObject(object, -1, transferError) != 0)
			continue;

		int quantity = getFactoryQueueInventoryObjectQuantity(object);

		if (quantity <= 0)
			continue;

		int amount = quantity < remaining ? quantity : remaining;

		if (!(object->isResourceContainer() || object->isFactoryCrate()) && quantity > remaining)
			continue;

		loadable += amount;
		remaining -= amount;
		capacityRemaining -= objectSize;
	}

	return loadable;
}


int FactoryObjectImplementation::loadFactoryQueueIngredientFromInventory(
		CreatureObject* player,
		BlueprintEntry* entry,
		int amountNeeded,
		unsigned long long schematicID,
		int queueIndex) {

	if (player == nullptr || entry == nullptr || amountNeeded <= 0)
		return 0;

	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");
	ManagedReference<SceneObject*> inputHopper = getSlottedObject("ingredient_hopper");

	if (inventory == nullptr || inputHopper == nullptr)
		return 0;

	Vector<ManagedReference<TangibleObject*> > candidates;

	for (int i = 0; i < inventory->getContainerObjectsSize(); ++i) {
		ManagedReference<TangibleObject*> object =
			inventory->getContainerObject(i).castTo<TangibleObject*>();

		if (factoryQueueInventoryObjectMatches(entry, object))
			candidates.add(object);
	}

	int loaded = 0;

	while (candidates.size() > 0 && loaded < amountNeeded) {
		int remaining = amountNeeded - loaded;
		int exactIndex = -1;
		int underIndex = -1;
		int underQuantity = 0;
		int overIndex = -1;
		int overQuantity = 0;

		for (int i = 0; i < candidates.size(); ++i) {
			TangibleObject* object = candidates.get(i);

			if (object == nullptr || object->getParentID() != inventory->getObjectID())
				continue;

			int quantity = getFactoryQueueInventoryObjectQuantity(object);

			if (quantity <= 0)
				continue;

			if (quantity == remaining) {
				exactIndex = i;
				break;
			}

			if (quantity < remaining) {
				if (underIndex < 0 || quantity > underQuantity) {
					underIndex = i;
					underQuantity = quantity;
				}
			} else if ((object->isResourceContainer() || object->isFactoryCrate()) &&
					(overIndex < 0 || quantity < overQuantity)) {
				overIndex = i;
				overQuantity = quantity;
			}
		}

		int selectedIndex = exactIndex >= 0 ? exactIndex : (underIndex >= 0 ? underIndex : overIndex);

		if (selectedIndex < 0)
			break;

		ManagedReference<TangibleObject*> source = candidates.get(selectedIndex);
		candidates.remove(selectedIndex);

		if (source == nullptr || source->getParentID() != inventory->getObjectID())
			continue;

		int sourceQuantity = getFactoryQueueInventoryObjectQuantity(source);

		if (sourceQuantity <= 0)
			continue;

		int amountToMove = sourceQuantity < remaining ? sourceQuantity : remaining;

		String transferError;

		// Preflight the real hopper container before mutating/splitting a source
		// stack. This prevents the common "split succeeded but hopper was full"
		// fragmentation case.
		if (inputHopper->canAddObject(source, -1, transferError) != 0) {
			info() << "Factory queue ingredient load preflight rejected. FactoryID: " << getObjectID()
				<< " PlayerID: " << player->getObjectID()
				<< " SchematicID: " << schematicID
				<< " QueuePosition: " << queueIndex + 1
				<< " SourceOID: " << source->getObjectID()
				<< " Reason: " << transferError;
			continue;
		}

		if (amountToMove >= sourceQuantity) {
			Locker sourceLocker(source, player);

			TransactionLog trx(inventory.get(), inputHopper.get(), source.get(), TrxCode::FACTORYOPERATION);
			trx.setType("factory_queue_auto_load");
			trx.addRelatedObject(asSceneObject());
			trx.addState("factoryId", (uint64)getObjectID());
			trx.addState("playerId", (uint64)player->getObjectID());
			trx.addState("schematicId", (uint64)schematicID);
			trx.addState("queuePosition", queueIndex + 1);
			trx.addState("ingredientType", entry->getType());
			trx.addState("ingredientKey", entry->getKey());
			trx.addState("ingredientSerial", entry->getSerial());
			trx.addState("sourceObjectId", (uint64)source->getObjectID());
			trx.addState("quantity", sourceQuantity);
			trx.addState("splitTransfer", false);

			if (inputHopper->transferObject(source, -1, true)) {
				inputHopper->broadcastObject(source, true);
				loaded += sourceQuantity;
				trx.commit();

				info() << "Factory queue ingredient loaded. FactoryID: " << getObjectID()
					<< " PlayerID: " << player->getObjectID()
					<< " SchematicID: " << schematicID
					<< " QueuePosition: " << queueIndex + 1
					<< " IngredientType: " << entry->getType()
					<< " IngredientKey: " << entry->getKey()
					<< " ObjectID: " << source->getObjectID()
					<< " Quantity: " << sourceQuantity
					<< " Split: false";
			} else {
				trx.abort() << "Factory queue automatic ingredient transfer failed.";
			}

			continue;
		}

		if (source->isResourceContainer() || source->isFactoryCrate()) {
			Vector<unsigned long long> inventoryIDsBeforeSplit;

			for (int j = 0; j < inventory->getContainerObjectsSize(); ++j) {
				SceneObject* existing = inventory->getContainerObject(j);

				if (existing != nullptr)
					inventoryIDsBeforeSplit.add(existing->getObjectID());
			}

			unsigned long long sourceObjectID = source->getObjectID();
			int sourceQuantityBefore = sourceQuantity;

			if (source->isResourceContainer()) {
				ResourceContainer* resource = cast<ResourceContainer*>(source.get());

				if (resource == nullptr)
					continue;

				Locker resourceLocker(resource, player);
				resource->split(amountToMove);
			} else {
				FactoryCrate* crate = cast<FactoryCrate*>(source.get());

				if (crate == nullptr || !crate->isValidFactoryCrate())
					continue;

				Locker crateLocker(crate, player);
				crate->split(amountToMove);
			}

			ManagedReference<TangibleObject*> splitObject = nullptr;

			for (int j = 0; j < inventory->getContainerObjectsSize(); ++j) {
				ManagedReference<TangibleObject*> candidate =
					inventory->getContainerObject(j).castTo<TangibleObject*>();

				if (candidate == nullptr || candidate->getObjectID() == sourceObjectID)
					continue;

				bool existedBefore = false;

				for (int k = 0; k < inventoryIDsBeforeSplit.size(); ++k) {
					if (inventoryIDsBeforeSplit.get(k) == candidate->getObjectID()) {
						existedBefore = true;
						break;
					}
				}

				if (existedBefore)
					continue;

				if (!factoryQueueInventoryObjectMatches(entry, candidate))
					continue;

				if (getFactoryQueueInventoryObjectQuantity(candidate) != amountToMove)
					continue;

				splitObject = candidate;
				break;
			}

			if (splitObject == nullptr) {
				warning() << "Factory queue split completed but split object could not be identified. FactoryID: "
					<< getObjectID() << " PlayerID: " << player->getObjectID()
					<< " SchematicID: " << schematicID
					<< " SourceOID: " << sourceObjectID
					<< " RequestedSplit: " << amountToMove;
				continue;
			}

			Locker splitLocker(splitObject, player);

			TransactionLog trx(inventory.get(), inputHopper.get(), splitObject.get(), TrxCode::FACTORYOPERATION);
			trx.setType("factory_queue_auto_load");
			trx.addRelatedObject(asSceneObject());
			trx.addRelatedObject(sourceObjectID);
			trx.addState("factoryId", (uint64)getObjectID());
			trx.addState("playerId", (uint64)player->getObjectID());
			trx.addState("schematicId", (uint64)schematicID);
			trx.addState("queuePosition", queueIndex + 1);
			trx.addState("ingredientType", entry->getType());
			trx.addState("ingredientKey", entry->getKey());
			trx.addState("ingredientSerial", entry->getSerial());
			trx.addState("sourceObjectId", (uint64)sourceObjectID);
			trx.addState("sourceQuantityBefore", sourceQuantityBefore);
			trx.addState("splitObjectId", (uint64)splitObject->getObjectID());
			trx.addState("quantity", amountToMove);
			trx.addState("splitTransfer", true);

			if (inputHopper->transferObject(splitObject, -1, true)) {
				inputHopper->broadcastObject(splitObject, true);
				loaded += amountToMove;
				trx.commit();

				info() << "Factory queue ingredient loaded. FactoryID: " << getObjectID()
					<< " PlayerID: " << player->getObjectID()
					<< " SchematicID: " << schematicID
					<< " QueuePosition: " << queueIndex + 1
					<< " IngredientType: " << entry->getType()
					<< " IngredientKey: " << entry->getKey()
					<< " SourceOID: " << sourceObjectID
					<< " ObjectID: " << splitObject->getObjectID()
					<< " Quantity: " << amountToMove
					<< " Split: true";
			} else {
				trx.abort() << "Factory queue automatic split ingredient transfer failed; split remains in inventory.";
			}
		}
	}

	return loaded;
}




String FactoryObjectImplementation::getRedeedMessage() {
	if (isActive())
		return "deactivate_factory_for_delete";

	if (getContainerObjectsSize() > 0)
		return "remove_schematic_for_delete";

	ManagedReference<SceneObject*> inputHopper = getSlottedObject("ingredient_hopper");

	if (inputHopper != nullptr && inputHopper->getContainerObjectsSize() > 0) {
		return "clear_input_hopper_for_delete";
	}

	ManagedReference<SceneObject*> outputHopper = getSlottedObject("output_hopper");

	if (outputHopper != nullptr && outputHopper->getContainerObjectsSize() > 0) {
		return "clear_output_hopper_for_delete";
	}

	return "";
}

void FactoryObjectImplementation::sendRemoveFailureMessage(CreatureObject* player, ManufactureSchematic* schematic) {
	if (player == nullptr || schematic == nullptr)
		return;

	StringIdChatParameter message("manf_station", "schematic_not_removed"); // Schematic %TT was not removed from the station and been placed in your datapad. Have a nice day!

	if (schematic->getCustomObjectName().isEmpty()) {
		message.setTT(schematic->getObjectNameStringIdFile(), schematic->getObjectNameStringIdName());
	} else {
		message.setTT(schematic->getCustomObjectName().toString());
	}

	player->sendSystemMessage(message);
}
