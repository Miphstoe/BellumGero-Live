/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions. */

#ifndef FORCERUN2COMMAND_H_
#define FORCERUN2COMMAND_H_

#include "server/zone/objects/creature/buffs/PrivateSkillMultiplierBuff.h"
#include "JediQueueCommand.h"

class ForceRun2Command : public JediQueueCommand {
public:
    ForceRun2Command(const String& name, ZoneProcessServer* server) : JediQueueCommand(name, server) {
        // Primary Force Run 2 buff
        buffCRC = BuffCRC::JEDI_FORCE_RUN_2;

        // Force Run 1/3 block 2 (and vice versa)
        blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_1);
        blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_3);

        // Usual skill mods
        skillMods.put("force_run", 2);
        skillMods.put("slope_move", 66);
    }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        if (creature == nullptr)
            return GENERALERROR;

        // Toggle OFF if already active
        if (creature->hasBuff(buffCRC)) {
            creature->removeBuff(buffCRC); // also removes secondaries we attach below
            creature->sendSystemMessage("@jedi_spam:force_run_off"); // optional STF
            return SUCCESS;
        }

        // --- Toggle ON path ---

        // duration <= 0 -> toggle mode (no timer): apply a huge duration so it won't expire.
        static const int TOGGLE_DURATION_SECONDS = 60 * 60 * 24 * 365 * 10; // ~10 years
        const bool toggleMode = (duration <= 0);

        // Temporarily override duration for this invocation only
        const int oldDuration = duration;
        if (toggleMode) {
            const_cast<ForceRun2Command*>(this)->duration = TOGGLE_DURATION_SECONDS;
        }

        // Apply the main JEDI_FORCE_RUN_2 buff, consume Force, run standard checks, etc.
        int res = doJediSelfBuffCommand(creature);

        // Restore original duration
        if (toggleMode) {
            const_cast<ForceRun2Command*>(this)->duration = oldDuration;
        }

        if (res != SUCCESS) {
            if (res == NOSTACKJEDIBUFF)
                creature->sendSystemMessage("@jedi_spam:already_force_running");
            return res;
        }

        // Fetch the primary buff we just added
        Buff* primary = creature->getBuff(BuffCRC::JEDI_FORCE_RUN_2);
        if (primary == nullptr)
            return GENERALERROR;

        // Apply the damage-divisor as a separate, private multiplier buff so the math behaves correctly.
        int appliedDuration = toggleMode ? TOGGLE_DURATION_SECONDS : oldDuration;

        ManagedReference<PrivateSkillMultiplierBuff*> multBuff =
            new PrivateSkillMultiplierBuff(creature, name.hashCode(), appliedDuration, BuffType::JEDI);

        {
            Locker locker(multBuff);
            multBuff->setSkillModifier("private_damage_divisor", 20);
            creature->addBuff(multBuff);
        }

        {
            Locker blocker(primary);
            // Ensure the secondary disappears with the primary (on toggle-off, death, etc.)
            primary->addSecondaryBuffCRC(multBuff->getBuffCRC());
        }

        // Prevent stacking with other run effects
        if (creature->hasBuff(STRING_HASHCODE("burstrun")) || creature->hasBuff(STRING_HASHCODE("retreat"))) {
            creature->removeBuff(STRING_HASHCODE("burstrun"));
            creature->removeBuff(STRING_HASHCODE("retreat"));
        }

        creature->sendSystemMessage("@jedi_spam:force_run_on"); // optional STF
        return SUCCESS;
    }
};

#endif // FORCERUN2COMMAND_H_
