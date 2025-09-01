/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions. */

#include "server/zone/objects/creature/commands/ForceRun3Command.h"

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/Zone.h"

// --- ForceRun3 auto-break on combat helper ---
namespace {
	inline void stripForceRun3OnCombat(CreatureObject* co) {
		if (!co) return;
		static const uint32 FORCERUN3 = STRING_HASHCODE("forcerun3");
		if (co->hasBuff(FORCERUN3)) {
			co->removeBuff(FORCERUN3);
			co->sendSystemMessage("@jedi_spam:force_run_off");
		}
	}
}


int ForceRun3Command::doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
    if (creature == nullptr || creature->isDead() || creature->isIncapacitated())
        return INVALIDTARGET;

    // Toggle OFF if already active
    if (creature->hasBuff(buffCRC)) {
        creature->removeBuff(buffCRC);
        // creature->sendSystemMessage("You stop force running.");
        creature->sendSystemMessage("@jedi_spam:force_run_off");
        return SUCCESS;
    }

    // Block activation while in combat (swap for PvP-only helper if desired)
    if (creature->isInCombat()) {
        // creature->sendSystemMessage("You cannot activate Force Run while in PvP combat.");
        creature->sendSystemMessage("@jedi_spam:force_run_blocked_pvp");
        return GENERALERROR;
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

     //Optional: auto-cancel on combat start if your Buff API supports it
     //if (ManagedReference<Buff*> fr = creature->getBuff(buffCRC)) {
       //  fr->setRemoveOnCombatStart(true); // or fr->setCancelOnAttack(true);
     
    return SUCCESS;
}
