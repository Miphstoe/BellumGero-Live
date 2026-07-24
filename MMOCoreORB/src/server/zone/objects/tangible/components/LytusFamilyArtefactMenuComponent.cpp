/*
 * LytusFamilyArtefactMenuComponent.cpp
 */

#include "LytusFamilyArtefactMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/creature/buffs/Buff.h"
#include "server/zone/objects/creature/buffs/BuffType.h"
#include "templates/tangible/SkillBuffTemplate.h"

void LytusFamilyArtefactMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	SkillBuffObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	// The item's baked client appearance is GOT FURNITURE, which the client
	// does not propose a default "Use" radial for (unlike GOT ITEM/FOOD/DRINK
	// items). Add it explicitly so selecting it sends selectedID == 20 back
	// to handleObjectMenuSelect below.
	if (sceneObject->isASubChildOf(player))
		menuResponse->addRadialMenuItem(20, 3, "@ui_radial:item_use");
}

int LytusFamilyArtefactMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (!sceneObject->isASubChildOf(player))
		return 0;

	if (selectedID != 20)
		return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);

	if (player->isDead() || player->isIncapacitated())
		return 0;

	if (!sceneObject->isTangibleObject())
		return 0;

	ManagedReference<TangibleObject*> tano = cast<TangibleObject*>(sceneObject);

	Reference<SkillBuffTemplate*> skillBuff = cast<SkillBuffTemplate*>(sceneObject->getObjectTemplate());
	if (skillBuff == nullptr) {
		error("No SkillBuffTemplate for: " + String::valueOf(sceneObject->getServerObjectCRC()));
		return 1;
	}

	// Jedi restriction: uses the project's standard Jedi detection
	// (PlayerObject::isJedi(), backed by jediState) rather than checking a
	// single hardcoded skill box, so it covers all Jedi regardless of rank.
	ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

	if (ghost != nullptr && ghost->isJedi()) {
		player->sendSystemMessage("The Lytus Family Artifact does not respond to Jedi.");
		return 0;
	}

	// buffCRC is computed from buffName rather than reused from an existing
	// base-game buff. This buff intentionally has no buff-bar icon: every
	// icon-eligible buffCRC belongs to a pre-existing base-game buff (see
	// BuffCRC.h), and reusing one also reuses its displayed name/tooltip --
	// none of which say "damage increase" (the closest options are all
	// accuracy/speed/defense trinkets). No icon is less misleading than a
	// wrong one; see the comment on buffCRC in
	// lytus_family_artefact_damage_buff.lua for the full reasoning.
	unsigned int buffCRC = skillBuff->getBuffName().hashCode();
	int duration = skillBuff->getDuration();
	VectorMap<String, float>* modifiers = skillBuff->getModifiers();

	// Stacking is prevented by reusing the buff system's own duplicate-buff
	// check (the same mechanism every other buff-granting item relies on).
	if (player->hasBuff(buffCRC)) {
		player->sendSystemMessage("You are already empowered by the Lytus Family Artifact.");
		return 0;
	}

	ManagedReference<Buff*> buff = new Buff(player, buffCRC, duration, BuffType::OTHER);

	Locker locker(buff);

	// Applies the "private_damage_percent_bonus" skill modifier defined on
	// the item's Lua template (currently 10, for +10%). The multiplier itself
	// is applied in CombatManager::applyDamageModifiers, which also excludes
	// lightsaber weapons from receiving it.
	for (int i = 0; i < modifiers->size(); ++i) {
		String attribute = modifiers->elementAt(i).getKey();
		float value = modifiers->elementAt(i).getValue();
		buff->setSkillModifier(attribute, (int)value);
	}

	player->addBuff(buff);

	player->sendSystemMessage("You feel empowered by the Lytus Family Artifact.");

	// Consume a charge from the item, destroy it if it reaches 0 charges remaining.
	tano->decreaseUseCount();

	return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
}
