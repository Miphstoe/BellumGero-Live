/*
 * BioCreatureLabratory.h
 *
 * Dedicated final-conditioning laboratory for Bio-Engineer creature deeds.
 */

#ifndef BIOCREATURELABRATORY_H_
#define BIOCREATURELABRATORY_H_

#include "ResourceLabratory.h"

namespace server {
namespace zone {
namespace managers {
namespace crafting {
namespace labratories {

class BioCreatureLabratory : public ResourceLabratory {
public:
	BioCreatureLabratory();
	virtual ~BioCreatureLabratory();

	void setInitialCraftingValues(TangibleObject* prototype, ManufactureSchematic* manufactureSchematic, int assemblySuccess);
};

}
}
}
}
}

using namespace server::zone::managers::crafting::labratories;

#endif /* BIOCREATURELABRATORY_H_ */
