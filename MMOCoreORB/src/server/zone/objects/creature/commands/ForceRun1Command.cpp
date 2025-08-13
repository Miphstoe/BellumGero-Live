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

        // Prefer string-id if you have it, otherwise swap to a literal:
        // creature->sendSystemMessage("You stop force running.");
        creature->sendSystemMessage("@jedi_spam:force_run_off");
        return SUCCESS;
    }

    // --- Block activation while in combat (safe default) ----------------------
    // If you only want to block PvP, replace this with your PvP check helper, e.g.:
    // if (isInPvpCombat(creature)) { ... }
    if (creature->isInCombat()) {
        // Prefer string-id; otherwise use a literal line.
        // creature->sendSystemMessage("You cannot activate Force Run while in PvP combat.");
        creature->sendSystemMessage("@jedi_spam:force_run_blocked_pvp");
        return GENERALERROR;
    }

    // --- Apply the buff -------------------------------------------------------
    int res = doJediSelfBuffCommand(creature);
    if (res != SUCCESS)
        return res;

    // SPECIAL - For Force Run: remove conflicting sprint-style buffs.
    // (Keep behavior consistent with original implementation.)
    if (creature->hasBuff(STRING_HASHCODE("burstrun")))
        creature->removeBuff(STRING_HASHCODE("burstrun"));
    if (creature->hasBuff(STRING_HASHCODE("retreat")))
        creature->removeBuff(STRING_HASHCODE("retreat"));

    // --- Optional: auto-cancel when combat begins -----------------------------
    // If your Buff class supports a cancel-on-combat flag, set it here.
    // Leaving this commented ensures this file compiles on all forks.
    //
    // if (ManagedReference<Buff*> fr = creature->getBuff(buffCRC)) {
    //     fr->setRemoveOnCombatStart(true);   // or fr->setCancelOnAttack(true);
    // }

    return SUCCESS;
}
