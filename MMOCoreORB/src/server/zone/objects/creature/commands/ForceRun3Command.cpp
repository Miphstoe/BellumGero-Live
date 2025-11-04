/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions. */

#include "server/zone/objects/creature/commands/ForceRun3Command.h"

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/Zone.h"

int ForceRun3Command::doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
    if (!creature || creature->isDead() || creature->isIncapacitated())
        return INVALIDTARGET;

    // Toggle OFF if already active
    if (creature->hasBuff(buffCRC)) {
        creature->removeBuff(buffCRC);
        creature->sendSystemMessage("@jedi_spam:remove_forcerun3");
        return SUCCESS;
    }

    // Block activation while in combat
    if (creature->isInCombat()) {
        creature->sendSystemMessage("@jedi_spam:force_run_blocked_pvp");
        return GENERALERROR;
    }

    // Apply the buff
    const int res = doJediSelfBuffCommand(creature);
    if (res != SUCCESS)
        return res;

    // Remove conflicting sprint-style buffs
    const uint32 BURSTRUN = STRING_HASHCODE("burstrun");
    const uint32 RETREAT  = STRING_HASHCODE("retreat");
    if (creature->hasBuff(BURSTRUN)) creature->removeBuff(BURSTRUN);
    if (creature->hasBuff(RETREAT))  creature->removeBuff(RETREAT);

    return SUCCESS;
}
