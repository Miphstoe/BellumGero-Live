/*
 * WearableObjectImplementation.cpp
 *
 *  Created on: 02/08/2009
 *      Author: victor
 */

#include "server/zone/objects/tangible/wearables/WearableObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/manufactureschematic/craftingvalues/CraftingValues.h"
#include "server/zone/objects/manufactureschematic/ManufactureSchematic.h"
#include "server/zone/objects/draftschematic/DraftSchematic.h"
#include "server/zone/objects/tangible/attachment/Attachment.h"
#include "server/zone/managers/skill/SkillModManager.h"
#include "server/zone/objects/tangible/wearables/ModSortingHelper.h"
#include "server/zone/objects/transaction/TransactionLog.h"

void WearableObjectImplementation::initializeTransientMembers() {
	TangibleObjectImplementation::initializeTransientMembers();

	// Wearable has too many attachments on it for the allowed socket count
	while (usedSocketCount > socketCount) {
		wearableSkillMods.removeElementAt(wearableSkillMods.size() - 1);

		usedSocketCount--;
	}
}

void WearableObjectImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* object) {
	TangibleObjectImplementation::fillAttributeList(alm, object);

	for(int i = 0; i < wearableSkillMods.size(); ++i) {
		String key = wearableSkillMods.elementAt(i).getKey();
		String statname = "cat_skill_mod_bonus.@stat_n:" + key;
		int value = wearableSkillMods.get(key);

		if (value > 0)
			alm->insertAttribute(statname, value);
	}

	//Anti Decay Kit
	if (hasAntiDecayKit() && !isArmorObject()){
		alm->insertAttribute("@veteran_new:antidecay_examine_title", "@veteran_new:antidecay_examine_text");
	}

}

void WearableObjectImplementation::updateCraftingValues(CraftingValues* values, bool initialUpdate) {
	/*
	 * Values available:	Range:
	 * sockets				0-0(novice artisan) (Don't use)
	 * hitpoints			1000-1000 (Don't Use)
	 */
	if (initialUpdate) {
		if(values->hasExperimentalAttribute("sockets") && values->getCurrentValue("sockets") >= 0)
			generateSockets(values);
	}
}

void WearableObjectImplementation::generateSockets(CraftingValues* craftingValues) {
	if (socketsGenerated) {
		return;
	}

	// Always assign max sockets without randomness
	socketCount = MAXSOCKETS;
	usedSocketCount = 0;

	socketsGenerated = true;
}

void WearableObjectImplementation::applyAttachment(CreatureObject* player, Attachment* attachment) {
	if (attachment == nullptr || !isASubChildOf(player)) {
		return;
	}

	if (getRemainingSockets() < 1 || wearableSkillMods.size() > 5) {
		return;
	}

	if (isEquipped()) {
		removeSkillModsFrom(player);
	}

	Locker clocker(attachment, player);

	SortedVector<ModSortingHelper> sortedMods;
	VectorMap<String, int>* skillModifiers = attachment->getSkillMods();

	for (int i = 0; i < skillModifiers->size(); i++) {
		auto key = skillModifiers->elementAt(i).getKey();
		auto value = skillModifiers->elementAt(i).getValue();

		sortedMods.put(ModSortingHelper(key, value));
	}

	// Select the next mod in the SEA, sorted high-to-low. If that skill mod is already on the
	// wearable, with higher or equal value, don't apply and continue.
	for (int i = 0; i < sortedMods.size(); i++) {
		String modName = sortedMods.elementAt(i).getKey();
		int modValue = sortedMods.elementAt(i).getValue();

		int existingValue = -26;

		if (wearableSkillMods.contains(modName)) {
			existingValue = wearableSkillMods.get(modName);
		}

		if (modValue > existingValue) {
			wearableSkillMods.put(modName, modValue);
		}
	}

	usedSocketCount++;
	addMagicBit(true);

	TransactionLog trx(player, asSceneObject(), attachment, TrxCode::APPLYATTACHMENT);

	if (trx.isVerbose()) {
		// Force a synchronous export because the object will be deleted before we can export it!
		trx.addRelatedObject(attachment, true);
		trx.setExportRelatedObjects(true);
		trx.exportRelated();
	}

	trx.addState("subjectSkillModMap", sortedMods);
	trx.addState("dstSkillModMap", wearableSkillMods);

	attachment->destroyObjectFromWorld(true);
	attachment->destroyObjectFromDatabase(true);

	if (isEquipped()) {
		applySkillModsTo(player);
	}
}

void WearableObjectImplementation::applySkillModsTo(CreatureObject* creature) const {
	if (creature == nullptr) {
		return;
	}

	for (int i = 0; i < wearableSkillMods.size(); ++i) {
		String name = wearableSkillMods.elementAt(i).getKey();
		int value = wearableSkillMods.get(name);

		if (!SkillModManager::instance()->isWearableModDisabled(name))
		{
			creature->addSkillMod(SkillModManager::WEARABLE, name, value, true);
			creature->updateSpeedAndAccelerationMods();
		}
	}

	SkillModManager::instance()->verifyWearableSkillMods(creature);
}

void WearableObjectImplementation::removeSkillModsFrom(CreatureObject* creature) {
	if (creature == nullptr) {
		return;
	}

	for (int i = 0; i < wearableSkillMods.size(); ++i) {
		String name = wearableSkillMods.elementAt(i).getKey();
		int value = wearableSkillMods.get(name);

		if (!SkillModManager::instance()->isWearableModDisabled(name))
		{
			creature->removeSkillMod(SkillModManager::WEARABLE, name, value, true);
			creature->updateSpeedAndAccelerationMods();
		}
	}

	SkillModManager::instance()->verifyWearableSkillMods(creature);
}

bool WearableObjectImplementation::isEquipped() {
	ManagedReference<SceneObject*> parent = getParent().get();
	if (parent != nullptr && parent->isPlayerCreature())
		return true;

	return false;
}

String WearableObjectImplementation::repairAttempt(int repairChance) {
	String message = "@error_message:";
	
	if(repairChance < 10) {
		message += "sys_repair_failed";
		setMaxCondition(getMaxCondition() * 0.50f, true);
		setConditionDamage(0, true);
	
	} else if(repairChance < 25) {
		message += "sys_repair_imperfect";
		setMaxCondition(getMaxCondition() * .80f, true);
		setConditionDamage(0, true);
	
	} else if(repairChance < 50) {
		setMaxCondition(getMaxCondition() * .90f, true);
		setConditionDamage(0, true);
		message += "sys_repair_slight";
	
	} else {
		setMaxCondition(getMaxCondition() * .97f, true);
		setConditionDamage(0, true);
		message += "sys_repair_perfect";
	}
	return message;
}