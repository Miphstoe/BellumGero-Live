/*
 * ResourceLabratory.cpp
 *
 *  Created on: Aug 6, 2013
 *      Author: swgemu
 */

#include "ResourceLabratory.h"
#include "server/zone/objects/draftschematic/DraftSchematic.h"
#include "server/zone/objects/tangible/component/Component.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/ComponentSlot.h"

#include <vector>

//#define DEBUG_RESOURCE_LAB

// Bellum Gero: weighted mixed full-suit armor segment aggregation
namespace {
	struct BellumComponentAggregate {
		String attribute;
		float total;
		int weight;
		int precision;
		String group;
		bool hidden;

		BellumComponentAggregate() : total(0), weight(0), precision(0), hidden(false) {
		}
	};

	bool isBellumSuitPackage(TangibleObject* prototype) {
		if (prototype == nullptr || prototype->getObjectTemplate() == nullptr)
			return false;
		return prototype->getObjectTemplate()->getFullTemplateString().endsWith("_suit_package.iff");
	}

	bool isBellumSuitArmorSegmentSlot(TangibleObject* prototype, ComponentSlot* compSlot, DraftSlot* draftSlot) {
		if (!isBellumSuitPackage(prototype) || compSlot == nullptr || draftSlot == nullptr)
			return false;
		if (compSlot->requiresIdentical() || draftSlot->getSlotType() != IngredientSlot::MIXEDSLOT)
			return false;
		return draftSlot->getResourceType().contains("object/tangible/component/armor/shared_armor_segment");
	}

	int findBellumAggregate(std::vector<BellumComponentAggregate>& aggregates, const String& attribute) {
		for (int i = 0; i < aggregates.size(); ++i) {
			if (aggregates[i].attribute == attribute)
				return i;
		}
		return -1;
	}

	bool applyBellumAveragedComponentProperty(CraftingValues* values, DraftSlot* draftSlot,
			const BellumComponentAggregate& aggregate) {
		if (values == nullptr || draftSlot == nullptr || aggregate.weight <= 0)
			return false;

		const String& attribute = aggregate.attribute;
		float propertyvalue = (aggregate.total / aggregate.weight) * draftSlot->getContribution();

		if (values->hasExperimentalAttribute(attribute)) {
			float max = values->getMaxValue(attribute);
			float min = values->getMinValue(attribute);
			float currentvalue = values->getCurrentValue(attribute);
			short combineType = values->getCombineType(attribute);

			switch (combineType) {
			case AttributesMap::LINEARCOMBINE:
				currentvalue += propertyvalue;
				min += propertyvalue;
				max += propertyvalue;
				values->setMinValue(attribute, min);
				values->setMaxValue(attribute, max);
				values->setCurrentValue(attribute, currentvalue);
				return true;
			case AttributesMap::PERCENTAGECOMBINE:
				currentvalue += propertyvalue;
				min += propertyvalue;
				max += propertyvalue;
				values->setMinValue(attribute, min);
				values->setMaxValue(attribute, max);
				values->setCurrentPercentage(attribute, currentvalue);
				return true;
			case AttributesMap::BITSETCOMBINE:
				currentvalue = (int)currentvalue | (int)propertyvalue;
				values->setCurrentValue(attribute, currentvalue);
				return true;
			case AttributesMap::OVERRIDECOMBINE:
				return false;
			case AttributesMap::LIMITEDCOMBINE:
				currentvalue += propertyvalue;
				if (currentvalue < min)
					currentvalue = min;
				if (currentvalue > max)
					currentvalue = max;
				values->setCurrentValue(attribute, currentvalue);
				return false;
			default:
				return false;
			}
		}

		values->addExperimentalAttribute(attribute, aggregate.group, propertyvalue, propertyvalue,
			aggregate.precision, aggregate.hidden, AttributesMap::LINEARCOMBINE);
		values->setCurrentPercentage(attribute, 0);
		values->setMaxPercentage(attribute, 0);
		values->setCurrentValue(attribute, propertyvalue);
		return true;
	}

	bool applyBellumAveragedArmorSegmentStats(CraftingValues* values, DraftSlot* draftSlot,
			ComponentSlot* compSlot) {
		if (values == nullptr || draftSlot == nullptr || compSlot == nullptr)
			return false;

		std::vector<BellumComponentAggregate> aggregates;

		for (int i = 0; i < compSlot->getContentCount(); ++i) {
			TangibleObject* tano = compSlot->getContentAt(i);
			if (tano == nullptr || !tano->isComponent())
				continue;

			Component* component = cast<Component*>(tano);
			if (component == nullptr)
				continue;

			int useWeight = tano->getUseCount();
			if (useWeight < 1)
				useWeight = 1;

			for (int j = 0; j < component->getPropertyCount(); ++j) {
				String attribute = component->getProperty(j);
				if (attribute.isEmpty() || attribute == "null" || attribute == "useCount")
					continue;

				int idx = findBellumAggregate(aggregates, attribute);
				if (idx < 0) {
					BellumComponentAggregate aggregate;
					aggregate.attribute = attribute;
					aggregate.precision = component->getAttributePrecision(attribute);
					aggregate.group = component->getAttributeGroup(attribute);
					aggregate.hidden = component->getAttributeHidden(attribute);
					aggregates.push_back(aggregate);
					idx = aggregates.size() - 1;
				}

				BellumComponentAggregate& aggregate = aggregates[idx];
				aggregate.total += component->getAttributeValue(attribute) * useWeight;
				aggregate.weight += useWeight;
			}
		}

		bool modified = false;
		for (int i = 0; i < aggregates.size(); ++i) {
			if (applyBellumAveragedComponentProperty(values, draftSlot, aggregates[i]))
				modified = true;
		}
		return modified;
	}

	bool shouldStripBellumBaseSegmentSpecial(TangibleObject* prototype, CraftingValues* values) {
		if (prototype == nullptr || values == nullptr || prototype->getObjectTemplate() == nullptr)
			return false;
		if (!values->hasSlotFilled("segment_enhancement"))
			return false;

		String templatePath = prototype->getObjectTemplate()->getFullTemplateString();
		if (!templatePath.contains("object/tangible/component/armor/armor_segment"))
			return false;

		// Interwoven variants intentionally carry their own Special Protection.
		if (templatePath.endsWith("_acklay.iff"))
			return false;
		return true;
	}

	void stripBellumBaseSegmentSpecial(CraftingValues* values) {
		if (values == nullptr)
			return;

		const char* attributes[] = {
			"armor_special_type",
			"armor_special_effectiveness",
			"armor_special_integrity"
		};

		for (int i = 0; i < 3; ++i) {
			String attribute = attributes[i];
			if (!values->hasExperimentalAttribute(attribute))
				continue;
			values->setMinValue(attribute, 0);
			values->setMaxValue(attribute, 0);
			values->setCurrentValue(attribute, 0);
			values->setCurrentPercentage(attribute, 0);
			values->setMaxPercentage(attribute, 0);
		}
	}
}

ResourceLabratory::ResourceLabratory() {
	setLoggingName("ResourceLabratory");
}

ResourceLabratory::~ResourceLabratory() {
}

void ResourceLabratory::initialize(ZoneServer* server) {
	SharedLabratory::initialize(server);
	Reference<Lua* > lua = new Lua();
	lua->init();
	if (!lua->runFile("scripts/managers/crafting/bio_skill_mods.lua")) {
		return;
	}
	LuaObject bioModsTable = lua->getGlobalObject("bioSkillMods");
	if (!bioModsTable.isValidTable())
		return;
	for (int i = 1; i <= bioModsTable.getTableSize(); ++i) {
		String mod = bioModsTable.getStringAt(i);
		bioMods.put(mod);
	}
	bioModsTable.pop();

}
void ResourceLabratory::setInitialCraftingValues(TangibleObject* prototype, ManufactureSchematic* manufactureSchematic, int assemblySuccess) {
#ifdef DEBUG_RESOURCE_LAB
	info(true) << "---------- ResourceLabratory::setInitialCraftingValues --------";
#endif // DEBUG_RESOURCE_LAB

	if (manufactureSchematic == nullptr || manufactureSchematic->getDraftSchematic() == nullptr)
		return;

	ManagedReference<DraftSchematic* > draftSchematic = manufactureSchematic->getDraftSchematic();
	CraftingValues* craftingValues = manufactureSchematic->getCraftingValues();

	float value, maxPercentage, currentPercentage, weightedSum;

	// These 2 values are pretty standard, adding these
	value = float(draftSchematic->getXpAmount());
	craftingValues->addExperimentalAttribute("xp", "", value, value, 0, true, AttributesMap::OVERRIDECOMBINE);

	value = manufactureSchematic->getComplexity();
	craftingValues->addExperimentalAttribute("complexity", "", value, value, 0, true, AttributesMap::OVERRIDECOMBINE);

	float modifier = calculateAssemblyValueModifier(assemblySuccess);

	for (int i = 0; i < draftSchematic->getResourceWeightCount(); ++i) {
		// Grab the first weight group
		Reference<ResourceWeight* > resourceWeight = draftSchematic->getResourceWeight(i);

		// Getting the title ex: expDamage
		String group = resourceWeight->getExperimentalTitle();

		// Getting the subtitle ex: minDamage
		String attribute = resourceWeight->getPropertyName();

#ifdef DEBUG_RESOURCE_LAB
		info(true) << "setInitialCraftingValues -- adding attribute " << attribute << " with the group " << group;
#endif // DEBUG_RESOURCE_LAB
		weightedSum = 0;
		craftingValues->addExperimentalAttribute(attribute, group, resourceWeight->getMinValue(), resourceWeight->getMaxValue(), resourceWeight->getPrecision(), resourceWeight->isFiller(), resourceWeight->getCombineType());

		for (int j = 0; j < resourceWeight->getPropertyListSize(); ++j) {
			// Based on the script we cycle through each exp group
			// Get the type from the type/weight
			int type = (resourceWeight->getTypeAndWeight(j) >> 4);

			// Get the calculation percentage
			float percentage = resourceWeight->getPropertyPercentage(j);

			// add to the weighted sum based on type and percentage
			weightedSum += getWeightedValue(manufactureSchematic, type) * percentage;
		}

		// > 0 ensures that we don't add things when there is NaN value
		if (weightedSum > 0) {

			// This is the formula for max experimenting percentages
			maxPercentage = ((weightedSum / 10.0f) * .01f);

			// Based on the weighted sum, we can get the initial %
			currentPercentage = getAssemblyPercentage(weightedSum) * modifier;
			craftingValues->setCurrentPercentage(attribute, currentPercentage, maxPercentage);
		}
	}

	craftingValues->recalculateValues(true);

	if (applyComponentStats(prototype, manufactureSchematic)) {
#ifdef DEBUG_RESOURCE_LAB
		info(true) << "Apply Component Stats is TRUE --  recalculateValues AGAIN";
#endif // DEBUG_RESOURCE_LAB
		craftingValues->recalculateValues(true);
	}

	if(draftSchematic->getIsMagic()) {
		prototype->setIsCraftedEnhancedItem(true);
		prototype->addMagicBit(false);
	}

#ifdef DEBUG_RESOURCE_LAB
	info(true) << "---------- END ResourceLabratory::setInitialCraftingValues --------";
#endif // DEBUG_RESOURCE_LAB
}

void ResourceLabratory::experimentRow(CraftingValues* craftingValues, int rowEffected, int pointsAttempted, float failure, int experimentationResult){
	String experimentedGroup = craftingValues->getVisibleAttributeGroup(rowEffected);

#ifdef DEBUG_RESOURCE_LAB
	info(true) << "---------- ResourceLabratory::experimentRow for Row #" << rowEffected << " with Experimented Group Name " << experimentedGroup << " with a total Experimental attributes " << craftingValues->getTotalExperimentalAttributes() << " using " << pointsAttempted << " points. -----------";
#endif // DEBUG_RESOURCE_LAB

	for (int i = 0; i < craftingValues->getTotalExperimentalAttributes(); ++i) {
		String attribute = craftingValues->getAttribute(i);
		String group = craftingValues->getAttributeGroup(attribute);

#ifdef DEBUG_RESOURCE_LAB
		info(true) << "Checking #" << i << " Attribute: " << attribute << " with Group: " << group;
#endif // DEBUG_RESOURCE_LAB

		if (group != experimentedGroup)
			continue;

		float modifier = calculateExperimentationValueModifier(experimentationResult,pointsAttempted);
		float newValue = craftingValues->getCurrentPercentage(attribute) + modifier;
		float maxPercent = craftingValues->getMaxPercentage(attribute);

		if (newValue > maxPercent) {
			newValue = maxPercent;
		}

		if (newValue < 0)
			newValue = 0;

#ifdef DEBUG_RESOURCE_LAB
		info(true) << "Experimenting on " << attribute << " with a modifier " << modifier << " and new calculated value of " << newValue << " and max percentage of " << maxPercent;
#endif // DEBUG_RESOURCE_LAB
		craftingValues->setCurrentPercentage(attribute, newValue);
	}

#ifdef DEBUG_RESOURCE_LAB
	info(true) << "---------- END ResourceLabratory::experimentRow ----------";
#endif // DEBUG_RESOURCE_LAB
}

int ResourceLabratory::getCreationCount(ManufactureSchematic* manufactureSchematic) {
	return 1;
}

bool ResourceLabratory::applyComponentStats(TangibleObject* prototype, ManufactureSchematic* manufactureSchematic) {
#ifdef DEBUG_RESOURCE_LAB
	info(true) << "----- ResourceLabratory::applyComponentStats called ------";
#endif // DEBUG_RESOURCE_LAB

	if (manufactureSchematic == nullptr || manufactureSchematic->getDraftSchematic() == nullptr)
		return false;

	float max, min, currentvalue, propertyvalue;
	int precision;
	bool modified = false;
	bool hidden;
	String attribute, group;

	CraftingValues* craftingValues = manufactureSchematic->getCraftingValues();
	ManagedReference<DraftSchematic* > draftSchematic = manufactureSchematic->getDraftSchematic();

#ifdef DEBUG_RESOURCE_LAB
	info(true) << "applyComponentStats -- Manufacture schematic Info: " << manufactureSchematic->getObjectNameStringIdName() << " Total Experimental Attributes: " << craftingValues->getTotalExperimentalAttributes();

	for (int i = 0; i < craftingValues->getTotalExperimentalAttributes(); ++i) {
		info(true) << "Schematic Attribute #" << i << " - " << craftingValues->getAttribute(i);
	}
#endif // DEBUG_RESOURCE_LAB

	bool isYellow = false;

	for (int i = 0; i < manufactureSchematic->getSlotCount(); ++i) {
#ifdef DEBUG_RESOURCE_LAB
		info(true) << "applyComponentStats -- Component #" << i;
#endif // DEBUG_RESOURCE_LAB

		Reference<IngredientSlot* > ingredientSlot = manufactureSchematic->getSlot(i);
		Reference<DraftSlot* > draftSlot = draftSchematic->getDraftSlot(i);

		if(ingredientSlot == nullptr || !ingredientSlot->isComponentSlot() || !ingredientSlot->isFull())
			continue;

		ComponentSlot* compSlot = cast<ComponentSlot*>(ingredientSlot.get());

		if(compSlot == nullptr)
			continue;

		ManagedReference<TangibleObject*> tano = compSlot->getPrototype();

		if (tano == nullptr || !tano->isComponent())
			continue;

		ManagedReference<Component*> component = cast<Component*>(tano.get());

		if (isBellumSuitArmorSegmentSlot(prototype, compSlot, draftSlot)) {
			if (applyBellumAveragedArmorSegmentStats(craftingValues, draftSlot, compSlot))
				modified = true;
			continue;
		}

		if (prototype->isWearableObject() && !prototype->isArmorObject()) {
			if (component->getObjectTemplate()->getObjectName() == "@craft_clothing_ingredients_n:reinforced_fiber_panels" || component->getObjectTemplate()->getObjectName() == "@craft_clothing_ingredients_n:synthetic_cloth" || component->getObjectTemplate()->getObjectName() == "@craft_clothing_ingredients_n:jewelry_setting" || component->getObjectTemplate()->getObjectName() == "@craft_clothing_ingredients_n:metal_fasteners" || component->getObjectTemplate()->getObjectName() == "@craft_clothing_ingredients_n:padding_segment" || component->getObjectTemplate()->getObjectName() == "@craft_clothing_ingredients_n:fiberplast_panel"){
				for (int k = 0; k < component->getPropertyCount(); ++k) {
					attribute = component->getProperty(k);

					if (attribute == "" || attribute == "null") {
						continue;
					}

					String key = checkBioSkillMods(attribute);

					if (key == "")
						continue;

					currentvalue = component->getAttributeValue(attribute);
					precision = component->getAttributePrecision(attribute);

					int preciseValue = Math::getPrecision(currentvalue, precision);

					WearableObject* clothing = cast<WearableObject*>(prototype);
					const VectorMap<String, int>* clothingMods = clothing->getWearableSkillMods();

					int existingValue = 0;

					if (clothingMods->contains(key)) {
						existingValue = clothingMods->get(key);
					}

					preciseValue += existingValue;

					if (preciseValue > 25)
						preciseValue = 25;

					clothing->addSkillMod(SkillModManager::WEARABLE, key, preciseValue);
					isYellow = true;
				}
			}
		} else {
			for (int j = 0; j < component->getPropertyCount(); ++j) {
				attribute = component->getProperty(j);
				modified = true;

#ifdef DEBUG_RESOURCE_LAB
				info(true) << "Component Attribute: " << attribute;
#endif // DEBUG_RESOURCE_LAB

				if (craftingValues->hasExperimentalAttribute(attribute)) {
#ifdef DEBUG_RESOURCE_LAB
					info(true) << "Crafting values contains attribute: " << attribute << " updating values and percentages.";
#endif // DEBUG_RESOURCE_LAB

					max = craftingValues->getMaxValue(attribute);
					min = craftingValues->getMinValue(attribute);
					hidden = craftingValues->isHidden(attribute);
					currentvalue = craftingValues->getCurrentValue(attribute);
					propertyvalue = component->getAttributeValue(attribute) * draftSlot->getContribution();
					short combineType = craftingValues->getCombineType(attribute);

					switch(combineType) {
					case AttributesMap::LINEARCOMBINE:
						currentvalue += propertyvalue;
						min += propertyvalue;
						max += propertyvalue;

#ifdef DEBUG_RESOURCE_LAB
						info(true) << "LINEARCOMBINE: Adding propertyvalue = " << propertyvalue << " Set New Atrributes - Value = " << currentvalue << " Min = " << min << " Max = " << max;
#endif // DEBUG_RESOURCE_LAB

						craftingValues->setMinValue(attribute, min);
						craftingValues->setMaxValue(attribute, max);

						craftingValues->setCurrentValue(attribute, currentvalue);
						break;
					case AttributesMap::PERCENTAGECOMBINE:
						currentvalue += propertyvalue;
						min += propertyvalue;
						max += propertyvalue;

#ifdef DEBUG_RESOURCE_LAB
						info(true) << "PERCENTAGECOMBINE: Adding propertyvalue = " << propertyvalue << " Set New Atrributes - Value = " << currentvalue << " Min = " << min << " Max = " << max;
#endif // DEBUG_RESOURCE_LAB

						craftingValues->setMinValue(attribute, min);
						craftingValues->setMaxValue(attribute, max);

						craftingValues->setCurrentPercentage(attribute, currentvalue);
						break;
					case AttributesMap::BITSETCOMBINE:
						currentvalue = (int)currentvalue | (int)propertyvalue;

#ifdef DEBUG_RESOURCE_LAB
						info(true) << "BITSETCOMBINE: Set New Atrributes - Value = " << currentvalue << " Min = " << min << " Max = " << max;
#endif // DEBUG_RESOURCE_LAB

						craftingValues->setCurrentValue(attribute, currentvalue);
						break;
					case AttributesMap::OVERRIDECOMBINE:
						// Do nothing because the values should override whatever is
						// on the component
						break;
					case AttributesMap::LIMITEDCOMBINE:
						currentvalue += propertyvalue;

						if (currentvalue < min)
							currentvalue = min;

						if (currentvalue > max)
							currentvalue = max;

#ifdef DEBUG_RESOURCE_LAB
						info(true) << "LIMITEDCOMBINE: Adding propertyvalue = " << propertyvalue << " Set New Atrributes - Value = " << currentvalue << " Min = " << min << " Max = " << max;
#endif // DEBUG_RESOURCE_LAB

						craftingValues->setCurrentValue(attribute, currentvalue);

						modified = false;
						break;
					default:
						break;
					}

				} else {
#ifdef DEBUG_RESOURCE_LAB
					info(true) << "Crafting values DOES NOT contain attribute: " << attribute << " addingExperimentalAttribute.";
#endif // DEBUG_RESOURCE_LAB
					currentvalue = component->getAttributeValue(attribute);
					precision = component->getAttributePrecision(attribute);
					group = component->getAttributeGroup(attribute);
					hidden = component->getAttributeHidden(attribute);

#ifdef DEBUG_RESOURCE_LAB
					if (hidden)
						info(true) << "Attribute: " << attribute << " is hidden.";
					else
						info(true) << "Attribute: " << attribute << " is NOT hidden.";
#endif // DEBUG_RESOURCE_LAB

					craftingValues->addExperimentalAttribute(attribute, group, currentvalue, currentvalue, precision, hidden, AttributesMap::LINEARCOMBINE);
					craftingValues->setCurrentPercentage(attribute, 0);
					craftingValues->setMaxPercentage(attribute, 0);
					craftingValues->setCurrentValue(attribute, currentvalue);
				}
			}
		}
	}

	if (shouldStripBellumBaseSegmentSpecial(prototype, craftingValues)) {
		stripBellumBaseSegmentSpecial(craftingValues);
		modified = true;
	}

	if(isYellow) {
		prototype->setIsCraftedEnhancedItem(true);
		prototype->addMagicBit(false);
	}

#ifdef DEBUG_RESOURCE_LAB
	info(true) << "----- END ResourceLabratory::applyComponentStats called ------";
#endif

	return modified;
}

String ResourceLabratory::checkBioSkillMods(const String& property) {
	for (int l = 0; l < bioMods.size(); ++l) {

		String key = bioMods.elementAt(l);
		String statname = "cat_skill_mod_bonus.@stat_n:" + key;

		if (property == statname) {
			return key;
		}
	}

	return "";
}
