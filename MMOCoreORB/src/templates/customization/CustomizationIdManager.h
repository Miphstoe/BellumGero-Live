/*
 * CustomizationIdManager.h
 *
 *  Created on: 28/03/2012
 *      Author: victor
 */

#ifndef CUSTOMIZATIONIDMANAGER_H_
#define CUSTOMIZATIONIDMANAGER_H_

#include "engine/log/Logger.h"
#include "engine/util/Singleton.h"
#include "templates/customization/PaletteData.h"
#include "templates/customization/HairAssetData.h"

class CustomizationIdManager : public Object, public Logger, public Singleton<CustomizationIdManager> {
	HashTable<String, int> customizationIds;
	HashTable<int, String> reverseIds;
	HashTable<String, Reference<PaletteData*> > paletteColumns;

	// BG: datatables/customization/hair_assets_skill_mods.iff now legitimately contains MULTIPLE
	// rows for the same hair item's serverTemplate -- bg_species1.tre's custom species reuse many
	// stock hairstyles, adding one row per compatible species that shares that hairstyle. Storing a
	// single HairAssetData per serverTemplate (as originally written) meant loadHairAssetsSkillMods()
	// silently overwrote every row but the last one loaded for ~300 of 554 hairstyles -- whichever
	// species happened to be listed last for that hairstyle "won", and every other species (Human
	// included) got a mismatched HairAssetData whose getServerPlayerTemplate() didn't match the
	// character being created, causing addHair()/createHairObject() to reject the hair and leave the
	// character bald. See getHairAssetData() below.
	HashTable<String, Vector<Reference<HairAssetData*> > > hairAssetSkillMods;

	HashTable<String, bool> allowBald;

public:
	CustomizationIdManager();

	void loadPaletteColumns(IffStream* iffStream);
	void loadHairAssetsSkillMods(IffStream* iffStream);
	void loadAllowBald(IffStream* iffStream);
	void readObject(IffStream* iffStream);

	int getCustomizationId(const String& var) {
		return customizationIds.get(var);
	}

	String getCustomizationVariable(int id) {
		return reverseIds.get(id);
	}

	PaletteData* getPaletteData(const String& palette) {
		return paletteColumns.get(palette);
	}

	// BG: playerTemplate (the target creature's complete/CC template path, e.g.
	// "object/creature/player/human_female.iff") disambiguates between the multiple species that
	// can now share a single hairServerTemplate. Returns nullptr if hairServerTemplate has no row
	// at all, or if it has rows but none of them are valid for playerTemplate specifically.
	HairAssetData* getHairAssetData(const String& hairServerTemplate, const String& playerTemplate) {
		if (!hairAssetSkillMods.containsKey(hairServerTemplate))
			return nullptr;

		Vector<Reference<HairAssetData*> >& candidates = hairAssetSkillMods.get(hairServerTemplate);

		for (int i = 0; i < candidates.size(); ++i) {
			if (candidates.get(i)->getServerPlayerTemplate() == playerTemplate)
				return candidates.get(i);
		}

		return nullptr;
	}

	bool canBeBald(const String& speciesSubString) {
		return allowBald.get(speciesSubString);
	}
};

#endif /* CUSTOMIZATIONIDMANAGER_H_ */
