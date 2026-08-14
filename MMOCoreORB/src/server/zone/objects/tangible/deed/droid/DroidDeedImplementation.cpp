/*
 * DroidDeedImplementation.cpp
 *
 *  Created on: October 23, 2013
 *      Author: Klivian
 */

#include "server/zone/objects/tangible/deed/droid/DroidDeed.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/manufactureschematic/ManufactureSchematic.h"
#include "server/zone/managers/creature/CreatureTemplateManager.h"
#include "server/zone/managers/creature/CreatureManager.h"
#include "server/zone/managers/creature/PetManager.h"
#include "server/zone/managers/stringid/StringIdManager.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/objects/creature/ai/CreatureTemplate.h"
#include "templates/tangible/DroidDeedTemplate.h"
#include "server/zone/objects/intangible/PetControlDevice.h"
#include "server/zone/objects/creature/ai/DroidObject.h"
#include "templates/customization/CustomizationIdManager.h"
#include "server/zone/objects/scene/variables/CustomizationVariables.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/IngredientSlot.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/ComponentSlot.h"
#include "server/zone/objects/tangible/components/droid/BaseDroidModuleComponent.h"
#include "server/zone/objects/tangible/component/droid/DroidComponent.h"
#include "server/zone/managers/crafting/labratories/DroidMechanics.h"

namespace {
	bool hasCombatDroidOperatorCertification(CreatureObject* player) {
		if (player == nullptr)
			return false;

		return player->hasSkill("crafting_architect_master")
			|| player->hasSkill("crafting_armorsmith_master")
			|| player->hasSkill("crafting_chef_master")
			|| player->hasSkill("crafting_droidengineer_master")
			|| player->hasSkill("crafting_shipwright_master")
			|| player->hasSkill("crafting_tailor_master")
			|| player->hasSkill("crafting_weaponsmith_master")
			|| player->hasSkill("outdoors_bio_engineer_master")
			|| player->hasSkill("outdoors_ranger_master")
			|| player->hasSkill("science_doctor_master")
			|| player->hasSkill("social_dancer_master")
			|| player->hasSkill("social_musician_master")
			|| player->hasSkill("social_imagedesigner_master");
	}

	int getArmorModuleLevel(HashTable<String, ManagedReference<DroidComponent*> >& modules) {
		if (!modules.containsKey("armor_module"))
			return 0;

		ManagedReference<DroidComponent*> armorComponent = modules.get("armor_module");

		if (armorComponent == nullptr || !armorComponent->hasKey("armor_module"))
			return 0;

		return (int)armorComponent->getAttributeValue("armor_module");
	}
}

void DroidDeedImplementation::loadTemplateData(SharedObjectTemplate* templateData) {
	DeedImplementation::loadTemplateData(templateData);

	DroidDeedTemplate* deedData = dynamic_cast<DroidDeedTemplate*>(templateData);

	if (deedData == nullptr)
		return;

	controlDeviceObjectTemplate = deedData->getControlDeviceObjectTemplate();
	mobileTemplate = deedData->getMobileTemplate();
	species = deedData->getSpecies();
}

void DroidDeedImplementation::onCloneObject(SceneObject* objectToClone) {
	DeedImplementation::onCloneObject(objectToClone);

	ManagedReference<DroidDeed*> deed = cast<DroidDeed*>(objectToClone);

	if (deed == nullptr) {
		error("Invalid object type used in DroidDeedImplementation::onCloneObject");
		return;
	}

	//clear old modules
	modules.removeAll();

	// Insert our stacked droid modules into the droid's crafted components container
	String key;
	ManagedReference<DroidComponent*> comp = nullptr;

	auto modulesTable = deed->getModules();

	if (modulesTable != nullptr) {
		HashTableIterator<String, ManagedReference<DroidComponent*> > iterator = modulesTable->iterator();

		while (iterator.hasNext()) {
			iterator.getNextKeyAndValue(key, comp);

			if (comp != nullptr) {
				ManagedReference<DroidComponent*> cloneComponent = cast<DroidComponent*>(ObjectManager::instance()->cloneObject(comp));

				if (cloneComponent == nullptr)
					continue;

				cloneComponent->setParent(nullptr);
				modules.put(key, cloneComponent);
			}
		}
	}
}

void DroidDeedImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* object) {
	DeedImplementation::fillAttributeList(alm, object);

	int armorModuleLevel = getArmorModuleLevel(modules);
	int displayLevel = DroidMechanics::determineLevel(overallQuality, species, combatRating, armorModuleLevel);

	alm->insertAttribute("challenge_level", displayLevel);

	// HAM
	int maxHam = DroidMechanics::determineHam(overallQuality, species);
	alm->insertAttribute("creature_health", maxHam);
	alm->insertAttribute("creature_action", maxHam);
	alm->insertAttribute("creature_mind", maxHam);

    // Check for combat rating and apply attack, to-hit, and damage range attributes
	if (combatRating > 0) {
		float attackSpeed = DroidMechanics::determineSpeed(species,maxHam);
		float chanceHit = DroidMechanics::determineHit(species,maxHam);
		float damageMin = DroidMechanics::determineMinDamage(species,combatRating);
		float damageMax = DroidMechanics::determineMaxDamage(species,combatRating);

		// Unsupported/custom chassis use the same safe fallback applied when
		// the Combat Module initializes the called droid. This prevents the deed
		// from advertising an invalid zero attack speed or zero accuracy.
		if (attackSpeed <= 0.0f)
			attackSpeed = 2.0f;

		if (chanceHit <= 0.0f)
			chanceHit = 0.20f;

		StringBuffer attdisplayValue;
		StringBuffer hitdisplayValue;

		attdisplayValue << Math::getPrecision(attackSpeed, 2);
		hitdisplayValue << Math::getPrecision(chanceHit, 2);

		alm->insertAttribute("creature_attack", attdisplayValue);
		alm->insertAttribute("creature_tohit", hitdisplayValue);
		alm->insertAttribute("creature_damage", String::valueOf(damageMin) + " - " + String::valueOf(damageMax));
	}

	String key;
	ManagedReference<DroidComponent*> comp = nullptr;
	HashTableIterator<String, ManagedReference<DroidComponent*> > iterator = modules.iterator();

	for (int i = 0; i < modules.size(); ++i) {
		iterator.getNextKeyAndValue(key, comp);

		if (comp != nullptr) {
			DataObjectComponentReference* data = comp->getDataObjectComponent();
			BaseDroidModuleComponent* module = nullptr;

			if(data != nullptr && data->get() != nullptr && data->get()->isDroidModuleData() ){
				module = cast<BaseDroidModuleComponent*>(data->get());
			}

			if (module == nullptr) {
				continue;
			}

			String moduleName = module->getModuleName();

			// The finished deed already displays the combat results derived
			// from Combat Module Rating: attack speed, accuracy and damage.
			// Keep the raw rating visible on components/socket banks only.
			if (moduleName == "combat_module")
				continue;

			// Stim Power is determined only after Class A stimpacks are loaded
			// into the generated droid. The deed should preview the dispenser's
			// crafted Capacity and Delivery Speed without showing a false zero.
			if (moduleName == "stimpack_module") {
				if (comp->hasKey("stimpack_capacity"))
					alm->insertAttribute("stimpack_capacity",
						(int)comp->getAttributeValue("stimpack_capacity"));

				if (comp->hasKey("stimpack_speed"))
					alm->insertAttribute("stimpack_speed",
						(int)comp->getAttributeValue("stimpack_speed"));

				continue;
			}

			module->fillAttributeList(alm,object);
		}
	}
}

void DroidDeedImplementation::initializeTransientMembers() {
	DeedImplementation::initializeTransientMembers();
	setLoggingName("DroidDeed");
}

void DroidDeedImplementation::processModule(BaseDroidModuleComponent* module, uint32 crc) {
	if (module == nullptr)
		return;

	if (module->isStackable()) {
		if (modules.containsKey(module->getModuleName())) {
			// add to the stack if stackable.
			ManagedReference<DroidComponent*> comp = modules.get(module->getModuleName());

			if (comp == nullptr)
				return;

			DataObjectComponentReference* data = comp->getDataObjectComponent();

			if (data == nullptr || data->get() == nullptr ||
					!data->get()->isDroidModuleData())
				return;

			BaseDroidModuleComponent* bmodule = cast<BaseDroidModuleComponent*>(data->get());

			if (bmodule != nullptr)
				bmodule->addToStack(module);
		} else {
			ManagedReference<DroidComponent*> dcomp = (this->getZoneServer()->createObject(crc, 1)).castTo<DroidComponent*>();

			if (dcomp == nullptr)
				return;

			dcomp->setParent(nullptr);

			DataObjectComponentReference* data = dcomp->getDataObjectComponent();

			if (data == nullptr || data->get() == nullptr ||
					!data->get()->isDroidModuleData()) {
				dcomp->destroyObjectFromDatabase(true);
				return;
			}

			BaseDroidModuleComponent* bmodule = cast<BaseDroidModuleComponent*>(data->get());

			if (bmodule == nullptr) {
				dcomp->destroyObjectFromDatabase(true);
				return;
			}

			bmodule->copy(module);
			bmodule->setSpecies(species);
			modules.put(module->getModuleName(), dcomp);
		}
	} else {
		ManagedReference<DroidComponent*> dcomp = (this->getZoneServer()->createObject(crc, 1)).castTo<DroidComponent*>();

		if (dcomp == nullptr)
			return;

		dcomp->setParent(nullptr);

		DataObjectComponentReference* data = dcomp->getDataObjectComponent();

		if (data == nullptr || data->get() == nullptr ||
				!data->get()->isDroidModuleData()) {
			dcomp->destroyObjectFromDatabase(true);
			return;
		}

		BaseDroidModuleComponent* bmodule = cast<BaseDroidModuleComponent*>(data->get());

		if (bmodule == nullptr) {
			dcomp->destroyObjectFromDatabase(true);
			return;
		}

		bmodule->copy(module);
		bmodule->setSpecies(species);
		modules.put(module->getModuleName(), dcomp);
	}
}

void DroidDeedImplementation::destroyObjectFromDatabase(bool destroyContainedObjects) {
	HashTableIterator<String, ManagedReference<DroidComponent*> > iterator = modules.iterator();
	while(iterator.hasNext()) {
		ManagedReference<DroidComponent*> comp = iterator.getNextValue();
		if (comp != nullptr)
			comp->destroyObjectFromDatabase(true);
	}

	modules.removeAll();

	DeedImplementation::destroyObjectFromDatabase(destroyContainedObjects);
}

void DroidDeedImplementation::updateCraftingValues(CraftingValues* values, bool firstUpdate) {
	/*
	 * Values available:	Range:
	 *
	 */
	String key;
	ManagedReference<DroidComponent*> comp = nullptr;
	HashTableIterator<String, ManagedReference<DroidComponent*> > iterator = modules.iterator();
	for(int i = 0; i < modules.size(); ++i) {
		iterator.getNextKeyAndValue(key, comp);
		if (comp) {
			comp->destroyObjectFromWorld(true);
			comp->destroyObjectFromDatabase(true);
		}
	}
	modules.removeAll();

	ManagedReference<ManufactureSchematic*> manufact = values->getManufactureSchematic();

	// Find the separately crafted chassis before calculating final quality.
	// The generic crafting system linearly adds the chassis power_level to
	// the deed's power_level value, so remove that raw addition first and
	// replace it with the intentionally bounded chassis contribution below.
	float chassisPowerLevel = -1.0f;

	if (manufact != nullptr) {
		for (int i = 0; i < manufact->getSlotCount(); ++i) {
			Reference<IngredientSlot*> chassisSlot = manufact->getSlot(i);

			if (chassisSlot == nullptr || !chassisSlot->isComponentSlot())
				continue;

			ComponentSlot* componentSlot = cast<ComponentSlot*>(chassisSlot.get());

			if (componentSlot == nullptr)
				continue;

			ManagedReference<DroidComponent*> component = cast<DroidComponent*>(componentSlot->getPrototype());

			if (component == nullptr || !component->hasKey("power_level"))
				continue;

			if (!component->getObjectTemplate()->getFullTemplateString().contains("droid_chassis"))
				continue;

			chassisPowerLevel = component->getAttributeValue("power_level");
			break;
		}
	}

	// The basic and advanced schematics use actual power-level ranges of
	// 0-50 and 50-100. Store the deed's real value as normalized 0.0-1.0.
	float finalPowerLevel = values->getCurrentValue("power_level");

	if (chassisPowerLevel >= 0.0f)
		finalPowerLevel -= chassisPowerLevel;

	overallQuality = finalPowerLevel / 100.0f;

	if (chassisPowerLevel >= 0.0f) {
		float chassisRatio = chassisPowerLevel / 50.0f;

		if (chassisRatio < 0.0f)
			chassisRatio = 0.0f;

		if (chassisRatio > 1.0f)
			chassisRatio = 1.0f;

		// Chassis 0 = -5 quality points, 25 = neutral, 50 = +5.
		overallQuality += (chassisRatio - 0.5f) * 0.10f;
	}

	if (overallQuality < 0.0f)
		overallQuality = 0.0f;

	if (overallQuality > 1.0f)
		overallQuality = 1.0f;

	combatRating = values->getCurrentValue("cmbt_module");
	if (combatRating < 0)
		combatRating = 0;

	if (combatRating > 600)
		combatRating = 600;

	// @TODO Add crafting values, this should adjust toHit and Speed based on droid ham, also
	// we need to stack modules if they are stackable.
	// walk all components and ensure we have all modules that are stackable there.

	if (manufact == nullptr)
		return;

	for (int i = 0; i < manufact->getSlotCount(); ++i) {
		// Droid Component Slots
		Reference<IngredientSlot*> iSlot = manufact->getSlot(i);

		if (iSlot == nullptr || !iSlot->isComponentSlot())
			continue;

		ComponentSlot* componentSlot = cast<ComponentSlot*>(iSlot.get());

		if (componentSlot == nullptr)
			continue;

		ManagedReference<DroidComponent*> component = cast<DroidComponent*>(componentSlot->getPrototype());

		if (component == nullptr)
			continue;

		// only check modules
		if (component->isSocketCluster()) {
			// pull out the objects
			ManagedReference<SceneObject*> craftingComponents = component->getSlottedObject("crafted_components");

			if (craftingComponents == nullptr ||
					craftingComponents->getContainerObjectsSize() == 0)
				continue;

			ManagedReference<SceneObject*> satchel = craftingComponents->getContainerObject(0);

			if (satchel == nullptr)
				continue;

			for (int j = 0; j < satchel->getContainerObjectsSize(); ++j) {
				ManagedReference<SceneObject*> sceno = satchel->getContainerObject(j);

				if (sceno != nullptr) {
					// now we have the component used in this socket item
					ManagedReference<DroidComponent*> sub = cast<DroidComponent*>( sceno.get());

					if (sub != nullptr) {
						DataObjectComponentReference* data = sub->getDataObjectComponent();
						BaseDroidModuleComponent* module = nullptr;

						if (data != nullptr && data->get() != nullptr && data->get()->isDroidModuleData()){
							module = cast<BaseDroidModuleComponent*>(data->get());
						}

						if (module == nullptr) {
							continue;
						}

						processModule(module, sceno->getServerObjectCRC());
					}
				}
			}
		} else {
			DataObjectComponentReference* data = component->getDataObjectComponent();
			BaseDroidModuleComponent* module = nullptr;

			if (data != nullptr && data->get() != nullptr && data->get()->isDroidModuleData() ){
				module = cast<BaseDroidModuleComponent*>(data->get());
			}

			if (module == nullptr) {
				continue;
			}

			processModule(module, component->getServerObjectCRC());
		}

	}

	// Module stacking is complete. Calculate and persist the finished droid's
	// challenge level from its actual HAM, DPS, accuracy, armor and resistance.
	int armorModuleLevel = getArmorModuleLevel(modules);
	level = DroidMechanics::determineLevel(overallQuality, species, combatRating, armorModuleLevel);
}

void DroidDeedImplementation::fillObjectMenuResponse(ObjectMenuResponse* menuResponse, CreatureObject* player) {
	DeedImplementation::fillObjectMenuResponse(menuResponse, player);

	if (!isASubChildOf(player)) {
		return;
	}

	menuResponse->addRadialMenuItem(RadialOptions::ITEM_USE, 3, "@pet/pet_menu:menu_unpack"); //"Ready Droid Unit"
}

int DroidDeedImplementation::handleObjectMenuSelect(CreatureObject* player, byte selectedID) {
	if (player == nullptr) {
		return 1;
	}

	if (selectedID == RadialOptions::ITEM_USE) {
		if (generated || !isASubChildOf(player)) {
			return 1;
		}

		bool combatDroid =
			modules.containsKey("combat_module") ||
			species == DroidObject::PROBOT ||
			species == DroidObject::DZ70;

		// A droid carrying both Combat and Detonation Modules is still a combat
		// droid for certification, active-slot and call-restriction purposes.
		// Only a pure bomb droid receives the normal bomb-droid exemptions.
		bool bombDroid = isBombDroid() && !combatDroid;
		bool requiresCombatDroidCertification = combatDroid;

		if (requiresCombatDroidCertification &&
				!hasCombatDroidOperatorCertification(player)) {
			player->sendSystemMessage(
				"You must master an eligible elite non-combat profession "
				"to operate a combat droid."
			);

			return 1;
		}

		if (player->isDead()) {
			player->sendSystemMessage("@pet/pet_menu:cant_call"); // "You cannot call this pet right now."
			return 1;
		}

		if ((!bombDroid && player->isIncapacitated()) || (bombDroid && player->isIncapacitated() && !player->isFeigningDeath())) {
			player->sendSystemMessage("@pet/pet_menu:cant_call"); // "You cannot call this pet right now."
			return 1;
		}

		if (!bombDroid && (player->isInCombat() || player->isRidingMount() || player->isSwimming())) {
			player->sendSystemMessage("@pet/pet_menu:cant_call"); // "You cannot call this pet right now."
			return 1;
		}

		auto zoneServer = player->getZoneServer();

		if (zoneServer == nullptr) {
			return 1;
		}

		ManagedReference<SceneObject*> datapad = player->getDatapad();

		if (datapad == nullptr) {
			player->sendSystemMessage("Datapad doesn't exist when trying to generate droid");
			return 1;
		}

		// Check if this will exceed maximum number of droids allowed
		ManagedReference<PlayerManager*> playerManager = player->getZoneServer()->getPlayerManager();

		int droidsInDatapad = 0;
		int maxStoredDroids = playerManager->getBaseStoredDroids();

		for (int i = 0; i < datapad->getContainerObjectsSize(); i++) {
			Reference<SceneObject*> obj =  datapad->getContainerObject(i).castTo<SceneObject*>();

			if (obj != nullptr && obj->isPetControlDevice()) {
				Reference<PetControlDevice*> petDevice = cast<PetControlDevice*>(obj.get());
				if (petDevice != nullptr && petDevice->getPetType() == PetManager::DROIDPET) {
					droidsInDatapad++;
				}
			}
		}

		if (droidsInDatapad >= maxStoredDroids) {
			player->sendSystemMessage("You have too many droids in your datapad");
			return 1;
		}

		Reference<CreatureManager*> creatureManager = player->getZone()->getCreatureManager();

		if (creatureManager == nullptr) {
			return 1;
		}

		CreatureTemplateManager* creatureTemplateManager = CreatureTemplateManager::instance();
		Reference<CreatureTemplate*> creatureTemplate =  creatureTemplateManager->getTemplate(mobileTemplate.hashCode());

		if (creatureTemplate == nullptr) {
			warning() << "Improper droid template: " << mobileTemplate;
			return 1;
		}

		Reference<PetControlDevice*> controlDevice = (server->getZoneServer()->createObject(controlDeviceObjectTemplate.hashCode(), 1)).castTo<PetControlDevice*>();

		if (controlDevice == nullptr) {
			warning() << "Improper droid control device template " << controlDeviceObjectTemplate;
			return 1;
		}

		Locker locker(controlDevice, player);

		Reference<CreatureObject*> creatureObject = creatureManager->createCreature(generatedObjectTemplate.hashCode(), true, mobileTemplate.hashCode());

		if (creatureObject == nullptr) {
			controlDevice->destroyObjectFromDatabase(true);

			warning() << "Improper droid templates -- mobileTemplate: " << mobileTemplate << " generatedObjectTemplate: " << generatedObjectTemplate;
			return 1;
		}

		Locker clocker(creatureObject, player);

		Reference<DroidObject*> droid = creatureObject.castTo<DroidObject*>();

		if (droid == nullptr) {
			controlDevice->destroyObjectFromDatabase(true);
			creatureObject->destroyObjectFromDatabase(true);
			return 1;
		}

		droid->loadTemplateData(creatureTemplate);
		droid->setCustomObjectName(StringIdManager::instance()->getStringId(*droid->getObjectName()), true);
		droid->createChildObjects();
		droid->setControlDevice(controlDevice);

		int armorModuleLevel = getArmorModuleLevel(modules);
		int droidLevel = DroidMechanics::determineLevel(overallQuality, species, combatRating, armorModuleLevel);
		droid->setLevel(droidLevel);

		int maxHam = (int)round(DroidMechanics::determineHam(overallQuality, species));
		droid->setMaximumHAM(maxHam);

		for (int i = 0; i < 9; ++i) {
			if (i % 3 == 0) {
				droid->setBaseHAM(i, maxHam, false);
				droid->setHAM(i, maxHam, false);
				droid->setMaxHAM(i, maxHam, false);
			} else {
				droid->setBaseHAM(i, maxHam / 10, false);
				droid->setHAM(i, maxHam / 10, false);
				droid->setMaxHAM(i, maxHam / 10, false);
			}
		}

		// this will change to use stacked modules. we wont care about non droid modules as they aren't needed.
		ManagedReference<SceneObject*> craftingComponentsSatchel = droid->getCraftedComponentsSatchel();

		String key;
		ManagedReference<DroidComponent*> comp = nullptr;
		HashTableIterator<String, ManagedReference<DroidComponent*> > iterator = modules.iterator();

		for (int i = 0; i < modules.size(); ++i) {
			iterator.getNextKeyAndValue(key, comp);

			if (comp == nullptr) {
				continue;
			}

			if (!craftingComponentsSatchel->transferObject(comp, -1, false)) {
				error("Error transferring droid module from Deed to Object");
			}

			DataObjectComponentReference* componentData = comp->getDataObjectComponent();

			if (componentData == nullptr || componentData->get() == nullptr ||
					!componentData->get()->isDroidModuleData())
				continue;

			BaseDroidModuleComponent* data = cast<BaseDroidModuleComponent*>(componentData->get());

			if (data != nullptr) {
				data->initialize(droid);
			}
		}

		modules.removeAll();

		// Create our transient modules based on the stored physical components
		droid->initDroidModules();
		droid->initDroidWeapons();

		// Copy color customization from deed to droid
		CustomizationVariables* customVars = getCustomizationVariables();

		if (customVars != nullptr) {
			for (int i = 0; i < customVars->size(); ++i) {
				uint8 id = customVars->elementAt(i).getKey();
				int16 val = customVars->elementAt(i).getValue();

				String name = CustomizationIdManager::instance()->getCustomizationVariable(id);

				if (name != "/private/index_color_0" && name.contains("color")) {
					droid->setCustomizationVariable(name, val, true);
				}
			}

			droid->refreshPaint();
		}

		StringId s;
		s.setStringId(droid->getObjectName()->getFullPath());
		controlDevice->setObjectName(s, false);
		controlDevice->setPetType(PetManager::DROIDPET);
		controlDevice->setMaxVitality(100);
		controlDevice->setVitality(100);
		controlDevice->setControlledObject(droid);
		controlDevice->setDefaultCommands();

		if (!datapad->transferObject(controlDevice, -1)) {
			controlDevice->destroyObjectFromDatabase(true);
			return 1;
		}

		datapad->broadcastObject(controlDevice, true);

		controlDevice->callObject(player, true);

		//Remove the deed from its container.
		ManagedReference<SceneObject*> deedContainer = getParent().get();

		if (deedContainer != nullptr) {
			destroyObjectFromWorld(true);
		}

		generated = true;
		destroyObjectFromDatabase(true);

		player->sendSystemMessage("@pet/pet_menu:device_added"); // "A control device has been added to your datapad."
		return 0;
	}

	return DeedImplementation::handleObjectMenuSelect(player, selectedID);
}

bool DroidDeedImplementation::isBombDroid() {
	ManagedReference<DroidComponent*> droidComponent = nullptr;
	HashTableIterator<String, ManagedReference<DroidComponent*> > iterator = modules.iterator();

	for (int i = 0; i < modules.size(); ++i) {
		droidComponent = iterator.getNextValue();

		if (droidComponent == nullptr) {
			continue;
		}

		DataObjectComponentReference* componentData = droidComponent->getDataObjectComponent();

		if (componentData == nullptr || componentData->get() == nullptr ||
				!componentData->get()->isDroidModuleData())
			continue;

		BaseDroidModuleComponent* data = cast<BaseDroidModuleComponent*>(componentData->get());

		if (data == nullptr || !data->isDetonationModule()) {
			continue;
		}

		return true;
	}

	return false;
}
