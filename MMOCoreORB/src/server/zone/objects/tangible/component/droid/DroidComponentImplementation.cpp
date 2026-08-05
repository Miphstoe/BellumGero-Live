/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#include "server/zone/objects/tangible/component/droid/DroidComponent.h"
#include "server/zone/objects/tangible/components/droid/BaseDroidModuleComponent.h"
#include "server/zone/objects/tangible/components/droid/DroidDataStorageModuleDataComponent.h"
#include "server/zone/objects/tangible/components/droid/DroidItemStorageModuleDataComponent.h"
#include "templates/tangible/DroidEffectsModuleTemplate.h"

void DroidComponentImplementation::initializeTransientMembers() {
	ComponentImplementation::initializeTransientMembers();
}

void DroidComponentImplementation::updateCraftingValues(CraftingValues* values, bool firstUpdate) {
	ComponentImplementation::updateCraftingValues(values, firstUpdate);

	quality = values->getCurrentValue("mechanism_quality");
	durability = values->getCurrentValue("decayrate");

	// Setup droid module floats for more precise crafting
	autoRepairPower = values->getCurrentValue("auto_repair_power");
	combatRating = values->getCurrentValue("cmbt_module");
	detonationRating = values->getCurrentValue("bomb_level");
	harvestBonus = values->getCurrentValue("harvest_power");
	stimpackSpeed = values->getCurrentValue("stimpack_speed");
	stimpackCapacity = values->getCurrentValue("stimpack_capacity");
	trapBonus = values->getCurrentValue("trap_bonus");

	if (values->hasExperimentalAttribute("droid_count")) {
		setUseCount(values->getCurrentValue("droid_count"));
		surveyDroid = true;
	} else if (autoRepairPower > 0) {
		autoRepairDroid = true;
	} else if (combatRating > 0) {
		combatDroid = true;
	} else if (detonationRating > 0) {
		detonationDroid = true;
	} else if (harvestBonus > 0) {
		harvestDroid = true;
	} else if (stimpackSpeed > 0) {
		stimpackDroid = true;
	} else if (trapBonus > 0) {
		trapDroid = true;
	}

	DataObjectComponentReference* data = getDataObjectComponent();

	if(data != nullptr && data->get() != nullptr && data->get()->isDroidModuleData() ){
		BaseDroidModuleComponent* module = cast<BaseDroidModuleComponent*>(data->get());
		if( module != nullptr ){
			module->updateCraftingValues( values, firstUpdate );
		}
	}
}
void DroidComponentImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* object) {
	//ComponentImplementation::fillAttributeList(alm, object);

	alm->insertAttribute("volume", 1);
	alm->insertAttribute("crafter", craftersName);
	alm->insertAttribute("serial_number", objectSerial);

	//alm->insertAttribute("decayrate", (int)durability);

	if (quality > AttributesMap::VALUENOTFOUND)
		alm->insertAttribute("mechanism_quality", (int)quality);

	// Chassis Power Level is a functional crafting result used by the
	// finished droid deed. Display it on every chassis/component that has it.
	if (hasKey("power_level")) {
		float powerLevel = getAttributeValue("power_level");

		if (powerLevel > AttributesMap::VALUENOTFOUND)
			alm->insertAttribute("power_level", (int)powerLevel);
	}

	// Droid Storage Compartment Quality contributes to the effectiveness
	// of full-size crafting stations that use this component.
	if (hasKey("usemodifier")) {
		float useModifier = getAttributeValue("usemodifier");

		if (useModifier > AttributesMap::VALUENOTFOUND)
			alm->insertAttribute("usemodifier", (int)useModifier);
	}

	bool socketCluster = isSocketCluster();
	bool standaloneModuleDisplayed = false;

	// Every standalone droid module already owns the authoritative display
	// logic for its functional rating, installed type, or named effect.
	// Calling it here removes the old per-module allowlist and ensures Repair,
	// Effects, Maintenance, Merchant, Personality and future modules are
	// visible before they are installed into a cluster.
	DataObjectComponentReference* moduleData = getDataObjectComponent();

	if (!socketCluster && moduleData != nullptr && moduleData->get() != nullptr &&
			moduleData->get()->isDroidModuleData()) {
		BaseDroidModuleComponent* module =
			cast<BaseDroidModuleComponent*>(moduleData->get());

		if (module != nullptr) {
			String moduleName = module->getModuleName();

			if (moduleName == "stimpack_module") {
				// Stim Power comes from the Class A stimpacks loaded after the
				// droid is generated. During component crafting, display only
				// the functional dispenser Capacity and Delivery Speed.
				alm->insertAttribute("stimpack_capacity", (int)stimpackCapacity);
				alm->insertAttribute("stimpack_speed", (int)stimpackSpeed);
			} else {
				module->fillAttributeList(alm, object);
			}

			standaloneModuleDisplayed = true;
		}
	}

	if (socketCluster) {
		// A socket cluster may contain several numeric module families at the
		// same time. Display every aggregate independently rather than relying
		// on the mutually exclusive primary classification flags.
		if (autoRepairPower > 0)
			alm->insertAttribute("auto_repair_power", (int)autoRepairPower);

		if (combatRating > 0)
			alm->insertAttribute("cmbt_module", (int)combatRating);

		if (detonationRating > 0)
			alm->insertAttribute("bomb_level", (int)detonationRating);

		if (harvestBonus > 0)
			alm->insertAttribute("harvest_power", (int)harvestBonus);

		if (stimpackSpeed > 0 || stimpackCapacity > 0) {
			alm->insertAttribute("stimpack_capacity", (int)stimpackCapacity);
			alm->insertAttribute("stimpack_speed", (int)stimpackSpeed);
		}

		if (trapBonus > 0)
			alm->insertAttribute("trap_bonus", (int)trapBonus);
	} else if (!standaloneModuleDisplayed) {
		// Preserve the original generic display path for non-module droid
		// components that use the common DroidComponent numeric fields.
		if (autoRepairDroid) {
			alm->insertAttribute("auto_repair_power", (int)autoRepairPower);
		} else if (combatDroid) {
			alm->insertAttribute("cmbt_module", (int)combatRating);
		} else if (detonationDroid) {
			alm->insertAttribute("bomb_level", (int)detonationRating);
		} else if (harvestDroid) {
			alm->insertAttribute("harvest_power", (int)harvestBonus);
		} else if (stimpackDroid) {
			alm->insertAttribute("stimpack_capacity", (int)stimpackCapacity);
			alm->insertAttribute("stimpack_speed", (int)stimpackSpeed);
		} else if (surveyDroid) {
			// Survey droid count is represented by the object's use count.
		} else if (trapDroid) {
			alm->insertAttribute("trap_bonus", (int)trapBonus);
		}
	}

	if (!socketCluster)
		return;

	int armorModuleRating = 0;
	int dataStorageCapacity = 0;
	int itemStorageRawRating = 0;
	int medicalModuleRawRating = 0;
	int maintenanceModuleRating = 0;
	int playbackModules = 0;
	int trapModules = 0;
	Vector<String> installedEffects;

	ManagedReference<SceneObject*> satchel = getCraftedComponentsSatchel();

	if (satchel != nullptr) {
		for (int i = 0; i < satchel->getContainerObjectsSize(); ++i) {
			ManagedReference<SceneObject*> sceneObject =
				satchel->getContainerObject(i);
			ManagedReference<DroidComponent*> sub =
				cast<DroidComponent*>(sceneObject.get());

			if (sub == nullptr)
				continue;

			DataObjectComponentReference* data =
				sub->getDataObjectComponent();

			if (data == nullptr || data->get() == nullptr ||
					!data->get()->isDroidModuleData())
				continue;

			BaseDroidModuleComponent* module =
				cast<BaseDroidModuleComponent*>(data->get());

			if (module == nullptr)
				continue;

			String moduleName = module->getModuleName();

			if (moduleName == "armor_module") {
				if (sub->hasKey("armor_module"))
					armorModuleRating +=
						(int)sub->getAttributeValue("armor_module");
			} else if (moduleName == "datapad_storage_module") {
				DroidDataStorageModuleDataComponent* dataStorage =
					cast<DroidDataStorageModuleDataComponent*>(module);

				if (dataStorage != nullptr)
					dataStorageCapacity += dataStorage->getStorageCapacity();
			} else if (moduleName == "item_storage_module") {
				DroidItemStorageModuleDataComponent* itemStorage =
					cast<DroidItemStorageModuleDataComponent*>(module);

				if (itemStorage != nullptr)
					itemStorageRawRating += itemStorage->getRating();
			} else if (moduleName == "medical_module") {
				if (sub->hasKey("medical_module"))
					medicalModuleRawRating +=
						(int)sub->getAttributeValue("medical_module");
			} else if (moduleName == "maintenance_module") {
				// Maintenance modules intentionally keep only the highest
				// rating when the finished deed stacks them.
				if (sub->hasKey("struct_module")) {
					int rating =
						(int)sub->getAttributeValue("struct_module");

					if (rating > maintenanceModuleRating)
						maintenanceModuleRating = rating;
				}
			} else if (moduleName == "playback_module") {
				playbackModules++;
			} else if (moduleName == "trap_module") {
				// Trap Bonus is already aggregated through the cluster's
				// common crafting fields. Count modules separately so the
				// cluster can also preview its eventual trap capacity.
				trapModules++;
			} else if (moduleName == "effects_module") {
				Reference<DroidEffectsModuleTemplate*> effectsTemplate =
					cast<DroidEffectsModuleTemplate*>(
						sub->getObjectTemplate());

				if (effectsTemplate != nullptr) {
					String effectName = effectsTemplate->getEffectName();
					bool alreadyAdded = false;

					for (int j = 0; j < installedEffects.size(); ++j) {
						if (installedEffects.get(j) == effectName) {
							alreadyAdded = true;
							break;
						}
					}

					if (!alreadyAdded)
						installedEffects.add(effectName);
				} else {
					// Retain a safe fallback for any custom Effects Module
					// whose template is not a DroidEffectsModuleTemplate.
					module->fillAttributeList(alm, object);
				}
			} else if (
				moduleName == "auto_repair_module" ||
				moduleName == "combat_module" ||
				moduleName == "detonation_module" ||
				moduleName == "harvest_module" ||
				moduleName == "stimpack_module") {
				// These numeric families were already displayed once from
				// the cluster's aggregated common crafting fields above.
				continue;
			} else {
				// Named/non-numeric modules such as Repair, Merchant Barker,
				// Personality Chips and Crafting Stations already provide
				// the correct installed/type-specific attribute themselves.
				module->fillAttributeList(alm, object);
			}
		}
	}

	if (armorModuleRating > 0) {
		if (armorModuleRating > 6)
			armorModuleRating = 6;

		alm->insertAttribute("armor_module", armorModuleRating);
	}

	if (dataStorageCapacity > 0) {
		if (dataStorageCapacity > 150)
			dataStorageCapacity = 150;

		alm->insertAttribute("data_module", dataStorageCapacity);
	}

	if (itemStorageRawRating > 0) {
		int itemStorageCapacity = 100;

		if (itemStorageRawRating <= 10)
			itemStorageCapacity = 10;
		else if (itemStorageRawRating <= 20)
			itemStorageCapacity = 20;
		else if (itemStorageRawRating <= 40)
			itemStorageCapacity = 40;
		else if (itemStorageRawRating <= 60)
			itemStorageCapacity = 60;
		else if (itemStorageRawRating <= 80)
			itemStorageCapacity = 80;

		alm->insertAttribute("storage_module", itemStorageCapacity);
	}

	if (medicalModuleRawRating > 0) {
		int medicalModuleRating = 110;

		if (medicalModuleRawRating <= 2)
			medicalModuleRating = 55;
		else if (medicalModuleRawRating <= 4)
			medicalModuleRating = 65;
		else if (medicalModuleRawRating <= 6)
			medicalModuleRating = 75;
		else if (medicalModuleRawRating <= 8)
			medicalModuleRating = 85;
		else if (medicalModuleRawRating <= 10)
			medicalModuleRating = 100;

		alm->insertAttribute("medical_module", medicalModuleRating);
	}

	if (maintenanceModuleRating > 0)
		alm->insertAttribute("struct_module", maintenanceModuleRating);

	if (playbackModules > 0)
		alm->insertAttribute("playback_modules", playbackModules);

	if (trapModules > 0) {
		StringBuffer trapCapacity;
		trapCapacity << "0/" << (trapModules * 10);
		alm->insertAttribute("max_trap_load", trapCapacity.toString());
	}

	for (int i = 0; i < installedEffects.size(); ++i) {
		String effectName = installedEffects.get(i);
		int separator = effectName.indexOf(':');

		if (separator >= 0)
			effectName =
				effectName.subString(separator + 1, effectName.length());

		alm->insertAttribute(effectName, "Installed");
	}
}
bool DroidComponentImplementation::isSocketCluster() {
	String objTemplate = getObjectTemplate()->getFullTemplateString();
	return objTemplate.contains("socket_bank");
}
