#ifndef MANAGEFACTORYQUEUESUICALLBACK_H_
#define MANAGEFACTORYQUEUESUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"
#include "server/zone/objects/installation/factory/FactoryObject.h"

class ManageFactoryQueueSuiCallback : public SuiCallback {
public:
	enum QueueAction {
		ACTION_VIEW_REQUIREMENTS = 1,
		ACTION_MOVE_UP = 2,
		ACTION_MOVE_DOWN = 3,
		ACTION_RECHECK = 4,
		ACTION_REMOVE = 5,
		ACTION_LOAD_BATCH_INGREDIENTS = 6,
		ACTION_MANAGE_INGREDIENT_HOPPER = 7,
		ACTION_UPDATE_BATCH_AMOUNT = 8
	};

private:
	unsigned long long selectedSchematicID;

public:
	ManageFactoryQueueSuiCallback(ZoneServer* server, unsigned long long schematicID = 0)
		: SuiCallback(server), selectedSchematicID(schematicID) {
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

		if (selectedSchematicID == 0) {
			if (!suiBox->isListBox() || args == nullptr || args->size() < 2)
				return;

			bool addPressed = Bool::valueOf(args->get(0).toString());

			if (addPressed) {
				factory->sendInsertManuSui(player);
				return;
			}

			SuiListBox* listBox = cast<SuiListBox*>(suiBox);
			int row = Integer::valueOf(args->get(1).toString());

			if (row < 0)
				return;

			unsigned long long schematicID = listBox->getMenuObjectID(row);

			if (schematicID == 0)
				return;

			int queueIndex = factory->getManufacturingQueueIndex(schematicID);

			if (queueIndex < 0) {
				player->sendSystemMessage("That manufacturing queue entry is no longer available.");
				factory->sendManufacturingQueueSui(player);
				return;
			}

			factory->sendManufacturingQueueEntrySui(player, queueIndex);
			return;
		}

		int queueIndex = factory->getManufacturingQueueIndex(selectedSchematicID);

		if (queueIndex < 0) {
			player->sendSystemMessage("That manufacturing queue entry is no longer available.");
			factory->sendManufacturingQueueSui(player);
			return;
		}

		if (suiBox->getWindowType() == SuiWindowType::FACTORY_QUEUE_LOAD_INGREDIENTS) {
			if (args == nullptr || args->size() < 2)
				return;

			bool backPressed = Bool::valueOf(args->get(0).toString());

			if (backPressed) {
				factory->sendManufacturingQueueEntrySui(player, queueIndex);
				return;
			}

			factory->loadBatchIngredientsFromInventory(player, queueIndex);
			factory->sendQueuedSchematicIngredientsSui(player, queueIndex);
			return;
		}

		if (suiBox->getWindowType() == SuiWindowType::FACTORY_QUEUE_HOPPER_MANAGER) {
			if (!suiBox->isListBox() || args == nullptr || args->size() < 2)
				return;

			bool backPressed = Bool::valueOf(args->get(0).toString());

			if (backPressed) {
				factory->sendManufacturingQueueEntrySui(player, queueIndex);
				return;
			}

			SuiListBox* listBox = cast<SuiListBox*>(suiBox);
			int row = Integer::valueOf(args->get(1).toString());

			if (row < 0)
				return;

			unsigned long long ingredientID = listBox->getMenuObjectID(row);

			if (ingredientID == 0)
				return;

			factory->returnFactoryIngredientToInventory(player, ingredientID);
			factory->sendFactoryIngredientHopperManagerSui(player, queueIndex);
			return;
		}

		if (suiBox->getWindowType() == SuiWindowType::FACTORY_INGREDIENTS) {
			factory->sendManufacturingQueueEntrySui(player, queueIndex);
			return;
		}

		if (!suiBox->isListBox() || args == nullptr || args->size() < 2)
			return;

		bool backPressed = Bool::valueOf(args->get(0).toString());

		if (backPressed) {
			factory->sendManufacturingQueueSui(player);
			return;
		}

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);
		int row = Integer::valueOf(args->get(1).toString());

		if (row < 0)
			return;

		int action = (int)listBox->getMenuObjectID(row);

		switch (action) {
		case ACTION_VIEW_REQUIREMENTS:
			factory->sendQueuedSchematicIngredientsSui(player, queueIndex);
			return;
		case ACTION_LOAD_BATCH_INGREDIENTS:
			factory->sendLoadBatchIngredientsSui(player, queueIndex);
			return;
		case ACTION_MANAGE_INGREDIENT_HOPPER:
			factory->sendFactoryIngredientHopperManagerSui(player, queueIndex);
			return;
		case ACTION_UPDATE_BATCH_AMOUNT:
			factory->sendManufacturingBatchEditAmountSui(player, queueIndex);
			return;
		case ACTION_MOVE_UP:
			factory->moveQueuedSchematic(player, queueIndex, -1);
			break;
		case ACTION_MOVE_DOWN:
			factory->moveQueuedSchematic(player, queueIndex, 1);
			break;
		case ACTION_RECHECK:
			factory->retryQueuedSchematic(queueIndex);
			break;
		case ACTION_REMOVE:
			factory->removeQueuedSchematic(player, queueIndex);
			break;
		default:
			return;
		}

		factory->sendManufacturingQueueSui(player);
	}
};

class FactoryQueueBatchEditAmountSuiCallback : public SuiCallback {
private:
	unsigned long long schematicID;

public:
	FactoryQueueBatchEditAmountSuiCallback(ZoneServer* server, unsigned long long id)
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

		int queueIndex = factory->getManufacturingQueueIndex(schematicID);

		if (queueIndex < 0) {
			player->sendSystemMessage("That manufacturing queue entry is no longer available.");
			factory->sendManufacturingQueueSui(player);
			return;
		}

		if (eventIndex == 1) {
			factory->sendManufacturingQueueEntrySui(player, queueIndex);
			return;
		}

		if (args == nullptr || args->size() < 1)
			return;

		int requestedAmount = 0;

		try {
			requestedAmount = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			player->sendSystemMessage("Enter a whole-number total batch amount.");
			factory->sendManufacturingBatchEditAmountSui(player, queueIndex);
			return;
		}

		factory->sendManufacturingBatchEditConfirmSui(player, queueIndex, requestedAmount);
	}
};

class FactoryQueueBatchEditConfirmSuiCallback : public SuiCallback {
private:
	unsigned long long schematicID;
	int requestedAmount;

public:
	FactoryQueueBatchEditConfirmSuiCallback(ZoneServer* server, unsigned long long id, int amount)
		: SuiCallback(server), schematicID(id), requestedAmount(amount) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr)
			return;

		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();

		if (object == nullptr || !object->isFactory())
			return;

		FactoryObject* factory = cast<FactoryObject*>(object.get());

		Locker playerLocker(player);
		Locker factoryLocker(factory, player);

		int queueIndex = factory->getManufacturingQueueIndex(schematicID);

		if (queueIndex < 0) {
			player->sendSystemMessage("That manufacturing queue entry is no longer available.");
			factory->sendManufacturingQueueSui(player);
			return;
		}

		if (eventIndex == 1)
			return;

		bool backPressed = false;

		if (args != nullptr && args->size() > 0)
			backPressed = Bool::valueOf(args->get(0).toString());

		if (backPressed) {
			factory->sendManufacturingBatchEditAmountSui(player, queueIndex);
			return;
		}

		factory->updateQueuedSchematicBatchAmount(player, queueIndex, requestedAmount);

		int refreshedIndex = factory->getManufacturingQueueIndex(schematicID);

		if (refreshedIndex >= 0)
			factory->sendManufacturingQueueEntrySui(player, refreshedIndex);
		else
			factory->sendManufacturingQueueSui(player);
	}
};

#endif
