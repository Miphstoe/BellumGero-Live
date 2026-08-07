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

#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
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
}

void FactoryObjectImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* object) {
	InstallationObjectImplementation::fillAttributeList(alm, object);

	// Show maintenance and power to admins
	if (object != nullptr && isOnAdminList(object)) {
		alm->insertAttribute("examine_maintenance_rate", String::valueOf((int)getMaintenanceRate()) + " / hour");
		alm->insertAttribute("examine_maintenance", String::valueOf((int)surplusMaintenance));

		int basePowerRate = getBasePowerRate();
		if (basePowerRate > 0) {
			alm->insertAttribute("examine_power", String::valueOf((int)surplusPower) + " (Rate: " + String::valueOf(basePowerRate) + " / hour)");
		} else {
			alm->insertAttribute("examine_power", String::valueOf((int)surplusPower));
		}
	}

	if (isActive() && object != nullptr && isOnAdminList(object)) {
		if (getContainerObjectsSize() == 0)
			return;

		ManagedReference<ManufactureSchematic*> schematic = getActiveQueuedSchematic();

		if (schematic == nullptr)
			return;

		ManagedReference<TangibleObject*> prototype = dynamic_cast<TangibleObject*>(schematic->getPrototype());

		if (prototype != nullptr) {
			alm->insertAttribute("manufacture_object", prototype->getDisplayedName());
		}

		alm->insertAttribute("manufacture_time", timer);

		ManagedReference<SceneObject*> outputHopper = getSlottedObject("output_hopper");

		if (outputHopper != nullptr) {
			alm->insertAttribute("manf_limit", schematic->getManufactureLimit());
			alm->insertAttribute("manufacture_count", currentRunCount); // Manufactured Items:
		}
	}
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
	int metadataSize = queueSchematicIDs.size();
	if (metadataSize == 0) {
		for (int i = 0; i < getContainerObjectsSize(); ++i) {
			ManagedReference<ManufactureSchematic*> schematic = getContainerObject(i).castTo<ManufactureSchematic*>();
			if (schematic == nullptr)
				continue;
			queueSchematicIDs.add(schematic->getObjectID());
			queueSequence.add(i + 1);
			queueRequestedLimits.add(schematic->getManufactureLimit());
			queueRemainingLimits.add(schematic->getManufactureLimit());
			queueStatuses.add(i == 0 ? QUEUE_ACTIVE : QUEUE_WAITING);
			queueBlockedReasons.add("");
			queueEvaluationTimes.add(0);
		}
		if (queueSchematicIDs.size() > 0)
			info() << "Factory queue restored from legacy contents. FactoryID: " << getObjectID();
	}

	int size = queueSchematicIDs.size();
	if (size > MAX_FACTORY_QUEUE) {
		warning() << "Factory queue invariant repaired. FactoryID: " << getObjectID() << " Entries: " << size;
		while (queueSchematicIDs.size() > MAX_FACTORY_QUEUE) {
			int last = queueSchematicIDs.size() - 1;
			queueSchematicIDs.remove(last);
			if (queueSequence.size() > last) queueSequence.remove(last);
			if (queueRequestedLimits.size() > last) queueRequestedLimits.remove(last);
			if (queueRemainingLimits.size() > last) queueRemainingLimits.remove(last);
			if (queueStatuses.size() > last) queueStatuses.remove(last);
			if (queueBlockedReasons.size() > last) queueBlockedReasons.remove(last);
			if (queueEvaluationTimes.size() > last) queueEvaluationTimes.remove(last);
		}
		size = MAX_FACTORY_QUEUE;
	}
	while (queueSequence.size() < size) queueSequence.add(queueSequence.size() + 1);
	while (queueRequestedLimits.size() < size) queueRequestedLimits.add(0);
	while (queueRemainingLimits.size() < size) queueRemainingLimits.add(queueRequestedLimits.get(queueRemainingLimits.size()));
	while (queueStatuses.size() < size) queueStatuses.add(QUEUE_WAITING);
	while (queueBlockedReasons.size() < size) queueBlockedReasons.add("");
	while (queueEvaluationTimes.size() < size) queueEvaluationTimes.add(0);

	bool activeFound = false;
	for (int i = 0; i < size; ++i) {
		if (queueStatuses.get(i) == QUEUE_ACTIVE) {
			if (activeFound)
				queueStatuses.set(i, QUEUE_WAITING);
			else
				activeFound = true;
		}
	}
	if (!activeFound) {
		for (int i = 0; i < size; ++i) {
			if (queueStatuses.get(i) == QUEUE_WAITING) {
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

		ManagedReference<ManufactureSchematic*> schematic = server->getZoneServer()->getObject(queueSchematicIDs.get(i)).castTo<ManufactureSchematic*>();
		if (schematic == nullptr) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Active manufacturing schematic could not be resolved.");
			return nullptr;
		}

		ManagedReference<SceneObject*> parent = schematic->getParent().get();
		if (parent == nullptr || parent->getObjectID() != getObjectID()) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Active manufacturing schematic is not contained by this factory.");
			return nullptr;
		}

		int remaining = queueRemainingLimits.get(i);
		if (remaining <= 0) {
			queueStatuses.set(i, QUEUE_COMPLETED);
			return nullptr;
		}

		if (schematic->getManufactureLimit() != remaining) {
			Locker schematicLocker(schematic, _this.getReferenceUnsafeStaticCast());
			schematic->setManufactureLimit(remaining);
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

	return syncActiveQueueEntryToFactory() != nullptr;
}

void FactoryObjectImplementation::markQueueEntryBlocked(int index, int status, const String& reason) {
	if (index < 0 || index >= queueStatuses.size())
		return;
	queueStatuses.set(index, status);
	queueBlockedReasons.set(index, reason);
	queueEvaluationTimes.set(index, (unsigned long long)Time().getTime());
	warning() << "Factory queue entry blocked. FactoryID: " << getObjectID() << " SchematicID: " << queueSchematicIDs.get(index) << " Position: " << index + 1 << " Reason: " << reason;
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

	bool activated = false;
	for (int i = 0; i < queueSchematicIDs.size(); ++i) {
		if (queueStatuses.get(i) == QUEUE_COMPLETED)
			continue;
		ManagedReference<ManufactureSchematic*> schematic = server->getZoneServer()->getObject(queueSchematicIDs.get(i)).castTo<ManufactureSchematic*>();
		if (schematic == nullptr) {
			markQueueEntryBlocked(i, QUEUE_BLOCKED_INVALID, "Manufacturing schematic could not be resolved.");
			continue;
		}
		if (queueRemainingLimits.get(i) <= 0) {
			queueStatuses.set(i, QUEUE_COMPLETED);
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
			info() << "Factory queue readiness failed. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Position: " << i + 1 << " Validation: " << (type == "resource" ? "MISSING_RESOURCES" : "MISSING_COMPONENTS") << " Detail: " << displayedName;
			markQueueEntryBlocked(i, type == "resource" ? QUEUE_BLOCKED_RESOURCES : QUEUE_BLOCKED_COMPONENTS, displayedName);
			continue;
		}
		if (!isQueuedOutputReady(schematic)) {
			info() << "Factory queue readiness failed. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Position: " << i + 1 << " Validation: OUTPUT_FULL";
			markQueueEntryBlocked(i, QUEUE_BLOCKED_OUTPUT_FULL, "Output hopper is full.");
			continue;
		}
		info() << "Factory queue readiness passed. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Position: " << i + 1 << " Validation: RUNNABLE Output: READY";
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
	if (!activated)
		info() << "Factory queue exhausted or blocked. FactoryID: " << getObjectID();
	if (!activated && queueSchematicIDs.size() > 0 && getPendingTask("factoryQueueRetry") == nullptr) {
		Reference<FactoryQueueRetryTask*> retryTask = new FactoryQueueRetryTask(_this.getReferenceUnsafeStaticCast());
		addPendingTask("factoryQueueRetry", retryTask, 60000);
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
	if (player == nullptr || schematic == nullptr || !isOnAdminList(player) || !schematic->isASubChildOf(player)) return false;
	restoreQueueMetadata();
	int previousQueueSize = queueSchematicIDs.size();
	unsigned long long existingActiveID = 0;
	for (int i = 0; i < queueStatuses.size(); ++i)
		if (queueStatuses.get(i) == QUEUE_ACTIVE) {
			existingActiveID = queueSchematicIDs.get(i);
			break;
		}
	info() << "Factory queue insertion requested. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " QueueSize: " << previousQueueSize << " ExistingActiveSchematicID: " << existingActiveID;
	if (queueSchematicIDs.size() >= MAX_FACTORY_QUEUE) {
		player->sendSystemMessage("This factory queue already contains 10 manufacturing schematics.");
		info() << "Factory queue insertion rejected. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Validation: QUEUE_FULL";
		return false;
	}
	if (!schematic->isManufactureSchematic() || schematic->getDraftSchematic() == nullptr) {
		info() << "Factory queue insertion rejected. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Validation: INVALID_SCHEMATIC";
		return false;
	}
	ManagedReference<SceneObject*> parent = schematic->getParent().get();
	if (findQueueEntry(schematic->getObjectID()) >= 0 || (parent != nullptr && parent->isFactory())) {
		player->sendSystemMessage("That manufacturing schematic is already assigned to another factory.");
		return false;
	}
	bool match = false;
	for (int i = 0; i < craftingTabsSupported.size(); ++i)
		if (craftingTabsSupported.get(i) == schematic->getDraftSchematic()->getToolTab()) match = true;
	if (!match) {
		player->sendSystemMessage("This schematic is not compatible with this type of manufacturing installation.");
		info() << "Factory queue insertion rejected. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Validation: INCOMPATIBLE_SCHEMATIC";
		return false;
	}
	// Factory templates have a legacy volume limit of one. The queue enforces its
	// own schematic-only limit above, so bypass that legacy limit for entries 2-10.
	if (!transferObject(schematic, -1, true, true)) {
		player->sendSystemMessage("The manufacturing schematic could not be stored in this factory.");
		info() << "Factory queue insertion rejected. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Validation: CONTAINMENT_TRANSFER_FAILED";
		return false;
	}
	queueSchematicIDs.add(schematic->getObjectID());
	queueSequence.add(queueSchematicIDs.size());
	queueRequestedLimits.add(schematic->getManufactureLimit());
	queueRemainingLimits.add(schematic->getManufactureLimit());
	queueStatuses.add(previousQueueSize == 0 ? QUEUE_ACTIVE : QUEUE_WAITING);
	queueBlockedReasons.add("");
	queueEvaluationTimes.add(0);
	if (previousQueueSize == 0 && syncActiveQueueEntryToFactory() == nullptr) {
		markQueueEntryBlocked(0, QUEUE_BLOCKED_INVALID, "New active manufacturing schematic could not be synchronized.");
	}
	unsigned long long activeAfterInsert = existingActiveID;
	for (int i = 0; i < queueStatuses.size(); ++i)
		if (queueStatuses.get(i) == QUEUE_ACTIVE) {
			activeAfterInsert = queueSchematicIDs.get(i);
			break;
		}
	info() << "Factory queue insertion accepted. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Validation: ACCEPTED Position: " << queueSchematicIDs.size() << " Status: " << (previousQueueSize == 0 ? "ACTIVE" : "WAITING") << " ActiveSchematicID: " << activeAfterInsert << " LegacyActiveChanged: " << (existingActiveID != activeAfterInsert ? "true" : "false");
	if (queueEnabled && !isActive()) evaluateManufacturingQueue();
	return true;
}

/*
 * Opens a SUI with all manufacturing schematics available for the player to insert into factory
 */
void FactoryObjectImplementation::sendInsertManuSui(CreatureObject* player) {
	ManagedReference<SuiListBox*> schematics = nullptr;

	if (getContainerObjectsSize() == 0) {
		schematics = new SuiListBox(player, SuiWindowType::FACTORY_SCHEMATIC2BUTTON, SuiListBox::HANDLETWOBUTTON);
		schematics->setPromptText("Choose a schematic to be added to the factory.");
	} else {
		schematics = new SuiListBox(player, SuiWindowType::FACTORY_SCHEMATIC3BUTTON, SuiListBox::HANDLETHREEBUTTON);

		StringBuffer message;
		message << "Current Schematic Installed: ";

		ManufactureSchematic* activeSchematic = getActiveQueuedSchematic();
		if (activeSchematic == nullptr)
			message << "No active schematic";
		else if (activeSchematic->getCustomObjectName().isEmpty())
			message << "@" << activeSchematic->getObjectNameStringIdFile() << ":" << activeSchematic->getObjectNameStringIdName();
		else
			message << activeSchematic->getCustomObjectName().toString();

		schematics->setPromptText(message.toString());

		schematics->setOtherButton(true, "@remove_schematic");
	}

	schematics->setHandlerText("handleUpdateSchematic");
	schematics->setPromptTitle("SCHEMATIC MANAGEMENT"); // found a SS with this as the title so...

	schematics->setOkButton(true, "@use_schematic");
	schematics->setCancelButton(true, "@cancel");

	/*
	 * Insert only the schematics that can be used in this type of factory
	 */
	ManagedReference<SceneObject*> datapad = player->getSlottedObject("datapad");

	for (int i = 0; i < datapad->getContainerObjectsSize(); ++i) {
		ManagedReference<SceneObject*> datapadObject = datapad->getContainerObject(i);

		if (datapadObject != nullptr && datapadObject->isManufactureSchematic()) {
			ManagedReference<ManufactureSchematic*> manSchem = dynamic_cast<ManufactureSchematic*>(datapadObject.get());

			if (manSchem->getDraftSchematic() == nullptr)
				continue;

			uint32 craftingTabId = manSchem->getDraftSchematic()->getToolTab();

			bool match = false;

			for (int j = 0; j < craftingTabsSupported.size(); ++j) {
				if (craftingTabId == craftingTabsSupported.get(j)) {
					match = true;
					break;
				}
			}

			if (!match)
				continue;

			String sendname;

			if (manSchem->getCustomObjectName().isEmpty())
				sendname = "@" + manSchem->getObjectNameStringIdFile() + ":" + manSchem->getObjectNameStringIdName();
			else
				sendname = manSchem->getCustomObjectName().toString();

			schematics->addMenuItem(sendname, manSchem->getObjectID());
		}
	}

	schematics->setCallback(new InsertSchematicSuiCallback(server->getZoneServer()));

	schematics->setUsingObject(_this.getReferenceUnsafeStaticCast());
	player->getPlayerObject()->addSuiBox(schematics);
	player->sendMessage(schematics->generateMessage());
}

void FactoryObjectImplementation::sendManufacturingQueueSui(CreatureObject* player) {
	if (player == nullptr || !isOnAdminList(player)) return;
	restoreQueueMetadata();
	ManagedReference<SuiListBox*> queue = new SuiListBox(player, SuiWindowType::FACTORY_SCHEMATIC3BUTTON, SuiListBox::HANDLETHREEBUTTON);
	queue->setPromptTitle("MANUFACTURING QUEUE");
	queue->setPromptText("Select an entry. OK retries it; Remove unlocks it and returns it to your datapad.");
	queue->setOtherButton(true, "@remove_schematic");
	queue->setOkButton(true, "@retry");
	queue->setCancelButton(true, "@cancel");
	for (int i = 0; i < queueSchematicIDs.size(); ++i) {
		ManagedReference<ManufactureSchematic*> schematic = server->getZoneServer()->getObject(queueSchematicIDs.get(i)).castTo<ManufactureSchematic*>();
		String name = schematic == nullptr ? "Invalid schematic" : (schematic->getCustomObjectName().isEmpty() ? "@" + schematic->getObjectNameStringIdFile() + ":" + schematic->getObjectNameStringIdName() : schematic->getCustomObjectName().toString());
		String status = "WAITING";
		switch (queueStatuses.get(i)) {
		case QUEUE_ACTIVE: status = "ACTIVE"; break;
		case QUEUE_BLOCKED_RESOURCES: status = "BLOCKED_RESOURCES"; break;
		case QUEUE_BLOCKED_COMPONENTS: status = "BLOCKED_COMPONENTS"; break;
		case QUEUE_BLOCKED_OUTPUT_FULL: status = "BLOCKED_OUTPUT_FULL"; break;
		case QUEUE_BLOCKED_POWER: status = "BLOCKED_POWER"; break;
		case QUEUE_BLOCKED_MAINTENANCE: status = "BLOCKED_MAINTENANCE"; break;
		case QUEUE_BLOCKED_INVALID: status = "BLOCKED_INVALID"; break;
		case QUEUE_COMPLETED: status = "COMPLETED"; break;
		default: break;
		}
		String row = String::valueOf(i + 1) + ". " + name + " [" + status + ", remaining " + String::valueOf(queueRemainingLimits.get(i)) + "]";
		if (!queueBlockedReasons.get(i).isEmpty()) row += " - " + queueBlockedReasons.get(i);
		queue->addMenuItem(row, queueSchematicIDs.get(i));
	}
	queue->setCallback(new ManageFactoryQueueSuiCallback(server->getZoneServer()));
	queue->setUsingObject(_this.getReferenceUnsafeStaticCast());
	player->getPlayerObject()->addSuiBox(queue);
	player->sendMessage(queue->generateMessage());
}


/*
 * Opens a SUI with all manufacturing schematics available for the player to insert into factory
 */
void FactoryObjectImplementation::sendIngredientsNeededSui(CreatureObject* player) {
	if (player == nullptr || getContainerObjectsSize() == 0)
		return;

	ManagedReference<ManufactureSchematic*> schematic = getActiveQueuedSchematic();

	// A stopped queue normally has no ACTIVE entry. In that state, show the
	// ingredients for the first valid queued schematic instead.
	if (schematic == nullptr) {
		restoreQueueMetadata();

		for (int i = 0; i < queueSchematicIDs.size(); ++i) {
			schematic = server->getZoneServer()->getObject(queueSchematicIDs.get(i)).castTo<ManufactureSchematic*>();

			if (schematic != nullptr)
				break;
		}
	}

	if (schematic == nullptr) {
		player->sendSystemMessage("No valid manufacturing schematic is available in this factory queue.");
		return;
	}

	ManagedReference<SuiListBox*> ingredientList = new SuiListBox(player, SuiWindowType::FACTORY_INGREDIENTS);
	ingredientList->setPromptTitle("@base_player:swg"); // STAR WARS GALAXIES - found a SS with this as the title so....

	ingredientList->setPromptText("@manf_station:examine_prompt"); // Ingredients required to manufacture an item at this station.

	ingredientList->setOkButton(true, "@ok");

	for (int i = 0; i < schematic->getBlueprintSize(); ++i) {
		BlueprintEntry* blueprintEntry = schematic->getBlueprintEntry(i);

		if (blueprintEntry != nullptr)
			blueprintEntry->insertFactoryIngredient(ingredientList);
	}

	ingredientList->setUsingObject(_this.getReferenceUnsafeStaticCast());
	player->getPlayerObject()->addSuiBox(ingredientList);
	player->sendMessage(ingredientList->generateMessage());
}

void FactoryObjectImplementation::sendIngredientHopper(CreatureObject* player) {
	ManagedReference<SceneObject*> inputHopper = getSlottedObject("ingredient_hopper");

	if (inputHopper == nullptr) {
		return;
	}

#ifdef DEBUG_FACTORIES
	info(true) << "sendIngredientHopper - Player: " << player->getFirstName();
#endif

	inputHopper->sendWithoutContainerObjectsTo(player);
	inputHopper->openContainerTo(player);
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
	if (addQueuedSchematic(player, schematic))
		player->sendSystemMessage("The manufacturing schematic was added to the factory queue.");
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
	if (player == nullptr || queueIndex < 0)
		return false;
	restoreQueueMetadata();
	if (queueIndex >= queueSchematicIDs.size()) return false;
	if (queueStatuses.get(queueIndex) == QUEUE_ACTIVE && isActive()) {
		player->sendSystemMessage("Stop the factory before removing the active schematic.");
		return false;
	}

	ManagedReference<SceneObject*> datapad = player->getSlottedObject("datapad");
	ManagedReference<SceneObject*> schematic = server->getZoneServer()->getObject(queueSchematicIDs.get(queueIndex));

	if (schematic == nullptr) {
		unsigned long long invalidID = queueSchematicIDs.get(queueIndex);
		queueSchematicIDs.remove(queueIndex);
		queueSequence.remove(queueIndex);
		queueRequestedLimits.remove(queueIndex);
		queueRemainingLimits.remove(queueIndex);
		queueStatuses.remove(queueIndex);
		queueBlockedReasons.remove(queueIndex);
		queueEvaluationTimes.remove(queueIndex);
		for (int i = 0; i < queueSequence.size(); ++i) queueSequence.set(i, i + 1);
		player->sendSystemMessage("The invalid manufacturing queue entry was removed.");
		info() << "Invalid factory queue entry removed. FactoryID: " << getObjectID() << " SchematicID: " << invalidID << " Position: " << queueIndex + 1;
		return true;
	}

	if (datapad == nullptr || !schematic->isManufactureSchematic())
		return false;

	ManagedReference<ManufactureSchematic*> manuSchem = schematic.castTo<ManufactureSchematic*>();

	if (manuSchem == nullptr)
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

	StringIdChatParameter message("manf_station", "schematic_removed"); // Schematic %TT has been removed from the station and been placed in your datapad. Have a nice day!

	if (schematic->getCustomObjectName().isEmpty()) {
		message.setTT(schematic->getObjectNameStringIdFile(), schematic->getObjectNameStringIdName());
	} else {
		message.setTT(schematic->getCustomObjectName().toString());
	}

	player->sendSystemMessage(message);
	queueSchematicIDs.remove(queueIndex);
	queueSequence.remove(queueIndex);
	queueRequestedLimits.remove(queueIndex);
	queueRemainingLimits.remove(queueIndex);
	queueStatuses.remove(queueIndex);
	queueBlockedReasons.remove(queueIndex);
	queueEvaluationTimes.remove(queueIndex);
	for (int i = 0; i < queueSequence.size(); ++i) queueSequence.set(i, i + 1);
	info() << "Factory queue entry removed. FactoryID: " << getObjectID() << " SchematicID: " << manuSchem->getObjectID() << " Position: " << queueIndex + 1;
	restoreQueueMetadata();
	evaluateManufacturingQueue();

	return true;
}

bool FactoryObjectImplementation::moveQueuedSchematic(CreatureObject* player, int queueIndex, int direction) {
	if (player == nullptr || !isOnAdminList(player)) return false;
	restoreQueueMetadata();
	int other = queueIndex + direction;
	if (queueIndex < 0 || queueIndex >= queueSchematicIDs.size() || other < 0 || other >= queueSchematicIDs.size()) return false;
	if (queueStatuses.get(queueIndex) == QUEUE_ACTIVE || queueStatuses.get(other) == QUEUE_ACTIVE) {
		player->sendSystemMessage("The active schematic cannot be reordered while the factory is operating.");
		return false;
	}
	unsigned long long schematicID = queueSchematicIDs.get(queueIndex); queueSchematicIDs.set(queueIndex, queueSchematicIDs.get(other)); queueSchematicIDs.set(other, schematicID);
	unsigned long long sequence = queueSequence.get(queueIndex); queueSequence.set(queueIndex, queueSequence.get(other)); queueSequence.set(other, sequence);
	int requested = queueRequestedLimits.get(queueIndex); queueRequestedLimits.set(queueIndex, queueRequestedLimits.get(other)); queueRequestedLimits.set(other, requested);
	int remaining = queueRemainingLimits.get(queueIndex); queueRemainingLimits.set(queueIndex, queueRemainingLimits.get(other)); queueRemainingLimits.set(other, remaining);
	int status = queueStatuses.get(queueIndex); queueStatuses.set(queueIndex, queueStatuses.get(other)); queueStatuses.set(other, status);
	String reason = queueBlockedReasons.get(queueIndex); queueBlockedReasons.set(queueIndex, queueBlockedReasons.get(other)); queueBlockedReasons.set(other, reason);
	unsigned long long evaluated = queueEvaluationTimes.get(queueIndex); queueEvaluationTimes.set(queueIndex, queueEvaluationTimes.get(other)); queueEvaluationTimes.set(other, evaluated);
	for (int i = 0; i < queueSequence.size(); ++i) queueSequence.set(i, i + 1);
	info() << "Factory queue reordered. FactoryID: " << getObjectID() << " Position: " << queueIndex + 1;
	return true;
}

void FactoryObjectImplementation::retryQueuedSchematic(int queueIndex) {
	restoreQueueMetadata();
	if (queueIndex >= 0 && queueIndex < queueStatuses.size() && queueStatuses.get(queueIndex) != QUEUE_ACTIVE) {
		queueStatuses.set(queueIndex, QUEUE_WAITING);
		queueBlockedReasons.set(queueIndex, "");
	}
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
		player->sendSystemMessage("No schematic, unable to start");
		return;
	}

	if (!queueEnabled) {
		queueEnabled = true;
		currentUserName = player->getFirstName();
		currentRunCount = 0;

		int activeIndex = -1;
		unsigned long long activeSchematicID = 0;
		for (int i = 0; i < queueStatuses.size(); ++i)
			if (queueStatuses.get(i) == QUEUE_ACTIVE) {
				activeIndex = i;
				activeSchematicID = queueSchematicIDs.get(i);
				break;
			}
		ManagedReference<SceneObject*> legacyContainerSchematic = getContainerObjectsSize() > 0 ? getContainerObject(0) : nullptr;
		info() << "Factory start requested. FactoryID: " << getObjectID() << " QueueSize: " << queueSchematicIDs.size() << " ActiveQueueIndex: " << activeIndex << " ActiveSchematicID: " << activeSchematicID << " ResolvedActive: " << (getActiveQueuedSchematic() != nullptr ? "true" : "false") << " LegacyContainerSchematicID: " << (legacyContainerSchematic != nullptr ? legacyContainerSchematic->getObjectID() : 0) << " Operating: " << (isActive() ? "true" : "false");

		evaluateManufacturingQueue();
		if (isActive()) {
			ManagedReference<ManufactureSchematic*> schematic = syncActiveQueueEntryToFactory();
			player->sendSystemMessage("@manf_station:activated"); // Station activated
			if (schematic != nullptr)
				player->sendSystemMessage("This schematic limit is: " + String::valueOf(schematic->getManufactureLimit()));
		} else {
			player->sendSystemMessage("The factory could not start. Check the factory log for the exact queue validation failure.");
		}
	} else {
		queueEnabled = false;
		stopFactory("manf_done", getDisplayedName(), "", currentRunCount);
		Reference<Task*> retryTask = getPendingTask("factoryQueueRetry");
		removePendingTask("factoryQueueRetry");
		if (retryTask != nullptr && retryTask->isScheduled()) retryTask->cancel();
		player->sendSystemMessage("@manf_station:deactivated"); // Station deactivated
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
		return;
	}

	ManagedReference<ManufactureSchematic*> schematic = getActiveQueuedSchematic();

	if (schematic == nullptr || !schematic->isManufactureSchematic()) {
		stopFactory("manf_error_4", "", "", -1);
		return;
	}

	ManagedReference<TangibleObject*> prototype = cast<TangibleObject*>(schematic->getPrototype());

	if (prototype == nullptr) {
		stopFactory("manf_error_2", "", "", -1);
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

	String type = "";
	String displayedName = "";

	schematic->canManufactureItem(type, displayedName);

	if (displayedName != "") {
		int queueIndex = findQueueEntry(schematic->getObjectID());
		markQueueEntryBlocked(queueIndex, type == "resource" ? QUEUE_BLOCKED_RESOURCES : QUEUE_BLOCKED_COMPONENTS, displayedName);
		stopFactory(type, displayedName);
		evaluateManufacturingQueue();
		return;
	}

	int crateSize = schematic->getFactoryCrateSize();

	if (crateSize <= 0) {
		stopFactory("manf_error", "", "", -1);
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
	if (queueIndex >= 0)
		queueRemainingLimits.set(queueIndex, schematic->getManufactureLimit());
	info() << "Factory production item completed. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " QueuePosition: " << queueIndex + 1 << " ManufacturedCount: " << currentRunCount << " RemainingProduction: " << schematic->getManufactureLimit();

	if (schematic->getManufactureLimit() < 1) {
		unsigned long long completedSchematicID = schematic->getObjectID();
		if (queueIndex >= 0) {
			queueStatuses.set(queueIndex, QUEUE_COMPLETED);
			info() << "Factory queue entry completed. FactoryID: " << getObjectID() << " SchematicID: " << schematic->getObjectID() << " Position: " << queueIndex + 1;
			queueSchematicIDs.remove(queueIndex);
			queueSequence.remove(queueIndex);
			queueRequestedLimits.remove(queueIndex);
			queueRemainingLimits.remove(queueIndex);
			queueStatuses.remove(queueIndex);
			queueBlockedReasons.remove(queueIndex);
			queueEvaluationTimes.remove(queueIndex);
			for (int i = 0; i < queueSequence.size(); ++i) queueSequence.set(i, i + 1);
		}
		schematic->destroyObjectFromWorld(true);
		schematic->destroyObjectFromDatabase(true);
		stopFactory("manf_done", getDisplayedName(), "", currentRunCount);
		info() << "Factory queue advancing after completion. FactoryID: " << getObjectID() << " CompletedSchematicID: " << completedSchematicID << " RemainingQueueSize: " << queueSchematicIDs.size();
		if (queueSchematicIDs.size() == 0) {
			queueEnabled = false;
			currentUserName = "";
			info() << "Factory queue completed and stopped. FactoryID: " << getObjectID() << " Reason: QUEUE_EMPTY";
		} else {
			evaluateManufacturingQueue();
		}
		return;
	}

	Reference<Task*> pending = getPendingTask("createFactoryObject");

	if (pending != nullptr)
		pending->reschedule(timer * 1000);
	else
		stopFactory("manf_error", "", "", -1);
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
