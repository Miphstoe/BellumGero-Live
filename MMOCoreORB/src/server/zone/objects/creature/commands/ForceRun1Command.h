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
        // BuffCRC's, first one is used.
        buffCRC = BuffCRC::JEDI_FORCE_RUN_1;

        // If these are active they will block buff use
        blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_2);
        blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_3);

        // Skill mods.
        skillMods.put("force_run", 1);
        skillMods.put("slope_move", 33);
    }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const override;
};

#endif // FORCERUN1COMMAND_H_
