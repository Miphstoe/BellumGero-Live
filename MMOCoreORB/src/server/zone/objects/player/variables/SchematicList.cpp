/*
 * SchematicList.cpp
 *
 *  Created on: 6/3/2010
 *      Author: kyle
 */

#include "SchematicList.h"

#include "server/zone/objects/player/PlayerObject.h"

bool SchematicList::toBinaryStream(ObjectOutputStream* stream) {

	TypeInfo<VectorMap<ManagedReference<DraftSchematic* >, int > >::toBinaryStream(&rewardedSchematics, stream);
	//schematics.toBinaryStream(stream);

	return true;
}

void to_json(nlohmann::json& j, const SchematicList& l) {
	to_json(j, l.rewardedSchematics);
}

bool SchematicList::parseFromBinaryStream(ObjectInputStream* stream) {

	TypeInfo<VectorMap<ManagedReference<DraftSchematic* >, int > >::parseFromBinaryStream(&rewardedSchematics, stream);
	//schematics.parseFromBinaryStream(stream);

	return true;
}

void SchematicList::addRewardedSchematics(SceneObject* player) {
	if (player->isPlayerObject()) {
		PlayerObject* ghost = cast<PlayerObject*>(player);

		if (ghost != nullptr) {
			Vector<ManagedReference<DraftSchematic* > > schematics;

			for (int i = rewardedSchematics.size() - 1; i >= 0; --i) {
				DraftSchematic* schem = rewardedSchematics.elementAt(i).getKey();

				if (schem == nullptr) {
					Logger::console.error("Dropping dangling rewarded draft schematic entry (object no longer in database) for player object: " + String::valueOf(ghost->getObjectID()));
					rewardedSchematics.remove(i);
					continue;
				}

				if (schem->isValidDraftSchematic()) {
					schematics.add(schem);
				} else {
					// Quarantine instead of destroy: the template may only be unresolved this
					// boot (rename, lua load failure). Destroying here would permanently delete
					// an earned reward; guards elsewhere keep the entry inert until it resolves.
					Logger::console.error("Quarantining rewarded draft schematic with unresolved template: objectID=" + String::valueOf(schem->getObjectID()) +
							" serverCRC=" + String::valueOf(schem->getServerObjectCRC()) +
							" clientCRC=" + String::valueOf(schem->getClientObjectCRC()) +
							" playerObject=" + String::valueOf(ghost->getObjectID()));
				}
			}

			ghost->addSchematics(schematics, true);
		}
	}
}

bool SchematicList::addRewardedSchematic(DraftSchematic* schematic, short type, int quantity) {
	if (type == MISSION) {
		for(int i = 0; i < rewardedSchematics.size(); ++i) {
			if(rewardedSchematics.elementAt(i).getKey() == schematic) {
				int newQuantity = rewardedSchematics.get(i) + quantity;
				rewardedSchematics.drop(schematic);
				rewardedSchematics.put(schematic, newQuantity);
				return false;
			}
		}
	}
	rewardedSchematics.put(schematic, quantity);
	return true;
}

void SchematicList::removeRewardedSchematic(DraftSchematic* schematic) {
	if(rewardedSchematics.contains(schematic))
		rewardedSchematics.drop(schematic);
}

bool SchematicList::decreaseSchematicUseCount(DraftSchematic* schematic) {
	if(rewardedSchematics.contains(schematic)) {

		for(int i = 0; i < rewardedSchematics.size(); ++i) {
			if(rewardedSchematics.elementAt(i).getKey() == schematic) {
				if(rewardedSchematics.get(i) > 1) {
					int newQuantity = rewardedSchematics.get(i) - 1;
					rewardedSchematics.drop(schematic);
					rewardedSchematics.put(schematic, newQuantity);
					return true;
				} else if(rewardedSchematics.get(i) == 1) {
					removeRewardedSchematic(schematic);
					return true;
				}
			}
		}
	}
	return false;
}

bool SchematicList::add(DraftSchematic* schematic, DeltaMessage* message, int updates) {
	if (schematic == nullptr || !schematic->isValidDraftSchematic())
		return false;

	bool val = vector.add(schematic);

	if (val && message != nullptr) {
		if (updates != 0)
			message->startList(updates, updateCounter += updates);

		message->insertByte(1);
		message->insertShort(vector.size() - 1);

		message->insertInt(schematic->getClientObjectCRC());
		message->insertInt(schematic->getClientObjectCRC()); /// Must be client CRC
	}

	return val;
}

bool SchematicList::contains(DraftSchematic* schematic) const {
	if(schematic == nullptr || !schematic->isValidDraftSchematic())
		return false;

	for(int i = 0; i < size(); ++i) {
		DraftSchematic* existingSchematic = get(i);

		if(existingSchematic == nullptr || !existingSchematic->isValidDraftSchematic())
			continue;

		if((existingSchematic->getClientObjectCRC() == schematic->getClientObjectCRC()) &&
				(existingSchematic->getCustomName() == schematic->getCustomName()))

			return true;
	}

	return false;
}

bool SchematicList::contains(const Vector<ManagedReference<DraftSchematic*>>& filteredschematics, DraftSchematic* schematic) const {
	if(schematic == nullptr || !schematic->isValidDraftSchematic())
		return false;

	for(int i = 0; i < filteredschematics.size(); ++i) {
		DraftSchematic* existingSchematic = filteredschematics.get(i);

		if(existingSchematic == nullptr || !existingSchematic->isValidDraftSchematic())
			continue;

		if((existingSchematic->getClientObjectCRC() == schematic->getClientObjectCRC()) &&
				(existingSchematic->getCustomName() == schematic->getCustomName()))

			return true;
	}

	return false;
}

/**
 *  Complexity Requirements
 	 1 - 15 General Crafting Tool
	16 - 20 Specialized Crafting Tool
	21 - 25 Specialized Crafting Tool + Public Crafting Station
	26 - Specialized Crafting Tool + Private Crafting Station

	http://swg.stratics.com/content/gameplay/guides/guides.php?Cat=664&uid=902
 */

Vector<ManagedReference<DraftSchematic* > > SchematicList::filterSchematicList(
		CreatureObject* player, const Vector<uint32>* enabledTabs, int complexityLevel) const {
	Vector<ManagedReference<DraftSchematic* > > filteredschematics;

	for (int i = 0; i < size(); ++i) {
		const ManagedReference<DraftSchematic*>& schematic = get(i);

		if (schematic == nullptr || !schematic->isValidDraftSchematic())
			continue;

		for(int j = 0; j < enabledTabs->size(); ++j) {
			if(enabledTabs->get(j) == schematic->getToolTab() &&
					schematic->getComplexity() <= complexityLevel) {

					filteredschematics.add(schematic);

				break;
			}
		}
	}
	return filteredschematics;
}

void SchematicList::insertToMessage(BaseMessage* msg) const {
	int validSchematicCount = 0;

	for (int i = 0; i < size(); ++i) {
		DraftSchematic* schematic = get(i);

		if (schematic != nullptr && schematic->isValidDraftSchematic())
			++validSchematicCount;
	}

	msg->insertInt(validSchematicCount);
	msg->insertInt(updateCounter);

	for (int i = 0; i < size(); ++i) {
		DraftSchematic* schematic = get(i);

		if (schematic == nullptr || !schematic->isValidDraftSchematic())
			continue;

		msg->insertInt(schematic->getClientObjectCRC());
		msg->insertInt(schematic->getClientObjectCRC());  /// Must be client CRC
	}
}
