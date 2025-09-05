#include "server/zone/objects/player/sui/callbacks/ExtractSEASuiCallback.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/managers/object/ObjectManager.h"
#include "templates/SharedObjectTemplate.h"

#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/tangible/wearables/WearableObject.h"
#include "server/zone/objects/tangible/wearables/WearableContainerObject.h"
#include "server/zone/objects/tangible/attachment/Attachment.h"
#include "server/zone/objects/scene/SceneObject.h"

#ifndef CA_TEMPLATE
#define CA_TEMPLATE "object/tangible/gem/clothing.iff"
#endif
#ifndef AA_TEMPLATE
#define AA_TEMPLATE "object/tangible/gem/armor.iff"
#endif

namespace {
    static const char* TOOL_SERVER_IFF = "object/tangible/item/sea_removal_tool.iff";
    static const char* TOOL_SHARED_IFF = "object/tangible/item/shared_sea_removal_tool.iff";

    inline bool isSEATool(SceneObject* so) {
        if (!so) return false;
        SharedObjectTemplate* tmpl = so->getObjectTemplate();
        if (!tmpl) return false;
        const String full = tmpl->getFullTemplateString();
        return full == TOOL_SERVER_IFF || full == TOOL_SHARED_IFF
            || full.indexOf("sea_removal_tool.iff") != -1;
    }

    SceneObject* findToolRecursive(SceneObject* container) {
        if (!container) return nullptr;
        const int n = container->getContainerObjectsSize();
        for (int i = 0; i < n; ++i) {
            SceneObject* child = container->getContainerObject(i);
            if (!child) continue;
            if (isSEATool(child)) return child;
            if (child->isContainerObject()) {
                if (SceneObject* hit = findToolRecursive(child)) return hit;
            }
        }
        return nullptr;
    }

    inline bool looksLikeAttachmentTemplate(const String& full) {
        return full.indexOf("/attachment/") != -1 || full.endsWith("_attachment.iff");
    }

    // Recurse into nested containers (belts, bandoliers, etc.)
    void collectAttachmentDescendants(SceneObject* root,
                                      Vector< ManagedReference<TangibleObject*> >& out,
                                      CreatureObject* dbg) {
        if (!root) return;

        const int n = root->getContainerObjectsSize();
        for (int i = 0; i < n; ++i) {
            SceneObject* child = root->getContainerObject(i);
            if (!child) continue;

            SharedObjectTemplate* tmpl = child->getObjectTemplate();
            if (tmpl) {
                const String full = tmpl->getFullTemplateString();
                if (dbg) dbg->sendSystemMessage(String("SEA: found child ") + full);
                if (looksLikeAttachmentTemplate(full)) {
                    if (auto* t = child->asTangibleObject()) out.add(t);
                }
            }

            if (child->isContainerObject())
                collectAttachmentDescendants(child, out, dbg);
        }
    }

   // Nudge the client to render newly created items
static void nudgeInventoryWithItems(CreatureObject* player,
                                    const Vector< ManagedReference<TangibleObject*> >& items) {
    if (!player) return;
    SceneObject* viewer = player; // upcast

    for (int i = 0; i < items.size(); ++i) {
        ManagedReference<TangibleObject*> obj = items.get(i);
        if (obj != nullptr) {
            // doClose = false, forceLoadContainer = true
            obj->sendTo(viewer, false, true);
        }
    }
}
}
 // namespace

void ExtractSEASuiCallback::run(CreatureObject* player, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* /*args*/) {
    if (player == nullptr || player->isDead() || player->isIncapacitated())
        return;

    if (!(eventIndex == 0 || eventIndex == 1))
        return;

    ManagedReference<SceneObject*> usingObj = (sui ? sui->getUsingObject() : nullptr);
    if (!usingObj) { player->sendSystemMessage("SEA: Invalid target."); return; }

    WearableObject* wearable = cast<WearableObject*>(usingObj.get());
    if (wearable == nullptr) { player->sendSystemMessage("SEA: Target is not wearable."); return; }

    ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");
    if (inventory == nullptr) { player->sendSystemMessage("SEA: Inventory not found."); return; }

    if (!wearable->isASubChildOf(inventory)) {
        player->sendSystemMessage("SEA: Wearable must be in your inventory.");
        return;
    }

    SceneObject* toolSO = findToolRecursive(inventory);
    if (!toolSO) { player->sendSystemMessage("SEA: SEA Removal Tool not found in your inventory."); return; }

    Locker lockPlayer(player, player);
    Locker lockInv(inventory, player);
    Locker lockWearable(wearable, player);
    Locker lockTool(toolSO, player);

    // 1) Detach attachment children if present
    Vector< ManagedReference<TangibleObject*> > attachments;
    collectAttachmentDescendants(wearable, attachments, player);

    if (!attachments.isEmpty()) {
        const int need = attachments.size();
        const int cap  = inventory->getContainerVolumeLimit();
        const int used = inventory->getContainerObjectsSize();
        if (used + need > cap) {
            player->sendSystemMessage("SEA: Not enough inventory space to extract attachments.");
            return;
        }

        for (int i = 0; i < attachments.size(); ++i) {
            auto att = attachments.get(i);
            if (!att) continue;
            Locker lat(att, player);
            if (!inventory->transferObject(att, -1, true)) {
                player->sendSystemMessage("SEA: Failed to move an attachment to your inventory. Aborting.");
                return;
            }
        }

        usingObj->destroyObjectFromWorld(true);
        usingObj->destroyObjectFromDatabase(true);
        toolSO->destroyObjectFromWorld(true);
        toolSO->destroyObjectFromDatabase(true);

        nudgeInventoryWithItems(player, attachments);
        player->sendSystemMessage("SEA: Extraction complete. Attachments moved to your inventory; the wearable and tool were consumed.");
        return;
    }

    // 2) Clone mods into new GEMs
    VectorMap<String, int> mods;
    collectSkillMods(wearable, mods, player);

    if (mods.isEmpty()) {
        player->sendSystemMessage("SEA: No skill modifiers found on this item.");
        return;
    }

    {
        const int need = mods.size();
        const int cap  = inventory->getContainerVolumeLimit();
        const int used = inventory->getContainerObjectsSize();
        if (used + need > cap) {
            player->sendSystemMessage("SEA: Not enough inventory space for extracted attachments.");
            return;
        }
    }

    const bool isArmor = usingObj->isArmorObject();
    const char* path   = isArmor ? AA_TEMPLATE : CA_TEMPLATE;
    const uint32 tmplCRC = String(path).hashCode();

    Vector< ManagedReference<TangibleObject*> > created;

    for (int i = 0; i < mods.size(); ++i) {
        const String& modName = mods.elementAt(i).getKey();
        const int     value   = mods.elementAt(i).getValue();

        Reference<SceneObject*> so = server->createObject(tmplCRC, 1);
        if (so == nullptr) {
            player->sendSystemMessage(String("SEA: Failed to create: ") + path);
            for (int j = 0; j < created.size(); ++j) {
                auto t = created.get(j);
                if (t) { t->destroyObjectFromWorld(true); t->destroyObjectFromDatabase(true); }
            }
            return;
        }

        ManagedReference<TangibleObject*> tobj = so.castTo<TangibleObject*>();
        if (tobj == nullptr) {
            player->sendSystemMessage(String("SEA: Template is not tangible: ") + path);
            so = nullptr;
            for (int j = 0; j < created.size(); ++j) {
                auto t = created.get(j);
                if (t) { t->destroyObjectFromWorld(true); t->destroyObjectFromDatabase(true); }
            }
            return;
        }

        {
            Locker lt(tobj);

            if (Attachment* gem = cast<Attachment*>(tobj.get())) {
                gem->addSkillMod(modName, value);
            }

            String n = isArmor ? "Armor Attachment: " : "Clothing Attachment: ";
            n += modName + " (+" + String::valueOf(value) + ")";
            tobj->setCustomObjectName(n, true);
        }

        if (!inventory->transferObject(tobj, -1, true)) {
            tobj->destroyObjectFromWorld(true);
            tobj->destroyObjectFromDatabase(true);
            for (int j = 0; j < created.size(); ++j) {
                auto t = created.get(j);
                if (t) { t->destroyObjectFromWorld(true); t->destroyObjectFromDatabase(true); }
            }
            player->sendSystemMessage("SEA: Failed to move created attachment to inventory.");
            return;
        }

        created.add(tobj);
    }

    usingObj->destroyObjectFromWorld(true);
    usingObj->destroyObjectFromDatabase(true);
    toolSO->destroyObjectFromWorld(true);
    toolSO->destroyObjectFromDatabase(true);

    nudgeInventoryWithItems(player, created);
    player->sendSystemMessage(String("SEA: created ") + String::valueOf(created.size()) + " attachment(s).");
    player->sendSystemMessage("SEA: Extraction complete. The wearable and tool were consumed.");
}

void ExtractSEASuiCallback::collectSkillMods(WearableObject* wearable,
                                             VectorMap<String, int>& outMods,
                                             CreatureObject* viewer) const {
    outMods.removeAll();
    if (!wearable) return;

    int found = 0;

    if (VectorMap<String,int>* m = wearable->getWearableSkillMods()) {
        for (int i = 0; i < m->size(); ++i) {
            String key = m->elementAt(i).getKey();
            int    val = m->get(key);
            if (!key.isEmpty() && val != 0) { outMods.put(key, val); ++found; }
        }
    }

    if (found == 0) {
        if (auto* wc = cast<WearableContainerObject*>(wearable)) {
            if (const VectorMap<String,int>* cm = wc->getWearableSkillMods()) {
                VectorMap<String,int>* m = const_cast<VectorMap<String,int>*>(cm);
                for (int i = 0; i < m->size(); ++i) {
                    String key = m->elementAt(i).getKey();
                    int    val = m->get(key);
                    if (!key.isEmpty() && val != 0) { outMods.put(key, val); ++found; }
                }
            }
        }
    }

    if (viewer) {
        viewer->sendSystemMessage(String("SEA: found ") + String::valueOf(found) + " mod(s) on wearable.");
    }
}

SceneObject* ExtractSEASuiCallback::findToolInInventory(SceneObject*) const { return nullptr; }
bool ExtractSEASuiCallback::templateMatches(SceneObject* so, const char* path) const {
    if (!so || !path) return false;
    SharedObjectTemplate* t = so->getObjectTemplate();
    return t && t->getFullTemplateString() == path;
}
