/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions. */

#include "server/zone/objects/creature/commands/ForceRun2Command.h"

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/Zone.h"

int ForceRun2Command::doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
    if (creature == nullptr || creature->isDead() || creature->isIncapacitated())
        return INVALIDTARGET;

    // Toggle OFF if already active
    if (creature->hasBuff(buffCRC)) {
        creature->removeBuff(buffCRC);
        // creature->sendSystemMessage("You stop force running.");
        creature->sendSystemMessage("@jedi_spam:remove_forcerun2");
        return SUCCESS;
    }

    // Apply the buff
    int res = doJediSelfBuffCommand(creature);
    if (res != SUCCESS)
        return res;

    // Remove conflicting sprint-style buffs
    if (creature->hasBuff(STRING_HASHCODE("burstrun")))
        creature->removeBuff(STRING_HASHCODE("burstrun"));
    if (creature->hasBuff(STRING_HASHCODE("retreat")))
        creature->removeBuff(STRING_HASHCODE("retreat"));

    // Optional: auto-cancel on combat start if your Buff API supports it
    // if (ManagedReference<Buff*> fr = creature->getBuff(buffCRC)) {
    //     fr->setRemoveOnCombatStart(true); // or fr->setCancelOnAttack(true);
    // }

    return SUCCESS;
}
