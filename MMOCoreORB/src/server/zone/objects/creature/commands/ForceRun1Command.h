/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions. */

#ifndef FORCERUN1COMMAND_H_
#define FORCERUN1COMMAND_H_

#include "JediQueueCommand.h"

class ForceRun1Command : public JediQueueCommand {
public:
    ForceRun1Command(const String& name, ZoneProcessServer* server)
        : JediQueueCommand(name, server) {
        // Primary FR1 buff
        buffCRC = BuffCRC::JEDI_FORCE_RUN_1;

        // FR2/FR3 block FR1 (and vice versa)
        blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_2);
        blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_3);

        // Skill mods.
        skillMods.put("force_run", 1);
        skillMods.put("slope_move", 33);
    }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        if (creature == nullptr)
            return GENERALERROR;

        // Toggle OFF if already active
        if (creature->hasBuff(buffCRC)) {
            creature->removeBuff(buffCRC);
            creature->sendSystemMessage("@jedi_spam:force_run_off"); // optional STF
            return SUCCESS;
        }

        // --- Toggle ON path ---
        // duration <= 0 => toggle mode (no timer): apply a huge duration so it won't expire.
        static const int TOGGLE_DURATION_SECONDS = 60 * 60 * 24 * 365 * 10; // ~10 years
        const bool toggleMode = (duration <= 0);

        // Temporarily override duration for this invocation only
        const int oldDuration = duration;
        if (toggleMode) {
            const_cast<ForceRun1Command*>(this)->duration = TOGGLE_DURATION_SECONDS;
        }

        // Standard self-buff flow (consumes Force, runs checks, applies JEDI_FORCE_RUN_1)
        int res = doJediSelfBuffCommand(creature);

        // Restore original duration
        if (toggleMode) {
            const_cast<ForceRun1Command*>(this)->duration = oldDuration;
        }

        if (res != SUCCESS) {
            if (res == NOSTACKJEDIBUFF)
                creature->sendSystemMessage("@jedi_spam:already_force_running");
            return res;
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

#endif // FORCERUN1COMMAND_H_
