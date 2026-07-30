/*
 * BioCreatureLabratory.cpp
 *
 * Dedicated final-conditioning laboratory for Bio-Engineer creature deeds.
 */

#include "BioCreatureLabratory.h"
#include "server/zone/managers/crafting/CraftingManager.h"
#include "server/zone/objects/draftschematic/DraftSchematic.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/ComponentSlot.h"
#include "server/zone/objects/tangible/component/genetic/GeneticComponent.h"

BioCreatureLabratory::BioCreatureLabratory() {
	setLoggingName("BioCreatureLabratory");
}

BioCreatureLabratory::~BioCreatureLabratory() {
}

void BioCreatureLabratory::setInitialCraftingValues(TangibleObject* prototype, ManufactureSchematic* manufactureSchematic, int assemblySuccess) {
	if (prototype == nullptr || manufactureSchematic == nullptr || manufactureSchematic->getDraftSchematic() == nullptr)
		return;

	ManagedReference<DraftSchematic*> draftSchematic = manufactureSchematic->getDraftSchematic();
	CraftingValues* craftingValues = manufactureSchematic->getCraftingValues();

	if (craftingValues == nullptr)
		return;

	// Locate the Genetic Template used by the creature schematic. The final
	// conditioning ranges are built from its real baseline values, allowing the
	// client to display meaningful final stat numbers instead of abstract bonus
	// percentages.
	ManagedReference<GeneticComponent*> geneticTemplate = nullptr;

	for (int i = 0; i < manufactureSchematic->getSlotCount(); ++i) {
		Reference<IngredientSlot*> ingredientSlot = manufactureSchematic->getSlot(i);

		if (ingredientSlot == nullptr || !ingredientSlot->isComponentSlot())
			continue;

		ComponentSlot* componentSlot = cast<ComponentSlot*>(ingredientSlot.get());

		if (componentSlot == nullptr)
			continue;

		ManagedReference<TangibleObject*> componentObject = componentSlot->getPrototype();

		if (componentObject == nullptr || componentObject->getGameObjectType() != SceneObjectType::GENETICCOMPONENT)
			continue;

		geneticTemplate = cast<GeneticComponent*>(componentObject.get());
		break;
	}

	if (geneticTemplate == nullptr)
		return;

	// Standard hidden crafting values used by the rest of the crafting system.
	float value = float(draftSchematic->getXpAmount());
	craftingValues->addExperimentalAttribute("xp", "", value, value, 0, true, AttributesMap::OVERRIDECOMBINE);

	value = manufactureSchematic->getComplexity();
	craftingValues->addExperimentalAttribute("complexity", "", value, value, 0, true, AttributesMap::OVERRIDECOMBINE);

	// Creature Food and Flora Food are the only resource slots in these
	// schematics. The Genetic Template component is ignored by getWeightedValue,
	// so these scores are driven entirely by the final-conditioning resources.
	float overallQuality = getWeightedValue(manufactureSchematic, CraftingManager::OQ);
	float potentialEnergy = getWeightedValue(manufactureSchematic, CraftingManager::PE);

	// Vitality leans toward Overall Quality, while Combat Conditioning leans
	// toward Potential Energy. Both remain dependent on both resource stats.
	float vitalityQuality = (overallQuality * 0.65f) + (potentialEnergy * 0.35f);
	float combatQuality = (overallQuality * 0.35f) + (potentialEnergy * 0.65f);

	vitalityQuality = Math::max(0.f, Math::min(vitalityQuality, 1000.f));
	combatQuality = Math::max(0.f, Math::min(combatQuality, 1000.f));

	float averageHam = (geneticTemplate->getHealth() + geneticTemplate->getAction() + geneticTemplate->getMind()) / 3.f;
	float minimumDamage = geneticTemplate->getMinDamage();
	float maximumDamage = Math::min((float)geneticTemplate->getMaxDamage(), 1000.f);
	float accuracy = geneticTemplate->getHit();

	if (minimumDamage > maximumDamage)
		minimumDamage = maximumDamage;

	// Existing client crafting strings are deliberately reused:
	//   exp_hitpointsmax -> Experimental Hitpoints
	//   expdamage        -> Experimental Damage
	//   hp, mindamage, maxdamage and accuracy display the actual final values.
	// The top of each range is exactly 5% above the Genetic Template baseline.
	craftingValues->addExperimentalAttribute("hp", "exp_hitpointsmax", averageHam, averageHam * 1.05f, 0, false, AttributesMap::OVERRIDECOMBINE);
	craftingValues->addExperimentalAttribute("mindamage", "expdamage", minimumDamage, minimumDamage * 1.05f, 0, false, AttributesMap::OVERRIDECOMBINE);
	craftingValues->addExperimentalAttribute("maxdamage", "expdamage", maximumDamage, Math::min(maximumDamage * 1.05f, 1000.f), 0, false, AttributesMap::OVERRIDECOMBINE);
	craftingValues->addExperimentalAttribute("accuracy", "expdamage", accuracy, accuracy * 1.05f, 2, false, AttributesMap::OVERRIDECOMBINE);

	float assemblyModifier = calculateAssemblyValueModifier(assemblySuccess);

	float vitalityMaxPercentage = vitalityQuality / 1000.f;
	float vitalityCurrentPercentage = getAssemblyPercentage(vitalityQuality) * assemblyModifier;
	vitalityCurrentPercentage = Math::max(0.f, Math::min(vitalityCurrentPercentage, vitalityMaxPercentage));
	craftingValues->setCurrentPercentage("hp", vitalityCurrentPercentage, vitalityMaxPercentage);

	float combatMaxPercentage = combatQuality / 1000.f;
	float combatCurrentPercentage = getAssemblyPercentage(combatQuality) * assemblyModifier;
	combatCurrentPercentage = Math::max(0.f, Math::min(combatCurrentPercentage, combatMaxPercentage));
	craftingValues->setCurrentPercentage("mindamage", combatCurrentPercentage, combatMaxPercentage);
	craftingValues->setCurrentPercentage("maxdamage", combatCurrentPercentage, combatMaxPercentage);
	craftingValues->setCurrentPercentage("accuracy", combatCurrentPercentage, combatMaxPercentage);

	craftingValues->recalculateValues(true);

	if (draftSchematic->getIsMagic()) {
		prototype->setIsCraftedEnhancedItem(true);
		prototype->addMagicBit(false);
	}
}
