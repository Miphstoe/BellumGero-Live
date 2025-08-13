/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions. */

#ifndef FORCERUN2COMMAND_H_
#define FORCERUN2COMMAND_H_

#include "JediQueueCommand.h"

class ForceRun2Command : public JediQueueCommand {
public:
    ForceRun2Command(const String& name, ZoneProcessServer* server)
        : JediQueueCommand(name, server) {
        // BuffCRC's, first one is used.
        buffCRC = BuffCRC::JEDI_FORCE_RUN_2;

        // If these are active they will block buff use
        blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_1);
        blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_3);

        // Skill mods.
        skillMods.put("force_run", 2);
        skillMods.put("slope_move", 66);
    }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const override;
};

#endif // FORCERUN2COMMAND_H_
