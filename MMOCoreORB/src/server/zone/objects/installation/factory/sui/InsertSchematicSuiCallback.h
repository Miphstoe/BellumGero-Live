#ifndef INSERTSCHEMATICSUICALLBACK_H_
#define INSERTSCHEMATICSUICALLBACK_H_

#include "server/zone/objects/installation/factory/FactoryObject.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/manufactureschematic/ManufactureSchematic.h"

class InsertSchematicSuiCallback : public SuiCallback, public Logger {
public:
	InsertSchematicSuiCallback(ZoneServer* server)
		: SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr)
			return;

		if (eventIndex == 1)
			return;

		if (!suiBox->isListBox() || args == nullptr || args->size() < 2)
			return;

		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();

		if (object == nullptr || !object->isFactory())
			return;

		FactoryObject* factory = cast<FactoryObject*>(object.get());

		Locker playerLocker(player);
		Locker factoryLocker(factory, player);

		bool backPressed = Bool::valueOf(args->get(0).toString());

		if (backPressed) {
			factory->sendManufacturingQueueSui(player);
			return;
		}

		int index = Integer::valueOf(args->get(1).toString());

		if (index < 0)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);

		ManagedReference<ManufactureSchematic*> schematic =
			server->getObject(listBox->getMenuObjectID(index)).castTo<ManufactureSchematic*>();

		if (schematic == nullptr)
			return;

		factory->sendManufacturingBatchAmountSui(
			player,
			schematic,
			schematic->getManufactureLimit());
	}
};

class FactoryQueueBatchAmountSuiCallback : public SuiCallback {
private:
	unsigned long long schematicID;

public:
	FactoryQueueBatchAmountSuiCallback(ZoneServer* server, unsigned long long id)
		: SuiCallback(server), schematicID(id) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isInputBox())
			return;

		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();

		if (object == nullptr || !object->isFactory())
			return;

		FactoryObject* factory = cast<FactoryObject*>(object.get());

		Locker playerLocker(player);
		Locker factoryLocker(factory, player);

		ManagedReference<ManufactureSchematic*> schematic =
			server->getObject(schematicID).castTo<ManufactureSchematic*>();

		if (schematic == nullptr || !schematic->isASubChildOf(player)) {
			player->sendSystemMessage("That manufacturing schematic is no longer available.");
			factory->sendInsertManuSui(player);
			return;
		}

		if (eventIndex == 1) {
			factory->sendInsertManuSui(player);
			return;
		}

		if (args == nullptr || args->size() < 1)
			return;

		int requestedAmount = 0;

		try {
			requestedAmount = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			player->sendSystemMessage("Enter a whole-number production amount.");
			factory->sendManufacturingBatchAmountSui(
				player,
				schematic,
				schematic->getManufactureLimit());
			return;
		}

		int maxAmount = schematic->getManufactureLimit();

		if (requestedAmount < 1 || requestedAmount > maxAmount) {
			player->sendSystemMessage(
				"Enter a production amount between 1 and " + String::valueOf(maxAmount) + ".");

			factory->sendManufacturingBatchAmountSui(player, schematic, maxAmount);
			return;
		}

		factory->sendManufacturingBatchConfirmSui(player, schematic, requestedAmount);
	}
};

class FactoryQueueBatchConfirmSuiCallback : public SuiCallback {
private:
	unsigned long long schematicID;
	int requestedAmount;

public:
	FactoryQueueBatchConfirmSuiCallback(ZoneServer* server, unsigned long long id, int amount)
		: SuiCallback(server), schematicID(id), requestedAmount(amount) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr)
			return;

		if (eventIndex == 1)
			return;

		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();

		if (object == nullptr || !object->isFactory())
			return;

		FactoryObject* factory = cast<FactoryObject*>(object.get());

		Locker playerLocker(player);
		Locker factoryLocker(factory, player);

		ManagedReference<ManufactureSchematic*> schematic =
			server->getObject(schematicID).castTo<ManufactureSchematic*>();

		if (schematic == nullptr || !schematic->isASubChildOf(player)) {
			player->sendSystemMessage("That manufacturing schematic is no longer available.");
			factory->sendManufacturingQueueSui(player);
			return;
		}

		bool backPressed = false;

		if (args != nullptr && args->size() > 0)
			backPressed = Bool::valueOf(args->get(0).toString());

		if (backPressed) {
			factory->sendManufacturingBatchAmountSui(player, schematic, requestedAmount);
			return;
		}

		if (requestedAmount < 1 || requestedAmount > schematic->getManufactureLimit()) {
			player->sendSystemMessage("The schematic's remaining uses changed. Please choose the production amount again.");
			factory->sendManufacturingBatchAmountSui(
				player,
				schematic,
				schematic->getManufactureLimit());
			return;
		}

		if (factory->addQueuedSchematicBatch(player, schematic, requestedAmount)) {
			player->sendSystemMessage(
				"The manufacturing schematic was added to the factory queue for a batch of " +
				String::valueOf(requestedAmount) + ".");

			factory->sendManufacturingQueueSui(player);
		} else {
			factory->sendInsertManuSui(player);
		}
	}
};

#endif
