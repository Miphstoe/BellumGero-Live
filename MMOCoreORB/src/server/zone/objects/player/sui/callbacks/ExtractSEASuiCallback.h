#pragma once

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/tangible/wearables/WearableObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/ZoneServer.h"
#include "templates/SharedObjectTemplate.h"

// Use engine-native containers to avoid TypeInfo issues
#include "system/util/VectorMap.h"

class ExtractSEASuiCallback : public SuiCallback {
public:
	ExtractSEASuiCallback(ZoneServer* serv) : SuiCallback(serv) {}
	virtual void run(CreatureObject* player, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args);

private:
    // must match your server IFF
    static constexpr const char* SEA_TOOL_TEMPLATE = "object/tangible/item/sea_removal_tool.iff";


    // Common SWGEmu layout (adjust if yours differs):
    static constexpr const char* CA_TEMPLATE = "object/tangible/wearables/attachment/clothing/clothing_attachment.iff";
    static constexpr const char* AA_TEMPLATE = "object/tangible/wearables/attachment/armor/armor_attachment.iff";

	SceneObject* findToolInInventory(SceneObject* inventory) const;
	bool templateMatches(SceneObject* so, const char* fullTemplate) const;

	// Collect skill mods (stubbed for compile-safety; will wire exact API next)
	void collectSkillMods(WearableObject* wearable, VectorMap<String, int>& outMods, CreatureObject* viewer) const;

	// Create 1 attachment per mod
	bool createAttachmentsForMods(const VectorMap<String, int>& mods,
	                              SceneObject* inventory,
	                              bool armor,
	                              Vector< ManagedReference<TangibleObject*> >& created) const;

	inline int neededSlots(const VectorMap<String,int>& mods) const { return mods.size(); }
};
