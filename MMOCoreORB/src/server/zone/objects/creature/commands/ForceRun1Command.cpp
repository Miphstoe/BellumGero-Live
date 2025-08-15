/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions. */

#include "server/zone/objects/creature/commands/ForceRun1Command.h"

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/Zone.h"

int ForceRun1Command::doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
    if (creature == nullptr || creature->isDead() || creature->isIncapacitated())
        return INVALIDTARGET;

    // --- Toggle OFF if already active ----------------------------------------
    if (creature->hasBuff(buffCRC)) {
        creature->removeBuff(buffCRC);

        // Prefer string-id if available; otherwise replace with a literal.
        // creature->sendSystemMessage("You stop force running.");
        creature->sendSystemMessage("@jedi_spam:force_run_off");
        return SUCCESS;
    }

    // --- Apply the buff (no combat/PvP checks) --------------------------------
    int res = doJediSelfBuffCommand(creature);
    if (res != SUCCESS)
        return res;

    // SPECIAL - For Force Run: remove conflicting sprint-style buffs.
    if (creature->hasBuff(STRING_HASHCODE("burstrun")))
        creature->removeBuff(STRING_HASHCODE("burstrun"));
    if (creature->hasBuff(STRING_HASHCODE("retreat")))
        creature->removeBuff(STRING_HASHCODE("retreat"));

    // Optional: auto-cancel when combat begins (keep disabled for "anytime" use).
    // if (ManagedReference<Buff*> fr = creature->getBuff(buffCRC)) {
    //     fr->setRemoveOnCombatStart(true);   // or fr->setCancelOnAttack(true);
    // }

    return SUCCESS;
}
