
/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions. */

#ifndef FORCERUN3COMMAND_H_
#define FORCERUN3COMMAND_H_

#include "server/zone/objects/creature/buffs/PrivateSkillMultiplierBuff.h"
#include "JediQueueCommand.h"

class ForceRun3Command : public JediQueueCommand {
public:
    ForceRun3Command(const String& name, ZoneProcessServer* server) : JediQueueCommand(name, server) {
        // Primary Force Run 3 buff
        buffCRC = BuffCRC::JEDI_FORCE_RUN_3;

        // Force Run 1/2 block 3 (and vice versa)
        blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_1);
        blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_2);

        // Usual skill mods
        skillMods.put("force_run", 3);
        skillMods.put("slope_move", 99);
    }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        if (creature == nullptr)
            return GENERALERROR;

        // Toggle OFF if already active
        if (creature->hasBuff(buffCRC)) {
            creature->removeBuff(buffCRC); // will also remove secondary buffs we attach below
            creature->sendSystemMessage("@jedi_spam:force_run_off"); // (add this STF if you want a nicer message)
            return SUCCESS;
        }

        // --- Toggle ON path ---

        // Treat duration <= 0 as "toggle mode" -> apply a huge duration so it won't expire on its own.
        static const int TOGGLE_DURATION_SECONDS = 60 * 60 * 24 * 365 * 10; // ~10 years
        const bool toggleMode = (duration <= 0);

        // Temporarily override duration passed to the base helper
        const int oldDuration = duration;
        if (toggleMode) {
            // Cast away constness to adjust the protected member for this invocation only.
            // (duration is inherited from Command/JediQueueCommand and is not const in Core3.)
            const_cast<ForceRun3Command*>(this)->duration = TOGGLE_DURATION_SECONDS;
        }

        // This applies the main JEDI_FORCE_RUN_3 buff, consumes Force, runs standard checks, etc.
        int res = doJediSelfBuffCommand(creature);

        // Restore original duration
        if (toggleMode) {
            const_cast<ForceRun3Command*>(this)->duration = oldDuration;
        }

        if (res != SUCCESS) {
            if (res == NOSTACKJEDIBUFF)
                creature->sendSystemMessage("@jedi_spam:already_force_running"); // You are already force running.
            return res;
        }

        // Fetch the primary buff we just added
        Buff* primary = creature->getBuff(BuffCRC::JEDI_FORCE_RUN_3);
        if (primary == nullptr)
            return GENERALERROR;

        // Apply the damage-divisor as a separate, private multiplier buff so the math behaves correctly.
        // Match duration to whatever we actually applied to the primary buff.
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

        creature->sendSystemMessage("@jedi_spam:force_run_on"); // (optional STF)
        return SUCCESS;
    }
};

#endif // FORCERUN3COMMAND_H_

