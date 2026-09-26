/*
 * CustomizationIdManager.cpp
 *
 *  Created on: 29/03/2012
 *      Author: victor
 */

#include "CustomizationIdManager.h"
#include "templates/datatables/DataTableIff.h"

CustomizationIdManager::CustomizationIdManager() {
	setLoggingName("CustomizationIdManager");
}

void CustomizationIdManager::loadHairAssetsSkillMods(IffStream* iffStream) {
	DataTableIff dataTable;
	dataTable.readObject(iffStream);

	int totalRows = 0;

	for (int i = 0; i < dataTable.getTotalRows(); ++i) {
		HairAssetData* data = new HairAssetData();
		data->readObject(dataTable.getRow(i));

		// BG: append rather than overwrite -- see the comment on hairAssetSkillMods in
		// CustomizationIdManager.h for why a single serverTemplate can now have multiple valid rows
		// (one per compatible player species).
		if (!hairAssetSkillMods.containsKey(data->getServerTemplate()))
			hairAssetSkillMods.put(data->getServerTemplate(), Vector<Reference<HairAssetData*> >());

		hairAssetSkillMods.get(data->getServerTemplate()).add(data);
		++totalRows;

		debug() << "adding " << data->getServerTemplate() << " for " << data->getServerPlayerTemplate();
	}

	info() << "loaded " << totalRows << " hair asset rows across " << hairAssetSkillMods.size() << " hair templates";
}

void CustomizationIdManager::loadAllowBald(IffStream* iffStream) {
	DataTableIff dataTable;
	dataTable.readObject(iffStream);

	for (int i = 0; i < dataTable.getTotalRows(); ++i) {
		String species;
		bool val;

		DataTableRow* row = dataTable.getRow(i);

		row->getValue(0, species);
		row->getValue(1, val);

		allowBald.put(species, val);
	}

	info() << "loaded " << allowBald.size() << " allow bald species data";
}

void CustomizationIdManager::loadPaletteColumns(IffStream* iffStream) {
	DataTableIff dataTable;
	dataTable.readObject(iffStream);

	for (int i = 0; i < dataTable.getTotalRows(); ++i) {
		PaletteData* data = new PaletteData();
		data->readObject(dataTable.getRow(i));

		paletteColumns.put(data->getName(), data);

		debug() << "adding " << data->getName();
	}

	info() << "loaded " << paletteColumns.size() << " palette columns";
}

void CustomizationIdManager::readObject(IffStream* iffStream) {
	iffStream->openForm('CIDM');
	iffStream->openForm('0001');

	Chunk* data = iffStream->openChunk('DATA');

	while (data->hasData()) {
		int id = data->readShort();
		String var;
		data->readString(var);

		customizationIds.put(var, id);
		reverseIds.put(id, var);
	}

	iffStream->closeChunk('DATA');

	iffStream->closeForm('0001');
	iffStream->closeForm('CIDM');

	info() << "loaded " << customizationIds.size() << " customization ids";
}

